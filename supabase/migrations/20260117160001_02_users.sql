-- 02. USERS: Profiles, Roles, Embeddings, Actions

-- 1. Tables
create table public.user_profiles (
  id uuid references auth.users on delete cascade primary key,
  username text unique,
  name text,
  phone_number text unique,
  birth_date date,
  gender gender,
  is_verified boolean default false,
  ci text,
  di text unique,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table public.user_embeddings (
  user_id uuid not null references public.user_profiles(id) on delete cascade primary key,
  embedding vector(1536),
  updated_at timestamptz default now()
);
create index user_embeddings_embedding_idx on public.user_embeddings using hnsw (embedding vector_cosine_ops);

create table public.app_roles (
  user_id uuid references auth.users on delete cascade primary key,
  role text not null check (role in ('super_admin', 'moderator')),
  created_at timestamptz default now()
);

create table public.user_actions (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references public.user_profiles(id) on delete cascade,
  party_id uuid not null, -- FK added later or assumed implicit order? Let's check dependency.
                          -- parties table is in 04_events. So we CANNOT add FK here if we execute sequentially.
                          -- Solution: Add FK in 04_events via ALTER TABLE.
  action_type user_action_type not null,
  created_at timestamptz default now()
);
create index user_actions_user_id_idx on public.user_actions(user_id);
-- party_id index will be created when FK is added

-- 2. Security Functions
create or replace function public.is_super_admin()
returns boolean as $$
  select exists (
    select 1 from public.app_roles 
    where user_id = auth.uid() and role = 'super_admin'
  );
$$ language sql security definer;

-- 3. Triggers
-- Auth Sync
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.user_profiles (
    id, 
    username, 
    name, 
    phone_number,
    birth_date,
    gender,
    is_verified
  )
  values (
    new.id, 
    new.raw_user_meta_data->>'username', 
    new.raw_user_meta_data->>'name', 
    new.raw_user_meta_data->>'phone_number',
    (new.raw_user_meta_data->>'birth_date')::date,
    (new.raw_user_meta_data->>'gender')::public.gender,
    (new.raw_user_meta_data->>'is_verified')::boolean
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Protect Profile Fields
create or replace function public.protect_user_profile_fields()
returns trigger 
set search_path = public
as $$
begin
  if (new.is_verified is distinct from old.is_verified) then
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

-- updated_at triggers
create trigger handle_updated_at before update on public.user_profiles for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.user_embeddings for each row execute procedure moddatetime (updated_at);

-- 4. RLS Policies
alter table public.user_profiles enable row level security;
alter table public.user_embeddings enable row level security;
alter table public.user_actions enable row level security;

-- User Profiles
create policy "Public read access" on public.user_profiles for select using (true);
create policy "Users can update own profile" on public.user_profiles for update using (auth.uid() = id);

-- User Update Own
-- (Already covered by above policy, keeping simple)
