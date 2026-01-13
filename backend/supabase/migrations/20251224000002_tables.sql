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

-- User Embeddings
create table public.user_embeddings (
  user_id uuid not null references public.user_profiles(id) on delete cascade primary key,
  embedding vector(1536), -- OpenAI text-embedding-3-small dimension
  updated_at timestamptz default now()
);
create index user_embeddings_embedding_idx on public.user_embeddings using hnsw (embedding vector_cosine_ops);

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

-- Locations View
create or replace view public.locations_view as
select 
  *,
  st_y(geo_point::geometry) as lat,
  st_x(geo_point::geometry) as lng
from public.locations;

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
  
  -- Required Verification IDs for this party
  required_verification_ids uuid[] default '{}',
  
  min_confirmed_count integer not null default 0,
  max_participants integer not null default 20,
  status text not null default 'active' check (status in ('draft', 'active', 'closed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (id)
);

-- Party Embeddings
create table public.party_embeddings (
  party_id uuid not null references public.parties(id) on delete cascade primary key,
  embedding vector(1536),
  updated_at timestamptz default now()
);
create index party_embeddings_embedding_idx on public.party_embeddings using hnsw (embedding vector_cosine_ops);

-- User Actions (Depends on User Profile and Party)
create table public.user_actions (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references public.user_profiles(id) on delete cascade,
  party_id uuid not null references public.parties(id) on delete cascade,
  action_type user_action_type not null,
  created_at timestamptz default now()
);
create index user_actions_user_id_idx on public.user_actions(user_id);
create index user_actions_party_id_idx on public.user_actions(party_id);

-- Initialize PGMQ Queue
select pgmq.create('recommendation_updates');

-- 12. Events
create table public.events (
  id uuid not null default gen_random_uuid(),
  party_id uuid not null references public.parties(id) on delete cascade,
  location_id uuid references public.locations(id) on delete set null,
  title text, 
  description jsonb,
  contact_options jsonb default '{}'::jsonb,
  
  start_time timestamptz not null,
  end_time timestamptz not null,
  max_participants int not null default 20,
  current_participants int not null default 0,
  status text not null default 'scheduled' check (status in ('scheduled', 'cancelled', 'completed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (id)
);

-- 13. Entry Groups (Templates & Instances)
create table public.entry_group_templates (
  id uuid not null default gen_random_uuid(),
  party_id uuid not null references public.parties(id) on delete cascade,
  
  label text,
  gender gender,
  birth_year_min integer,
  birth_year_max integer,
  
  -- Required Verification IDs for this group
  required_verification_ids uuid[] default '{}',
  
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (id)
);

create table public.entry_groups (
  id uuid not null default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  
  label text,
  gender gender,
  birth_year_min integer,
  birth_year_max integer,
  
  -- Required Verification IDs for this group
  required_verification_ids uuid[] default '{}',
  
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (id)
);

-- 14. Ticket Templates & Tickets
create table public.ticket_templates (
  id uuid not null default gen_random_uuid(),
  party_id uuid not null references public.parties(id) on delete cascade,
  
  name text not null,
  description text,
  price integer not null default 0,
  quantity integer not null,
  
  -- Linked Entry Group IDs (UUID Array)
  target_entry_group_ids uuid[] default '{}',
  
  -- Ticket specific verification requirements
  required_verification_ids uuid[] default '{}',
  
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (id)
);

create table public.tickets (
  id uuid not null default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  
  name text not null,
  description text,
  price integer not null default 0,
  quantity integer not null,
  sold_count integer not null default 0,
  
  -- Linked Entry Group IDs (UUID Array)
  target_entry_group_ids uuid[] default '{}',
  
  -- Ticket specific verification requirements
  required_verification_ids uuid[] default '{}',
  
  status text not null default 'on_sale' check (status in ('on_sale', 'sold_out', 'hidden')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (id)
);

-- 15. User Verifications (User's Private Vault - The Source of Truth)
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

-- Storage Buckets
insert into storage.buckets (id, name, public) values ('verification-proofs', 'verification-proofs', false) on conflict (id) do nothing;
insert into storage.buckets (id, name, public) values ('partner-proofs', 'partner-proofs', false) on conflict (id) do nothing;
insert into storage.buckets (id, name, public) values ('party-assets', 'party-assets', true) on conflict (id) do nothing;
