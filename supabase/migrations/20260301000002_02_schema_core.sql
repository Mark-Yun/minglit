-- 02. Core Schema: Users, Partners, Locations, Verifications
-- Squashed from: 02_users.sql, 03_partners.sql, 16_profile_image_url.sql, 24_add_refund_amount.sql (portone), 18_add_fk_indexes.sql
set search_path to public, extensions;

-- ============================================================
-- 1. User Tables
-- ============================================================

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
  profile_image_url text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table public.user_embeddings (
  user_id uuid not null references public.user_profiles(id) on delete cascade primary key,
  embedding extensions.vector(1536),
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
  party_id uuid not null,
  action_type user_action_type not null,
  created_at timestamptz default now()
);
create index user_actions_user_id_idx on public.user_actions(user_id);

-- ============================================================
-- 2. Security Functions
-- ============================================================

create or replace function public.is_super_admin()
returns boolean as $$
  select exists (
    select 1 from public.app_roles 
    where user_id = auth.uid() and role = 'super_admin'
  );
$$ language sql security definer;

-- ============================================================
-- 3. Auth Triggers
-- ============================================================

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

-- ============================================================
-- 4. Partner Tables
-- ============================================================

create table public.partners (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  introduction text,
  address text,
  contact_phone text,
  contact_email text,
  representative_name text,
  biz_name text,
  biz_number text,
  profile_image_url text,
  portone_partner_id text,
  is_active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
create index partners_portone_partner_id_idx on public.partners(portone_partner_id);

create table public.partner_settlements (
  partner_id uuid references public.partners(id) on delete cascade primary key,
  biz_type business_type not null,
  biz_name text not null,
  biz_number text not null,
  representative_name text not null,
  bank_name text not null,
  account_number text not null,
  account_holder text not null,
  tax_email text,
  biz_registration_path text,
  bankbook_path text,
  updated_at timestamptz default now()
);

create table public.partner_member_permissions (
  id uuid default gen_random_uuid() primary key,
  partner_id uuid references public.partners(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  role partner_role default 'staff' not null,
  permissions text[] not null default '{}',
  joined_at timestamptz default now(),
  unique(partner_id, user_id)
);

create table public.partner_applications (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  status partner_application_status default 'pending' not null,
  brand_name text not null,
  introduction text,
  address text,
  contact_phone text,
  contact_email text,
  biz_type business_type not null,
  biz_name text not null,
  biz_number text not null,
  representative_name text not null,
  bank_name text not null,
  account_number text not null,
  account_holder text not null,
  tax_email text,
  biz_registration_path text not null,
  bankbook_path text not null,
  admin_comment text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table public.locations (
  id uuid not null default gen_random_uuid(),
  partner_id uuid not null references public.partners(id) on delete cascade,
  name text not null,
  address text not null,
  address_detail text,
  region_1 text,
  region_2 text,
  region_3 text,
  directions_guide text,
  postal_code text,
  geo_point geography(Point, 4326),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (id)
);
create index locations_geo_point_idx on public.locations using GIST (geo_point);

create table public.verifications (
  id uuid default gen_random_uuid() primary key,
  partner_id uuid references public.partners(id) on delete cascade,
  category verification_category not null,
  internal_name text not null,
  display_name text not null,
  description text,
  icon_key text,
  form_schema jsonb not null default '[]'::jsonb,
  is_active boolean default true,
  created_at timestamptz default now()
);

-- ============================================================
-- 5. Partner Helper Views
-- ============================================================

create or replace view public.locations_view as
select 
  *,
  st_y(geo_point::geometry) as lat,
  st_x(geo_point::geometry) as lng
from public.locations;

-- ============================================================
-- 6. Partner Security Functions
-- ============================================================

create or replace function public.has_partner_permission(p_id uuid, p_key text)
returns boolean as $$
begin
  if public.is_super_admin() then return true; end if;

  return exists (
    select 1 from public.partner_member_permissions
    where partner_id = p_id 
    and user_id = auth.uid()
    and p_key = any(permissions)
  );
end;
$$ language plpgsql security definer;

-- ============================================================
-- 7. Partner Triggers
-- ============================================================

create or replace function public.sync_partner_member_permissions()
returns trigger as $$
begin
  if (new.role = 'owner') then
    new.permissions := array['PARTNER_EDIT', 'SETTLEMENT_VIEW', 'SETTLEMENT_EDIT', 'MEMBER_MANAGE', 'PARTY_MANAGE', 'VERIFY_LIST_VIEW', 'USER_DATA_VIEW', 'VERIFY_REVIEW', 'COMMENT_MANAGE'];
  elsif (new.role = 'manager') then
    new.permissions := array['PARTNER_EDIT', 'PARTY_MANAGE', 'VERIFY_LIST_VIEW', 'USER_DATA_VIEW', 'VERIFY_REVIEW', 'COMMENT_MANAGE'];
  elsif (new.role = 'staff') then
    new.permissions := array['VERIFY_LIST_VIEW', 'COMMENT_MANAGE', 'PARTY_MANAGE'];
  end if;
  return new;
end;
$$ language plpgsql;

create trigger trigger_sync_permissions before insert or update of role on public.partner_member_permissions for each row execute procedure public.sync_partner_member_permissions();

create trigger handle_updated_at before update on public.partners for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.locations for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.partner_applications for each row execute procedure moddatetime (updated_at);

-- ============================================================
-- 8. Enable RLS (all tables)
-- ============================================================

alter table public.user_profiles enable row level security;
alter table public.user_embeddings enable row level security;
alter table public.user_actions enable row level security;
alter table public.app_roles enable row level security;
alter table public.partners enable row level security;
alter table public.partner_settlements enable row level security;
alter table public.partner_member_permissions enable row level security;
alter table public.partner_applications enable row level security;
alter table public.locations enable row level security;
alter table public.verifications enable row level security;

-- ============================================================
-- 9. FK Indexes (core tables)
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_partner_member_permissions_partner_id ON public.partner_member_permissions(partner_id);
CREATE INDEX IF NOT EXISTS idx_partner_member_permissions_user_id ON public.partner_member_permissions(user_id);
CREATE INDEX IF NOT EXISTS idx_partner_applications_user_id ON public.partner_applications(user_id);
CREATE INDEX IF NOT EXISTS idx_locations_partner_id ON public.locations(partner_id);
CREATE INDEX IF NOT EXISTS idx_verifications_partner_id ON public.verifications(partner_id);
