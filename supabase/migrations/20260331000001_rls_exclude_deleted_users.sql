-- Fix #891: soft-deleted user visibility를 participant/match read 경로에서 제외
set search_path to public, extensions;

-- Fix #891: soft-deleted user profile의 공개 가시성 판별 헬퍼 추가
create or replace function public.is_visible_user_profile(p_user_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.user_profiles up
    where up.id = p_user_id
      and up.deleted_at is null
  );
$$;

revoke all on function public.is_visible_user_profile(uuid) from public;
grant execute on function public.is_visible_user_profile(uuid) to authenticated, service_role;

drop policy if exists "Authenticated users can read all participants" on public.event_participants;
-- Fix #891: soft-deleted participant는 본인만 조회 가능하고 타 유저에게는 숨김
create policy "Authenticated users can read visible participants" on public.event_participants
  for select
  using (
    auth.role() = 'authenticated'
    and (
      auth.uid() = user_id
      or public.is_visible_user_profile(user_id)
    )
  );

-- Fix #891: 매칭 뷰에서 soft-deleted 상대 유저를 제외
create or replace view public.my_matches_view as
select
  mp.id as match_id,
  mp.event_id,
  mp.matched_at,
  matched_user.id as partner_id
from public.match_pairs mp
join public.user_profiles matched_user
  on matched_user.id = case
    when mp.user_lower_id = auth.uid() then mp.user_higher_id
    else mp.user_lower_id
  end
where (mp.user_lower_id = auth.uid() or mp.user_higher_id = auth.uid())
  and matched_user.deleted_at is null;

-- Fix #891: 연락처 RPC가 soft-deleted 매칭 유저 정보를 반환하지 않도록 제한
create or replace function public.get_matched_user_contact(target_user_id uuid, target_event_id uuid)
returns text
as $$
declare
  contact_info text;
begin
  if exists (
    select 1 from public.match_pairs
    where event_id = target_event_id
      and (
        (user_lower_id = auth.uid() and user_higher_id = target_user_id) or
        (user_lower_id = target_user_id and user_higher_id = auth.uid())
      )
  ) then
    select phone_number into contact_info
    from public.user_profiles
    where id = target_user_id
      and deleted_at is null;

    return contact_info;
  else
    return null;
  end if;
end;
$$ language plpgsql security definer;

revoke all on function public.get_matched_user_contact(uuid, uuid) from public;
grant execute on function public.get_matched_user_contact(uuid, uuid) to authenticated, service_role;

-- Fix #891: 프로필 RPC가 soft-deleted 매칭 유저 정보를 반환하지 않도록 제한
create or replace function public.get_matched_user_info(
  p_target_user_id uuid,
  p_target_event_id uuid
)
returns table(user_name text, profile_image_url text, phone_number text)
language plpgsql
security definer
set search_path = public
as $$
begin
  if exists (
    select 1 from public.match_pairs
    where event_id = p_target_event_id
      and (
        (user_lower_id = auth.uid() and user_higher_id = p_target_user_id) or
        (user_lower_id = p_target_user_id and user_higher_id = auth.uid())
      )
  ) then
    return query
      select up.name, up.profile_image_url, up.phone_number
      from public.user_profiles up
      where up.id = p_target_user_id
        and up.deleted_at is null;
  end if;
end;
$$;

revoke all on function public.get_matched_user_info(uuid, uuid) from public;
grant execute on function public.get_matched_user_info(uuid, uuid) to authenticated, service_role;
