-- 07. SOCIAL: Interactions, Subscriptions, Bookmarks
set search_path to public, extensions;

-- 1. Enum Types
create type public.social_target_type as enum ('party', 'partner', 'review', 'comment');
create type public.social_interaction_type as enum ('like', 'subscribe', 'bookmark', 'block');

-- 2. Tables
create table public.social_interactions (
  user_id uuid references auth.users on delete cascade not null,
  target_id uuid not null, -- Polymorphic target ID
  target_type public.social_target_type not null,
  interaction_type public.social_interaction_type not null,
  created_at timestamptz default now(),
  
  -- Composite Primary Key: Prevents duplicate interactions and supports toggle logic
  primary key (user_id, target_id, interaction_type)
);

-- 3. Indexes (Optimization)
-- For counting likes/subscribers per target
create index idx_social_interactions_target 
  on public.social_interactions(target_id, target_type, interaction_type);

-- For listing user's activity (e.g., my liked parties)
create index idx_social_interactions_user 
  on public.social_interactions(user_id, target_type);

-- 4. RLS Policies
alter table public.social_interactions enable row level security;

-- Anyone can see counts (aggregated data)
create policy "Anyone can view interactions"
  on public.social_interactions for select
  using (true);

-- Only owners can manage their interactions
create policy "Users can manage own interactions"
  on public.social_interactions for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
