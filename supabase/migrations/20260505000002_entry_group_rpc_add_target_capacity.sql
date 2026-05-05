-- ============================================================
-- #2117: get_entry_group_participant_counts에 target_capacity 추가
-- EventApplicationListPage dashboard에서 "입장그룹별 현재 인원/정원" 표시에 사용.
-- 기존 반환 컬럼(entry_group_id, label, participant_count)은 유지되므로
-- 기존 호출자에 영향 없음.
-- 파트너 대시보드 전용: PARTY_MANAGE 권한 체크 + soft-delete 명시 필터.
-- ============================================================

-- DROP required: PostgreSQL disallows CREATE OR REPLACE when the return type changes
-- (SQLSTATE 42P13). Callers only need the result type at runtime, not at parse time.
drop function if exists public.get_entry_group_participant_counts(uuid);

create function public.get_entry_group_participant_counts(
  p_event_id uuid
)
returns table (
  entry_group_id uuid,
  label text,
  participant_count bigint,
  target_capacity bigint
)
language plpgsql
security definer
set search_path = public
stable
as $$
declare
  v_partner_id uuid;
begin
  -- 1. 이벤트 → 파트너 조회
  select pa.partner_id
    into v_partner_id
    from public.events e
    join public.parties pa on pa.id = e.party_id
   where e.id = p_event_id;

  if v_partner_id is null then
    raise exception 'event not found';
  end if;

  -- 2. 호출자가 해당 파트너의 PARTY_MANAGE 권한 보유 여부 확인
  if not public.has_partner_permission(v_partner_id, 'PARTY_MANAGE') then
    raise exception 'permission denied: PARTY_MANAGE required';
  end if;

  -- 3. 엔트리 그룹별 참가자 수 + 정원 집계
  --    security definer이므로 RLS 우회 → soft-delete를 user_profiles join으로 명시 필터
  return query
  select
    eg.id as entry_group_id,
    eg.label,
    count(distinct ep.id) filter (where up.id is not null) as participant_count,
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
  left join public.user_profiles up
    on up.id = ep.user_id
    and up.deleted_at is null
  where eg.event_id = p_event_id
  group by eg.id, eg.label, eg.created_at
  order by eg.created_at;
end;
$$;

revoke all on function public.get_entry_group_participant_counts(uuid) from public;
grant execute on function public.get_entry_group_participant_counts(uuid) to authenticated;
