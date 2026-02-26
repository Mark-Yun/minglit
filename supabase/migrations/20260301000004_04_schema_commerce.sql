-- 04. Commerce Schema: Applications, Submissions, Verified Users, Participants
-- Squashed from: 05_commerce.sql, 09_refund_trigger.sql, 24_rls_hardening.sql, 24_add_refund_amount.sql, 26_fix_payment_status.sql, 28_event_reminder_cron.sql (column), 18_add_fk_indexes.sql
set search_path to public, extensions;

-- ============================================================
-- 1. Tables
-- ============================================================

create table public.event_applications (
  id uuid not null default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  ticket_id uuid not null references public.tickets(id),
  user_id uuid not null references public.user_profiles(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'pending_review', 'approved', 'rejected', 'cancelled', 'paid', 'payment_failed', 'payment_pending')),
  message text,
  payment_id text,
  payment_amount integer,
  refund_amount integer default 0,
  refund_status text check (refund_status in ('none', 'requested', 'completed', 'failed')) default 'none',
  rejection_reason text,
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
  application_id uuid references public.event_applications(id) on delete cascade,
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
  display_name text,
  birth_year int,
  reminder_sent_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (id),
  unique (event_id, user_id)
);

create table public.verification_comments (
  id uuid default gen_random_uuid() primary key,
  submission_id uuid references public.verification_submissions(id) on delete cascade not null,
  author_id uuid references auth.users(id) not null,
  content jsonb not null,
  created_at timestamptz default now()
);

-- ============================================================
-- 2. Triggers
-- ============================================================

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

-- ============================================================
-- 3. Auto-Approve / Verification Logic
-- ============================================================

-- handle_verification_approval (FINAL version from 09_refund_trigger.sql)
create or replace function public.handle_verification_approval()
returns trigger 
set search_path = public
as $$
begin
  -- 1. Handling Approval
  if (new.status = 'approved' and old.status is distinct from 'approved') then
    insert into public.partner_verified_users (partner_id, user_id, verification_id, submission_id, verified_at)
    values (new.partner_id, new.user_id, new.verification_id, new.id, now())
    on conflict (partner_id, user_id, verification_id) 
    do update set submission_id = new.id, verified_at = now(), valid_until = null; 

    if (new.application_id is not null) then
      update public.event_applications
      set status = 'approved', updated_at = now()
      where id = new.application_id
      and status in ('pending', 'pending_review');
    end if;
  end if;

  -- 2. Handling Rejection
  if (new.status = 'rejected' and old.status is distinct from 'rejected') then
    if (new.application_id is not null) then
      update public.event_applications
      set 
        status = 'rejected',
        rejection_reason = new.admin_comment,
        updated_at = now()
      where id = new.application_id;
    end if;
  end if;

  -- 3. Revoking
  if (old.status = 'approved' and new.status is distinct from 'approved') then
    delete from public.partner_verified_users
    where submission_id = new.id;
  end if;

  return new;
end;
$$ language plpgsql security definer;

create trigger on_submission_status_change
  after update on public.verification_submissions
  for each row execute procedure public.handle_verification_approval();

-- issue_ticket_on_approval (FINAL version from 24_rls_hardening.sql with display_name/birth_year)
CREATE OR REPLACE FUNCTION public.issue_ticket_on_approval()
RETURNS trigger
SET search_path = public
AS $$
DECLARE
  v_display_name text;
  v_birth_year int;
BEGIN
  IF (new.status IN ('approved', 'paid') AND old.status NOT IN ('approved', 'paid')) THEN
    SELECT name, extract(year FROM birth_date)::int
    INTO v_display_name, v_birth_year
    FROM public.user_profiles WHERE id = new.user_id;

    INSERT INTO public.event_participants (
      event_id, ticket_id, user_id, application_id, status, ticket_code,
      display_name, birth_year
    )
    VALUES (
      new.event_id, new.ticket_id, new.user_id, new.id, 'ticket_issued',
      upper(substring(md5(gen_random_uuid()::text) FROM 1 FOR 8)),
      v_display_name, v_birth_year
    )
    ON CONFLICT (event_id, user_id) DO NOTHING;
  END IF;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

create trigger on_application_approval
  after update or insert on public.event_applications
  for each row execute procedure public.issue_ticket_on_approval();

-- handle_application_rejection (calls cancel-payment Edge Function)
create or replace function public.handle_application_rejection()
returns trigger
language plpgsql
security definer
set search_path = public, extensions, net
as $$
declare
  v_payment_id text;
  v_reason text;
  v_project_url text := 'https://cnuahgrfzcqkmdyhunuk.supabase.co';
  v_service_key text;
begin
  if new.status = 'rejected' and (old.status is distinct from 'rejected') then
    v_payment_id := new.payment_id;
    v_reason := new.rejection_reason;

    if v_payment_id is not null then
      select decrypted_secret into v_service_key 
      from vault.decrypted_secrets 
      where name = 'service_role_key' limit 1;

      perform net.http_post(
        url := v_project_url || '/functions/v1/cancel-payment',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || v_service_key
        ),
        body := jsonb_build_object(
          'payment_id', v_payment_id,
          'reason', v_reason
        )
      );

      new.refund_status := 'requested';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists on_application_rejected on public.event_applications;
create trigger on_application_rejected
  before update on public.event_applications
  for each row
  execute function public.handle_application_rejection();

-- ============================================================
-- 4. Enable RLS
-- ============================================================

alter table public.event_applications enable row level security;
alter table public.verification_submissions enable row level security;
alter table public.user_verifications enable row level security;
alter table public.partner_verified_users enable row level security;
alter table public.event_participants enable row level security;
alter table public.verification_comments enable row level security;

-- ============================================================
-- 5. FK Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_event_applications_event_id ON public.event_applications(event_id);
CREATE INDEX IF NOT EXISTS idx_event_applications_ticket_id ON public.event_applications(ticket_id);
CREATE INDEX IF NOT EXISTS idx_event_applications_user_id ON public.event_applications(user_id);
CREATE INDEX IF NOT EXISTS idx_verification_submissions_partner_id ON public.verification_submissions(partner_id);
CREATE INDEX IF NOT EXISTS idx_verification_submissions_user_id ON public.verification_submissions(user_id);
CREATE INDEX IF NOT EXISTS idx_verification_submissions_verification_id ON public.verification_submissions(verification_id);
CREATE INDEX IF NOT EXISTS idx_verification_submissions_reviewed_by ON public.verification_submissions(reviewed_by);
CREATE INDEX IF NOT EXISTS idx_user_verifications_verification_id ON public.user_verifications(verification_id);
CREATE INDEX IF NOT EXISTS idx_partner_verified_users_submission_id ON public.partner_verified_users(submission_id);
CREATE INDEX IF NOT EXISTS idx_event_participants_ticket_id ON public.event_participants(ticket_id);
CREATE INDEX IF NOT EXISTS idx_event_participants_user_id ON public.event_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_event_participants_application_id ON public.event_participants(application_id);
CREATE INDEX IF NOT EXISTS idx_verification_comments_submission_id ON public.verification_comments(submission_id);
CREATE INDEX IF NOT EXISTS idx_verification_comments_author_id ON public.verification_comments(author_id);
