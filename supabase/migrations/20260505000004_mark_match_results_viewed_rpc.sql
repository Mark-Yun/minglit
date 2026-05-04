-- ============================================================
-- #2124 follow-up: mark_match_results_viewed RPC
-- 클라이언트 직접 UPDATE 대신 이 함수를 통해 match_results_viewed_at 기록.
-- 소유권 검증 로직을 함수 안에 캡슐화 → RLS 정책 의존 제거.
-- ============================================================

create or replace function public.mark_match_results_viewed(
  p_application_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_owner uuid;
begin
  -- 소유권 확인: 본인의 신청서인지 검증
  select user_id into v_owner
  from public.event_applications
  where id = p_application_id;

  if v_owner is null then
    raise exception 'application not found' using errcode = 'P0002';
  end if;

  if v_owner <> auth.uid() then
    raise exception 'permission denied' using errcode = '42501';
  end if;

  -- idempotent: match_results_viewed_at이 NULL인 경우에만 설정
  update public.event_applications
  set match_results_viewed_at = now()
  where id = p_application_id
    and match_results_viewed_at is null;

  return found;
end;
$$;

-- anon은 불필요. authenticated만 허용.
revoke all on function public.mark_match_results_viewed(uuid) from public;
grant execute on function public.mark_match_results_viewed(uuid) to authenticated;
