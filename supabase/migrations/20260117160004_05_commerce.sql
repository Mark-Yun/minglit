-- 05. COMMERCE: Applications, Submissions, Verified Users, Participants

-- 1. Tables
create table public.event_applications (
  id uuid not null default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  ticket_id uuid not null references public.tickets(id),
  user_id uuid not null references public.user_profiles(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'pending_review', 'approved', 'rejected', 'cancelled', 'paid')),
  message text,
  payment_id text,
  payment_amount integer,
  refund_status text check (refund_status in ('none', 'requested', 'completed', 'failed')) default 'none',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (id),
  unique (event_id, user_id)
);

create table public.verification_submissions (
  id uuid default gen_random_uuid() primary key,
  partner_id uuid references public.partners(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  verification_id uuid references public.verifications(id) on delete cascade not null,
  application_id uuid references public.event_applications(id) on delete cascade, -- Linked application
  status verification_status default 'pending' not null,
  snapshot_data jsonb not null,
  admin_comment text,
  reviewed_at timestamptz,
  reviewed_by uuid references auth.users(id),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
create index verification_submissions_application_id_idx on public.verification_submissions(application_id);

create table public.user_verifications (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  verification_id uuid references public.verifications(id) on delete cascade not null,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz default now(),
  unique(user_id, verification_id)
);

create table public.partner_verified_users (
  partner_id uuid references public.partners(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  verification_id uuid references public.verifications(id) on delete cascade not null,
  submission_id uuid references public.verification_submissions(id) on delete cascade not null,
  verified_at timestamptz default now(),
  valid_until timestamptz,
  primary key (partner_id, user_id, verification_id)
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

create table public.verification_comments (
  id uuid default gen_random_uuid() primary key,
  submission_id uuid references public.verification_submissions(id) on delete cascade not null,
  author_id uuid references auth.users(id) not null,
  content jsonb not null, -- Rich text support
  created_at timestamptz default now()
);

-- 2. Triggers
create trigger handle_updated_at before update on public.event_applications for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.event_participants for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.verification_submissions for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.user_verifications for each row execute procedure moddatetime (updated_at);

-- Participation Stats
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

-- Auto-Approve Logic
create or replace function public.handle_verification_approval()
returns trigger 
set search_path = public
as $$
begin
  if (new.status = 'approved' and old.status != 'approved') then
    -- 1. Create Partner Verified User
    insert into public.partner_verified_users (partner_id, user_id, verification_id, submission_id, verified_at)
    values (new.partner_id, new.user_id, new.verification_id, new.id, now())
    on conflict (partner_id, user_id, verification_id) 
    do update set submission_id = new.id, verified_at = now(), valid_until = null; 

    -- 2. Auto-approve linked Event Application
    if (new.application_id is not null) then
      update public.event_applications
      set status = 'approved', updated_at = now()
      where id = new.application_id
      and status in ('pending', 'pending_review');
    end if;

  elsif (new.status != 'approved' and old.status = 'approved') then
    -- Revoke verification if status changes back
    delete from public.partner_verified_users
    where submission_id = new.id;
  end if;
  return new;
end;
$$ language plpgsql security definer;

create trigger on_submission_status_change
  after update on public.verification_submissions
  for each row execute procedure public.handle_verification_approval();

-- Issue Ticket Logic
create or replace function public.issue_ticket_on_approval()
returns trigger 
set search_path = public
as $$
begin
  if (new.status in ('approved', 'paid') and old.status not in ('approved', 'paid')) then
    insert into public.event_participants (
      event_id, 
      ticket_id, 
      user_id, 
      application_id, 
      status, 
      ticket_code
    )
    values (
      new.event_id,
      new.ticket_id,
      new.user_id,
      new.id,
      'ticket_issued',
      upper(substring(md5(gen_random_uuid()::text) from 1 for 8))
    )
    on conflict (event_id, user_id) do nothing;
  end if;
  return new;
end;
$$ language plpgsql security definer;

create trigger on_application_approval
  after update or insert on public.event_applications
  for each row execute procedure public.issue_ticket_on_approval();

-- 3. RPC Functions
create or replace function public.apply_event(
  p_event_id uuid,
  p_ticket_id uuid,
  p_user_id uuid,
  p_payment_id text,
  p_payment_amount int,
  p_verification_data jsonb default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_app_id uuid;
  v_status text := 'pending_review';
begin
  if (p_verification_data is null) then
    v_status := 'paid';
  end if;

  insert into public.event_applications (
    event_id, ticket_id, user_id, 
    payment_id, payment_amount, status
  )
  values (
    p_event_id, p_ticket_id, p_user_id,
    p_payment_id, p_payment_amount, v_status
  )
  returning id into v_app_id;

  if (p_verification_data is not null) then
    insert into public.user_verifications (user_id, verification_id, data)
    values (
      p_user_id, 
      (p_verification_data->>'verification_id')::uuid, 
      p_verification_data->'data'
    )
    on conflict (user_id, verification_id) 
    do update set data = excluded.data, updated_at = now();

    insert into public.verification_submissions (
      partner_id, user_id, verification_id, application_id,
      status, snapshot_data
    )
    values (
      (p_verification_data->>'partner_id')::uuid,
      p_user_id,
      (p_verification_data->>'verification_id')::uuid,
      v_app_id,
      'pending',
      p_verification_data->'data'
    );
  end if;

  return v_app_id;
end;
$$;

-- 4. RLS Policies
alter table public.event_applications enable row level security;
alter table public.verification_submissions enable row level security;
alter table public.user_verifications enable row level security;
alter table public.partner_verified_users enable row level security;
alter table public.event_participants enable row level security;

-- Event Applications
create policy "Users can read own applications" on public.event_applications for select 
  using (auth.uid() = user_id);
create policy "Users can create own applications" on public.event_applications for insert 
  with check (auth.uid() = user_id);
create policy "Users can update own applications" on public.event_applications for update 
  using (auth.uid() = user_id);
create policy "Users can read own applications (via Partner)" on public.partner_applications for select 
  using (auth.uid() = user_id or public.is_super_admin());

-- Event Participants
create policy "Users can read own participants" on public.event_participants for select 
  using (auth.uid() = user_id);

-- User Verifications
create policy "Users can read/write own verifications" on public.user_verifications for all
  using (auth.uid() = user_id);

-- Verification Submissions
create policy "Users can read own submissions" on public.verification_submissions for select 
  using (auth.uid() = user_id);
create policy "Users can create own submissions" on public.verification_submissions for insert 
  with check (auth.uid() = user_id);

-- Partner Verified Users
create policy "Users can read own verified status" on public.partner_verified_users for select 
  using (auth.uid() = user_id);

-- Partner Admin Access (Submissions & Applications)
-- Note: Assuming has_partner_permission checks partner_id.
-- However, applications/submissions are linked to partner via event or direct FK.
-- RLS policies for Partners to view applications/submissions need to be added here or in partner.sql?
-- Let's add basic partner access here.

create policy "Partner staff can view submissions" on public.verification_submissions for select
  using (public.has_partner_permission(partner_id, 'VERIFY_LIST_VIEW'));

create policy "Partner staff can update submissions" on public.verification_submissions for update
  using (public.has_partner_permission(partner_id, 'VERIFY_REVIEW'));

-- For event_applications, we need to join with events->party->partner to check permission.
-- Complex RLS joins can be slow. For now, rely on API filtering or add partner_id to applications?
-- Let's use EXISTS clause.
create policy "Partner staff can view applications" on public.event_applications for select
  using (
    exists (
      select 1 from public.events e
      join public.parties p on p.id = e.party_id
      where e.id = event_id
      and public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  );
