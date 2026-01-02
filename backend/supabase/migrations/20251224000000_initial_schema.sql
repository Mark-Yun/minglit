-- 1. Extensions
create extension if not exists postgis;
create extension if not exists moddatetime schema extensions;

-- 2. Enum Types
create type public.gender as enum ('male', 'female');
create type public.partner_role as enum ('owner', 'manager', 'staff');
create type public.verification_status as enum ('pending', 'approved', 'rejected', 'needs_correction', 'cancelled');
create type public.verification_category as enum ('career', 'asset', 'marriage', 'academic', 'vehicle', 'etc');
create type public.partner_application_status as enum ('pending', 'approved', 'rejected', 'needs_correction');
create type public.business_type as enum ('individual', 'corporate');

-- 3. User Profiles
create table public.user_profiles (
  id uuid references auth.users on delete cascade primary key,
  username text unique,
  name text,
  phone_number text unique,
  birth_date date,
  gender gender,
  is_verified boolean default false, -- Global platform verification status
  ci text,
  di text unique,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 4. App Roles (Admin)
create table public.app_roles (
  user_id uuid references auth.users on delete cascade primary key,
  role text not null check (role in ('super_admin', 'moderator')),
  created_at timestamptz default now()
);

-- 5. Partners
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

-- 6. Partner Settlements
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

-- 7. Partner Member Permissions
create table public.partner_member_permissions (
  id uuid default gen_random_uuid() primary key,
  partner_id uuid references public.partners(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  role partner_role default 'staff' not null,
  permissions text[] not null default '{}',
  joined_at timestamptz default now(),
  unique(partner_id, user_id)
);

-- 8. Partner Applications
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

-- 9. Locations
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

-- 10. Verifications (Definition Table)
create table public.verifications (
  id uuid default gen_random_uuid() primary key,
  partner_id uuid references public.partners(id) on delete cascade, -- NULL for Global System Verifications
  
  category verification_category not null, -- Keep for filtering/grouping
  internal_name text not null, -- e.g. "Dolsing Group A - Marriage Cert"
  display_name text not null,  -- e.g. "Marriage Verification"
  description text,
  icon_key text, -- e.g. "document_marriage"

  -- Dynamic Form Schema (JSONB)
  -- e.g. [{ "key": "cert_file", "type": "file", "label": "Upload Cert" }, { "key": "child_cnt", "type": "number", "label": "Children Count" }]
  form_schema jsonb not null default '[]'::jsonb,
  
  is_active boolean default true,
  created_at timestamptz default now()
);

-- 11. Parties
create table public.parties (
  id uuid not null default gen_random_uuid(),
  partner_id uuid not null references public.partners(id) on delete cascade,
  location_id uuid references public.locations(id) on delete set null,
  title text not null,
  description jsonb,
  image_url text,
  contact_options jsonb default '{}'::jsonb,
  
  -- Combined Conditions (JSONB)
  -- e.g. { "gender": "male", "age_range": { "min": 1990 } }
  conditions jsonb default '{}'::jsonb,
  
  -- Required Verification IDs for this party
  required_verification_ids uuid[] default '{}',
  
  min_confirmed_count integer not null default 0,
  max_participants integer not null default 20,
  status text not null default 'active' check (status in ('draft', 'active', 'closed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (id)
);

-- 12. Events
create table public.events (
  id uuid not null default gen_random_uuid(),
  party_id uuid not null references public.parties(id) on delete cascade,
  location_id uuid references public.locations(id) on delete set null,
  title text, 
  description jsonb,
  contact_options jsonb default '{}'::jsonb,
  
  -- Instance-specific conditions (Overrides or adds to party conditions)
  conditions jsonb default '{}'::jsonb,
  
  start_time timestamptz not null,
  end_time timestamptz not null,
  max_participants int not null default 20,
  current_participants int not null default 0,
  status text not null default 'scheduled' check (status in ('scheduled', 'cancelled', 'completed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (id)
);

-- 13. Tickets
create table public.tickets (
  id uuid not null default gen_random_uuid(),
  
  -- Can belong to a Party (Template) or an Event (Instance)
  party_id uuid references public.parties(id) on delete cascade,
  event_id uuid references public.events(id) on delete cascade,
  
  name text not null,
  description text,
  price integer not null default 0,
  quantity integer not null,
  sold_count integer not null default 0,
  
  -- Combined Purchase Conditions (JSONB)
  conditions jsonb default '{}'::jsonb,
  
  -- Ticket specific verification requirements (overrides or adds to party requirements)
  required_verification_ids uuid[] default '{}',
  
  status text not null default 'on_sale' check (status in ('on_sale', 'sold_out', 'hidden')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (id),
  
  -- Ensure it belongs to either a party or an event
  constraint ticket_owner_check check (
    (party_id is not null and event_id is null) or
    (event_id is not null and party_id is null)
  )
);

-- 14. User Verifications (User's Private Vault - The Source of Truth)
create table public.user_verifications (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  verification_id uuid references public.verifications(id) on delete cascade not null,
  
  -- User's input data (includes text values and storage paths)
  data jsonb not null default '{}'::jsonb,
  
  updated_at timestamptz default now(),
  unique(user_id, verification_id)
);

-- 15. Verification Submissions (The History/Log of Requests)
-- Created when user submits their 'user_verification' data to a partner
create table public.verification_submissions (
  id uuid default gen_random_uuid() primary key,
  partner_id uuid references public.partners(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  verification_id uuid references public.verifications(id) on delete cascade not null,
  
  status verification_status default 'pending' not null,
  
  -- Snapshot of data at the time of submission (Immutable, includes files)
  snapshot_data jsonb not null,
  
  admin_comment text, -- Rejection reason or internal note
  
  reviewed_at timestamptz,
  reviewed_by uuid references auth.users(id), -- Staff who reviewed this
  
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 16. Verification Comments (Communication Loop)
create table public.verification_comments (
  id uuid default gen_random_uuid() primary key,
  submission_id uuid references public.verification_submissions(id) on delete cascade not null,
  author_id uuid references auth.users(id) not null,
  content jsonb not null, -- Rich text support
  created_at timestamptz default now()
);

-- 17. Partner Verified Users (The Result Cache / "Entry Pass")
-- OPTIMIZATION TABLE: Only contains valid, approved verifications.
-- Queried when checking if a user can join a party.
create table public.partner_verified_users (
  partner_id uuid references public.partners(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  verification_id uuid references public.verifications(id) on delete cascade not null,
  
  -- The submission that granted this verification
  submission_id uuid references public.verification_submissions(id) on delete cascade not null,
  
  verified_at timestamptz default now(),
  valid_until timestamptz, -- Optional expiration date
  
  primary key (partner_id, user_id, verification_id)
);

-- 18. Event Applications & Participants
create table public.event_applications (
  id uuid not null default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  ticket_id uuid not null references public.tickets(id),
  user_id uuid not null references public.user_profiles(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected', 'cancelled', 'paid')),
  message text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (id),
  unique (event_id, user_id)
);

create table public.event_participants (
  id uuid not null default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  ticket_id uuid not null references public.tickets(id),
  user_id uuid not null references public.user_profiles(id) on delete cascade,
  application_id uuid references public.event_applications(id),
  status text not null default 'ticket_issued' check (status in ('ticket_issued', 'checked_in', 'no_show')),
  ticket_code text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (id),
  unique (event_id, user_id)
);

-- 19. Security Functions --

create or replace function public.is_super_admin()
returns boolean as $$
  select exists (
    select 1 from public.app_roles 
    where user_id = auth.uid() and role = 'super_admin'
  );
$$ language sql security definer;

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

-- 20. Triggers & Helpers --

create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger handle_updated_at before update on public.user_profiles for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.partners for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.locations for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.parties for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.events for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.tickets for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.event_applications for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.event_participants for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.partner_applications for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.verification_submissions for each row execute procedure moddatetime (updated_at);

-- Update participation stats
create or replace function public.update_event_participation_stats()
returns trigger as $$
begin
  if (TG_OP = 'INSERT') then
    update public.events set current_participants = current_participants + 1 where id = NEW.event_id;
    update public.tickets set sold_count = sold_count + 1 where id = NEW.ticket_id;
  elsif (TG_OP = 'DELETE') then
    update public.events set current_participants = current_participants - 1 where id = OLD.event_id;
    update public.tickets set sold_count = sold_count - 1 where id = OLD.ticket_id;
  end if;
  return null;
end;
$$ language plpgsql security definer;

create trigger on_participant_change
after insert or delete on public.event_participants
for each row execute function public.update_event_participation_stats();

-- Sync permissions
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

-- Auth.users -> user_profiles auto sync
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.user_profiles (id, username, name, phone_number)
  values (new.id, new.raw_user_meta_data->>'username', new.raw_user_meta_data->>'name', new.raw_user_meta_data->>'phone_number');
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Auto-Approve Logic (Trigger): When submission is approved, insert into partner_verified_users
create or replace function public.handle_verification_approval()
returns trigger as $$
begin
  if (new.status = 'approved' and old.status != 'approved') then
    insert into public.partner_verified_users (partner_id, user_id, verification_id, submission_id, verified_at)
    values (new.partner_id, new.user_id, new.verification_id, new.id, now())
    on conflict (partner_id, user_id, verification_id) 
    do update set submission_id = new.id, verified_at = now(), valid_until = null; 
  elsif (new.status != 'approved' and old.status = 'approved') then
    -- Revoke verification if status changes back (e.g., cancelled)
    delete from public.partner_verified_users
    where submission_id = new.id;
  end if;
  return new;
end;
$$ language plpgsql security definer;

create trigger on_submission_status_change
  after update on public.verification_submissions
  for each row execute procedure public.handle_verification_approval();

-- 21. Helper Views
-- locations_view: Decodes geography(Point) into separate lat/lng fields.
create or replace view public.locations_view as
select 
  *,
  st_y(geo_point::geometry) as lat,
  st_x(geo_point::geometry) as lng
from public.locations;

-- 22. Storage Buckets
insert into storage.buckets (id, name, public) values ('verification-proofs', 'verification-proofs', false) on conflict (id) do nothing;
insert into storage.buckets (id, name, public) values ('partner-proofs', 'partner-proofs', false) on conflict (id) do nothing;
insert into storage.buckets (id, name, public) values ('party-assets', 'party-assets', true) on conflict (id) do nothing;

-- 22. RLS & Policies
alter table public.user_profiles enable row level security;
alter table public.partners enable row level security;
alter table public.locations enable row level security;
alter table public.parties enable row level security;
alter table public.events enable row level security;
alter table public.tickets enable row level security;
alter table public.event_applications enable row level security;
alter table public.event_participants enable row level security;
alter table public.verifications enable row level security;
alter table public.user_verifications enable row level security;
alter table public.verification_submissions enable row level security;
alter table public.partner_verified_users enable row level security;

-- Public Access
create policy "Public read access" on public.locations for select using (true);
create policy "Public read access" on public.parties for select using (true);
create policy "Public read access" on public.events for select using (true);
create policy "Public read access" on public.tickets for select using (true);
create policy "Public read access" on public.verifications for select using (true);
create policy "Public read access" on public.user_profiles for select using (true);

-- Authenticated Storage
create policy "Allow Authenticated" on storage.objects for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "Public Storage Read" on storage.objects for select using (bucket_id = 'party-assets');

-- 23. Extended RLS Policies (Admin/Owner Write Access)

-- User Profiles
create policy "Users can update own profile" on public.user_profiles for update using (auth.uid() = id);

-- Partners
create policy "Public partners read access" on public.partners for select using (true);
create policy "Admin/Owner partners all access" on public.partners for all 
  using (public.is_super_admin() or public.has_partner_permission(id, 'PARTNER_EDIT'));

-- Partner Member Permissions
create policy "Users can read own permissions" on public.partner_member_permissions for select 
  using (auth.uid() = user_id or public.is_super_admin() or public.has_partner_permission(partner_id, 'MEMBER_MANAGE'));

-- Partner Applications
create policy "Users can read own applications" on public.partner_applications for select 
  using (auth.uid() = user_id or public.is_super_admin());

-- Locations (Write Access)
create policy "Admin/Owner locations all access" on public.locations for all 
  using (public.is_super_admin() or public.has_partner_permission(partner_id, 'PARTY_MANAGE'));

-- Parties (Write Access)
create policy "Admin/Owner parties all access" on public.parties for all 
  using (public.is_super_admin() or public.has_partner_permission(partner_id, 'PARTY_MANAGE'));

-- Events (Write Access)
create policy "Admin/Owner events all access" on public.events for all 
  using (
    public.is_super_admin() or 
    exists (
      select 1 from public.parties p
      where p.id = party_id
      and public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  );

-- Tickets (Write Access)
create policy "Admin/Owner tickets all access" on public.tickets for all 
  using (
    public.is_super_admin() or 
    exists (
      select 1 from public.parties p
      where p.id = party_id
      and public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  );

-- Verifications (Write Access)
create policy "Admin/Owner verifications all access" on public.verifications for all 
  using (
    public.is_super_admin() or 
    (partner_id is not null and public.has_partner_permission(partner_id, 'PARTNER_EDIT'))
  );