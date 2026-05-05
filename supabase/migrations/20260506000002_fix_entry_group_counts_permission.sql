-- ============================================================
-- Fix #2254: get_entry_group_participant_counts — PARTY_MANAGE 권한 체크 제거
--
-- 문제: 20260505000004 마이그레이션이 파트너 대시보드용 target_capacity 컬럼을
-- 추가하면서 PARTY_MANAGE 권한 체크도 함께 추가했다.
-- 이로 인해 일반 유저가 EventDetailPage의 참가현황 탭 진입 시
-- PostgrestException: permission denied: PARTY_MANAGE required 오류 발생.
--
-- 수정: PARTY_MANAGE 체크 제거. participant_count는 공개 정보로 이미
-- entry_groups / event_participants 테이블에 public read 정책이 존재한다.
-- SECURITY DEFINER + soft-delete 필터는 유지 (deleted_at null 체크 필요).
-- ============================================================

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
begin
  -- Fix #2254: PARTY_MANAGE 권한 체크 제거 — 참가자 수는 공개 정보
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
