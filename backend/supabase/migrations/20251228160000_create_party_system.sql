-- Enable Extensions
create extension if not exists postgis;
create extension if not exists moddatetime schema extensions;

-- 1. Locations: Managed venues by partners
create table public.locations (
  id uuid not null default gen_random_uuid(),
  partner_id uuid not null references public.partners(id) on delete cascade,
  
  name text not null,
  
  -- Detailed Address Structure
  address text not null,       -- Full road address
  address_detail text,         -- Apt/Suite/Unit
  sido text,                   -- Province (Seoul, Gyeonggi)
  sigungu text,                -- City/District (Gangnam-gu)
  
  geo_point geography(Point, 4326),
  
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (id)
);
create index locations_geo_point_idx on public.locations using GIST (geo_point);


-- 2. Parties: Party concepts/templates
create table public.parties (
  id uuid not null default gen_random_uuid(),
  partner_id uuid not null references public.partners(id) on delete cascade,
  
  title text not null,
  description jsonb, -- Rich text
  image_url text,
  
  contact_phone text,
  contact_email text,
  
  -- Default Verification Requirements
  required_verification_ids uuid[] default '{}',
  
  status text not null default 'active' check (status in ('draft', 'active', 'closed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  
  primary key (id)
);


-- 3. Events: Actual instances
create table public.events (
  id uuid not null default gen_random_uuid(),
  party_id uuid not null references public.parties(id) on delete cascade,
  location_id uuid references public.locations(id) on delete set null,
  
  -- Overrides
  title text, 
  description jsonb,
  contact_phone text,
  contact_email text,
  
  start_time timestamptz not null,
  end_time timestamptz not null,
  
  -- Overall Capacity
  max_participants int not null default 20,
  current_participants int not null default 0,
  
  status text not null default 'scheduled' check (status in ('scheduled', 'cancelled', 'completed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  
  primary key (id)
);


-- 4. Event Tickets: The core of sales & restrictions
create table public.event_tickets (
  id uuid not null default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  
  name text not null, -- "Male Early Bird"
  description text,
  price integer not null default 0,
  
  quantity integer not null, -- Total supply
  sold_count integer not null default 0, -- Current confirmed sales
  
  -- Conditions
  gender text check (gender in ('male', 'female')), -- Optional gender lock
  min_birth_year integer, 
  max_birth_year integer,
  required_verification_ids uuid[] default '{}', -- Specific verifications for this ticket
  
  status text not null default 'on_sale' check (status in ('on_sale', 'sold_out', 'hidden')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  
  primary key (id)
);


-- 5. Event Applications: Users applying to join (Pending approval/payment)
create table public.event_applications (
  id uuid not null default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  ticket_id uuid not null references public.event_tickets(id),
  user_id uuid not null references public.user_profiles(id) on delete cascade,
  
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected', 'cancelled', 'paid')),
  
  -- User message to host
  message text,
  
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  
  primary key (id),
  unique (event_id, user_id) -- Prevent duplicate application per event
);


-- 6. Event Participants: Confirmed attendees (Ticket issued)
create table public.event_participants (
  id uuid not null default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  ticket_id uuid not null references public.event_tickets(id),
  user_id uuid not null references public.user_profiles(id) on delete cascade,
  
  -- Link back to application
  application_id uuid references public.event_applications(id),
  
  -- Attendance status
  status text not null default 'ticket_issued' check (status in ('ticket_issued', 'checked_in', 'no_show')),
  
  ticket_code text, -- QR Code or Unique ID
  
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  
  primary key (id),
  unique (event_id, user_id)
);


-- Automate Counts using Triggers --

create or replace function public.update_event_participation_stats()
returns trigger as $$
begin
  if (TG_OP = 'INSERT') then
    update public.events set current_participants = current_participants + 1 where id = NEW.event_id;
    update public.event_tickets set sold_count = sold_count + 1 where id = NEW.ticket_id;
  elsif (TG_OP = 'DELETE') then
    update public.events set current_participants = current_participants - 1 where id = OLD.event_id;
    update public.event_tickets set sold_count = sold_count - 1 where id = OLD.ticket_id;
  end if;
  return null;
end;
$$ language plpgsql security definer;

create trigger on_participant_change
after insert or delete on public.event_participants
for each row execute function public.update_event_participation_stats();


-- Automate updated_at using moddatetime --

create trigger handle_updated_at before update on public.locations for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.parties for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.events for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.event_tickets for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.event_applications for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.event_participants for each row execute procedure moddatetime (updated_at);


-- RLS Policies
alter table public.locations enable row level security;
alter table public.parties enable row level security;
alter table public.events enable row level security;
alter table public.event_tickets enable row level security;
alter table public.event_applications enable row level security;
alter table public.event_participants enable row level security;

-- Public Read Access (Catalog)
create policy "Public read access" on public.locations for select using (true);
create policy "Public read access" on public.parties for select using (true);
create policy "Public read access" on public.events for select using (true);
create policy "Public read access" on public.event_tickets for select using (true);

-- Applications: Users see own, Partners see their events' apps
create policy "User view own applications" on public.event_applications for select using (auth.uid() = user_id);
create policy "User insert own applications" on public.event_applications for insert with check (auth.uid() = user_id);

-- Participants: Users see own, Partners see their events' participants
create policy "User view own participation" on public.event_participants for select using (auth.uid() = user_id);
