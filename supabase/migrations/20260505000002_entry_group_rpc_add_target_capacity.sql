-- ============================================================
-- #2117: get_entry_group_participant_counts에 target_capacity 추가
-- EventApplicationListPage dashboard에서 "입장그룹별 현재 인원/정원" 표시에 사용.
-- 기존 반환 컬럼(entry_group_id, label, participant_count)은 유지되므로
-- 기존 호출자에 영향 없음.
-- ============================================================

-- DROP required: PostgreSQL disallows CREATE OR REPLACE when the return type changes
-- (SQLSTATE 42P13). Callers only need the result type at runtime, not at parse time.
drop function if exists public.get_entry_group_participant_counts(uuid);

create or replace function public.get_entry_group_participant_counts(
  p_event_id uuid
)
returns table (
  entry_group_id uuid,
  label text,
  participant_count bigint,
  target_capacity bigint
)
language sql
security invoker
stable
as $$
  select
    eg.id as entry_group_id,
    eg.label,
    count(distinct ep.id) as participant_count,
    coalesce((
      select sum(t2.quantity)
      from public.tickets t2
      where eg.id = any(t2.target_entry_group_ids)
        and t2.event_id = p_event_id
    ), 0)::bigint as target_capacity
  from public.entry_groups eg
  left join public.tickets t
    on eg.id = any(t.target_entry_group_ids)
    and t.event_id = p_event_id
  left join public.event_participants ep
    on ep.ticket_id = t.id
    and ep.event_id = p_event_id
  where eg.event_id = p_event_id
  group by eg.id, eg.label
  order by eg.created_at;
$$;

-- 기존 권한 유지
revoke all on function public.get_entry_group_participant_counts(uuid) from public;
grant execute on function public.get_entry_group_participant_counts(uuid) to anon, authenticated, service_role;
