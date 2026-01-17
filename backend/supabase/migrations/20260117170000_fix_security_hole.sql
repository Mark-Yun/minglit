-- Fix Security Hole: Prevent users from updating protected fields in user_profiles

create or replace function public.protect_user_profile_fields()
returns trigger 
set search_path = public
as $$
begin
  -- Check if is_verified is being changed
  if (new.is_verified is distinct from old.is_verified) then
    -- Allow only service_role or super_admin
    -- Note: auth.role() returns 'authenticated' for normal users.
    -- 'service_role' for admin client.
    if (auth.role() = 'authenticated' and not public.is_super_admin()) then
      raise exception 'You cannot update verification status directly. (Access Denied)';
    end if;
  end if;
  return new;
end;
$$ language plpgsql security definer;

create trigger protect_user_profile_fields
  before update on public.user_profiles
  for each row execute procedure public.protect_user_profile_fields();
