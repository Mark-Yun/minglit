-- RLS & Policies
alter table public.user_profiles enable row level security;
alter table public.partners enable row level security;
alter table public.locations enable row level security;
alter table public.parties enable row level security;
alter table public.events enable row level security;
alter table public.entry_group_templates enable row level security;
alter table public.entry_groups enable row level security;
alter table public.ticket_templates enable row level security;
alter table public.tickets enable row level security;
alter table public.event_applications enable row level security;
alter table public.event_participants enable row level security;
alter table public.verifications enable row level security;
alter table public.user_verifications enable row level security;
alter table public.verification_submissions enable row level security;
alter table public.partner_verified_users enable row level security;
-- New tables policies (Default Deny for now, will add basic policies)
alter table public.user_embeddings enable row level security;
alter table public.party_embeddings enable row level security;
alter table public.user_actions enable row level security;

-- Public Access
create policy "Public read access" on public.locations for select using (true);
create policy "Public read access" on public.parties for select using (true);
create policy "Public read access" on public.events for select using (true);
create policy "Public read access" on public.entry_group_templates for select using (true);
create policy "Public read access" on public.entry_groups for select using (true);
create policy "Public read access" on public.ticket_templates for select using (true);
create policy "Public read access" on public.tickets for select using (true);
create policy "Public read access" on public.verifications for select using (true);
create policy "Public read access" on public.user_profiles for select using (true);

-- Authenticated Storage
create policy "Allow Authenticated" on storage.objects for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "Public Storage Read" on storage.objects for select using (bucket_id = 'party-assets');

-- Extended RLS Policies (Admin/Owner Write Access)
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

-- Ticket Templates (Write Access)
create policy "Admin/Owner ticket_templates all access" on public.ticket_templates for all 
  using (
    public.is_super_admin() or 
    exists (
      select 1 from public.parties p
      where p.id = party_id
      and public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  );

-- Entry Group Templates (Write Access)
create policy "Admin/Owner entry_group_templates all access" on public.entry_group_templates for all 
  using (
    public.is_super_admin() or 
    exists (
      select 1 from public.parties p
      where p.id = party_id
      and public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  );

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

-- Entry Groups (Write Access)
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

-- Tickets (Write Access)
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

-- Verifications (Write Access)
create policy "Admin/Owner verifications all access" on public.verifications for all 
  using (
    public.is_super_admin() or 
    (partner_id is not null and public.has_partner_permission(partner_id, 'PARTNER_EDIT'))
  );
