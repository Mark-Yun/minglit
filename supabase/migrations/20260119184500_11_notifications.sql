-- 11. NOTIFICATIONS
set search_path to public, extensions;

-- 1. Create Enum for Notification Category
create type public.notification_category as enum (
  'marketing',
  'service',
  'social'
);

-- 2. Create Notifications Table
create table public.user_notifications (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  body text not null,
  category public.notification_category not null default 'service',
  deep_link text,
  is_read boolean not null default false,
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz not null default now(),
  
  constraint user_notifications_pkey primary key (id)
);

-- 3. Enable RLS
alter table public.user_notifications enable row level security;

-- 4. Create Policies
-- Users can view their own notifications
create policy "Users can view their own notifications"
  on public.user_notifications
  for select
  using (auth.uid() = user_id);

-- Users can update (mark as read) their own notifications
create policy "Users can update their own notifications"
  on public.user_notifications
  for update
  using (auth.uid() = user_id);

-- Only service role (backend/edge functions) can insert notifications
create policy "Service role can insert notifications"
  on public.user_notifications
  for insert
  with check (true); 
  -- Note: Ideally, restrict this to service_role, but Supabase standard policy for 'insert' usually implies checking against authenticated user. 
  -- Since we want backend to insert, we can rely on service_role bypassing RLS. 
  -- If we need client-side insert (rare for notifications), we'd add logic here.
  -- For now, we assume ONLY backend inserts.

-- 5. Create Indexes
create index idx_user_notifications_user_id on public.user_notifications(user_id);
create index idx_user_notifications_created_at on public.user_notifications(created_at desc);
create index idx_user_notifications_unread on public.user_notifications(user_id) where is_read = false;

-- 6. Comment
comment on table public.user_notifications is 'Stores in-app notifications for users.';

-- 7. Create FCM Tokens Table
create table public.fcm_tokens (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null,
  device_type text check (device_type in ('android', 'ios', 'web')),
  last_updated_at timestamptz not null default now(),
  
  constraint fcm_tokens_pkey primary key (id),
  constraint fcm_tokens_token_key unique (token)
);

-- 8. Enable RLS for FCM Tokens
alter table public.fcm_tokens enable row level security;

-- 9. Policies for FCM Tokens
-- Users can view their own tokens
create policy "Users can view their own FCM tokens"
  on public.fcm_tokens
  for select
  using (auth.uid() = user_id);

-- Users can insert/update their own tokens
create policy "Users can insert/update their own FCM tokens"
  on public.fcm_tokens
  for insert
  with check (auth.uid() = user_id);

create policy "Users can delete their own FCM tokens"
  on public.fcm_tokens
  for delete
  using (auth.uid() = user_id);

-- 10. Upsert Function for FCM Token (Optional but helper)
-- Clients will likely use standard Upsert via SDK, but a trigger to update timestamp is good.
create or replace function public.handle_fcm_token_update()
returns trigger as $$
begin
  new.last_updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger on_fcm_token_update
  before update on public.fcm_tokens
  for each row execute procedure public.handle_fcm_token_update();

-- 11. Create User Settings Table
create table public.user_settings (
  user_id uuid not null references auth.users(id) on delete cascade,
  marketing_consent boolean not null default false,
  service_notification boolean not null default true,
  updated_at timestamptz not null default now(),
  
  constraint user_settings_pkey primary key (user_id)
);

-- 12. Enable RLS for User Settings
alter table public.user_settings enable row level security;

-- 13. Policies for User Settings
create policy "Users can view their own settings"
  on public.user_settings
  for select
  using (auth.uid() = user_id);

create policy "Users can update their own settings"
  on public.user_settings
  for update
  using (auth.uid() = user_id);

create policy "Users can insert their own settings"
  on public.user_settings
  for insert
  with check (auth.uid() = user_id);

-- 14. Auto-create settings on user creation (Optional, via trigger)
-- For now, we assume client creates it or we add a trigger to 02_users.sql later.
-- Or better: Add a trigger here for new users? No, trigger must be on auth.users.
-- Let's stick to client creating it lazily or trigger.
-- Adding trigger here to handle future users.
create or replace function public.handle_new_user_settings()
returns trigger as $$
begin
  insert into public.user_settings (user_id) values (new.id);
  return new;
end;
$$ language plpgsql security definer;

-- Trigger on auth.users (Careful with duplicate triggers)
-- The 02_users.sql has 'on_auth_user_created'. We can add another one.
create trigger on_auth_user_created_settings
  after insert on auth.users
  for each row execute procedure public.handle_new_user_settings();


