-- 16. USERS: Profile Image URL

alter table public.user_profiles
add column if not exists profile_image_url text;
