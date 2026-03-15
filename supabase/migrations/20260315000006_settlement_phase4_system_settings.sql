-- Settlement Phase 4: System Settings & Kill Switch
-- Adds system_settings table for operational controls (kill switches, thresholds).
-- Prerequisites: Phase 1-3 must be applied.

-- ============================================================
-- 1. system_settings — Key-value store for operational controls
--    REQ-4.6.10: Kill switch to block new READY→PROCESSING transitions
--    and force existing PROCESSING items to FAILED
-- ============================================================

create table if not exists public.system_settings (
  key text primary key,
  value jsonb not null default '{}',
  description text,
  updated_at timestamptz not null default now(),
  updated_by text
);

create index if not exists idx_system_settings_updated_at
  on public.system_settings(updated_at);

-- ============================================================
-- 2. Seed initial system settings
-- ============================================================

insert into public.system_settings (key, value, description) values
  ('settlement_kill_switch', '{"enabled": false}'::jsonb, '지급 긴급 중단 스위치'),
  ('reconciliation_kill_switch_threshold', '{"value": 3}'::jsonb, '대사 critical 불일치 자동 kill switch 활성화 임계치')
on conflict (key) do nothing;

-- ============================================================
-- 3. force_fail_processing_on_kill_switch() — Force all PROCESSING items to FAILED
--    Called when kill switch is activated (enabled=true).
--    Transitions all PROCESSING settlement_items to FAILED with reason 'KILL_SWITCH_ACTIVATED'.
-- ============================================================

create or replace function public.force_fail_processing_on_kill_switch()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_item record;
begin
  -- Select all PROCESSING items with row-level lock (SKIP LOCKED for non-blocking)
  for v_item in
    select id, version
    from public.settlement_items
    where status = 'PROCESSING'
    for update skip locked
  loop
    -- Transition each PROCESSING item to FAILED
    -- REQ-4.6.10: Kill switch forces PROCESSING → FAILED
    perform public.transition_settlement_status(
      p_item_id              := v_item.id,
      p_expected_version     := v_item.version,
      p_new_status           := 'FAILED',
      p_actor_type           := 'SYSTEM',
      p_actor_id             := 'SYSTEM',
      p_event_type           := 'kill_switch_forced_fail',
      p_failure_reason_code  := 'KILL_SWITCH_ACTIVATED',
      p_failure_message      := 'Kill switch forced fail'
    );
  end loop;
end;
$$;

-- ============================================================
-- 4. toggle_settlement_kill_switch() — Toggle kill switch and force failures if enabled
--    REQ-4.6.10: Activated kill switch blocks READY→PROCESSING and forces PROCESSING→FAILED
--    p_enabled: true to activate, false to deactivate
--    p_actor: admin user ID or system identifier
-- ============================================================

create or replace function public.toggle_settlement_kill_switch(
  p_enabled boolean,
  p_actor text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Update kill switch setting
  update public.system_settings
  set
    value = jsonb_set(value, '{enabled}', to_jsonb(p_enabled)),
    updated_at = now(),
    updated_by = p_actor
  where key = 'settlement_kill_switch';

  -- If enabling kill switch, force all PROCESSING items to FAILED
  if p_enabled then
    perform public.force_fail_processing_on_kill_switch();
  end if;
end;
$$;
