-- 04. EVENTS: Parties, Events, Tickets, Entry Groups

-- 1. Tables
create table public.parties (
  id uuid not null default gen_random_uuid(),
  partner_id uuid not null references public.partners(id) on delete cascade,
  location_id uuid references public.locations(id) on delete set null,
  title text not null,
  description jsonb,
  image_url text,
  contact_options jsonb default '{}'::jsonb,
  required_verification_ids uuid[] default '{}',
  min_confirmed_count integer not null default 0,
  max_participants integer not null default 20,
  status text not null default 'active' check (status in ('draft', 'active', 'closed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (id)
);

create table public.party_embeddings (
  party_id uuid not null references public.parties(id) on delete cascade primary key,
  embedding vector(1536),
  updated_at timestamptz default now()
);
create index party_embeddings_embedding_idx on public.party_embeddings using hnsw (embedding vector_cosine_ops);

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

-- Entry Group Templates (Party Level)
create table public.entry_group_templates (
  id uuid not null default gen_random_uuid(),
  party_id uuid not null references public.parties(id) on delete cascade,
  label text,
  gender gender,
  birth_year_min integer,
  birth_year_max integer,
  required_verification_ids uuid[] default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (id)
);

-- Entry Groups (Event Level)
create table public.entry_groups (
  id uuid not null default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  label text,
  gender gender,
  birth_year_min integer,
  birth_year_max integer,
  required_verification_ids uuid[] default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (id)
);

-- Ticket Templates (Party Level)
create table public.ticket_templates (
  id uuid not null default gen_random_uuid(),
  party_id uuid not null references public.parties(id) on delete cascade,
  name text not null,
  description text,
  price integer not null default 0,
  quantity integer not null,
  target_entry_group_ids uuid[] default '{}',
  required_verification_ids uuid[] default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (id)
);

-- Tickets (Event Level)
create table public.tickets (
  id uuid not null default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  name text not null,
  description text,
  price integer not null default 0,
  quantity integer not null,
  sold_count integer not null default 0,
  target_entry_group_ids uuid[] default '{}',
  required_verification_ids uuid[] default '{}',
  status text not null default 'on_sale' check (status in ('on_sale', 'sold_out', 'hidden')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (id)
);

-- 2. Constraints (Refactored from 171000_add_constraints.sql)
alter table public.tickets add constraint tickets_price_check check (price >= 0);
alter table public.tickets add constraint tickets_quantity_check check (quantity >= 0);
alter table public.events add constraint events_max_participants_check check (max_participants > 0);

-- 3. Triggers
create trigger handle_updated_at before update on public.parties for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.events for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.entry_group_templates for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.entry_groups for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.ticket_templates for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.tickets for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.party_embeddings for each row execute procedure moddatetime (updated_at);

-- 4. RLS Policies
alter table public.parties enable row level security;
alter table public.party_embeddings enable row level security;
alter table public.events enable row level security;
alter table public.entry_group_templates enable row level security;
alter table public.entry_groups enable row level security;
alter table public.ticket_templates enable row level security;
alter table public.tickets enable row level security;

-- Public Read
create policy "Public read access" on public.parties for select using (true);
create policy "Public read access" on public.events for select using (true);
create policy "Public read access" on public.entry_group_templates for select using (true);
create policy "Public read access" on public.entry_groups for select using (true);
create policy "Public read access" on public.ticket_templates for select using (true);
create policy "Public read access" on public.tickets for select using (true);

-- Admin/Owner Write
create policy "Admin/Owner parties all access" on public.parties for all 
  using (public.is_super_admin() or public.has_partner_permission(partner_id, 'PARTY_MANAGE'));

create policy "Admin/Owner events all access" on public.events for all 
  using (
    public.is_super_admin() or 
    exists (
      select 1 from public.parties p
      where p.id = party_id
      and public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  );

create policy "Admin/Owner ticket_templates all access" on public.ticket_templates for all 
  using (
    public.is_super_admin() or 
    exists (
      select 1 from public.parties p
      where p.id = party_id
      and public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  );

create policy "Admin/Owner entry_group_templates all access" on public.entry_group_templates for all 
  using (
    public.is_super_admin() or 
    exists (
      select 1 from public.parties p
      where p.id = party_id
      and public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  );

create policy "Admin/Owner entry_groups all access" on public.entry_groups for all 
  using (
    public.is_super_admin() or 
    exists (
      select 1 from public.events e
      join public.parties p on p.id = e.party_id
      where e.id = event_id
      and public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  );

create policy "Admin/Owner tickets all access" on public.tickets for all 
  using (
    public.is_super_admin() or 
    exists (
      select 1 from public.events e
      join public.parties p on p.id = e.party_id
      where e.id = event_id
      and public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  );
