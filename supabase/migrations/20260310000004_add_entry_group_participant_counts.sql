-- ============================================================
-- RPC: get_entry_group_participant_counts
-- 이벤트의 각 입장 그룹별 참여자 수를 반환
-- ============================================================
create or replace function public.get_entry_group_participant_counts(
  p_event_id uuid
)
returns table (
  entry_group_id uuid,
  label text,
  participant_count bigint
)
language sql
security invoker
stable
as $$
  select
    eg.id as entry_group_id,
    eg.label,
    count(distinct ep.id) as participant_count
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
