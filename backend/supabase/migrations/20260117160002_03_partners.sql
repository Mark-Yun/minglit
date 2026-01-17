-- 03. PARTNERS: Partners, Locations, Verifications, Settlements

-- 1. Tables
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
  is_active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

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

-- 2. Helper Views
create or replace view public.locations_view as
select 
  *,
  st_y(geo_point::geometry) as lat,
  st_x(geo_point::geometry) as lng
from public.locations;

-- 3. Security Functions
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

-- 4. Triggers
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

-- 5. RLS Policies
alter table public.partners enable row level security;
alter table public.locations enable row level security;
alter table public.verifications enable row level security;

-- Public Read
create policy "Public read access" on public.partners for select using (true);
create policy "Public read access" on public.locations for select using (true);
create policy "Public read access" on public.verifications for select using (true);

-- Partner Permissions
create policy "Admin/Owner partners all access" on public.partners for all 
  using (public.is_super_admin() or public.has_partner_permission(id, 'PARTNER_EDIT'));

create policy "Users can read own permissions" on public.partner_member_permissions for select 
  using (auth.uid() = user_id or public.is_super_admin() or public.has_partner_permission(partner_id, 'MEMBER_MANAGE'));

create policy "Users can read own applications" on public.partner_applications for select 
  using (auth.uid() = user_id or public.is_super_admin());

create policy "Admin/Owner locations all access" on public.locations for all 
  using (public.is_super_admin() or public.has_partner_permission(partner_id, 'PARTY_MANAGE'));

create policy "Admin/Owner verifications all access" on public.verifications for all 
  using (
    public.is_super_admin() or 
    (partner_id is not null and public.has_partner_permission(partner_id, 'PARTNER_EDIT'))
  );
