-- 16. USERS: Profile Image URL
set search_path to public, extensions;

alter table public.user_profiles
add column if not exists profile_image_url text;
