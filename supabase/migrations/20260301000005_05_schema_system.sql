-- 05. System Schema: Notifications, Social, Matching, Files, Settlements, Storage, PGMQ Infra
-- Squashed from: 07_social.sql, 08_matching.sql, 10_storage_buckets.sql, 11_notifications.sql, 13_file_management.sql, 15_settlements.sql, 06_system.sql (tables only)
set search_path to public, extensions;

-- ============================================================
-- 1. Notifications
-- ============================================================

create table public.user_notifications (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  body text not null,
  category public.notification_category not null default 'service',
  deep_link text,
  is_read boolean not null default false,
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint user_notifications_pkey primary key (id)
);

alter table public.user_notifications enable row level security;

create index idx_user_notifications_user_id on public.user_notifications(user_id);
create index idx_user_notifications_created_at on public.user_notifications(created_at desc);
create index idx_user_notifications_unread on public.user_notifications(user_id) where is_read = false;

comment on table public.user_notifications is 'Stores in-app notifications for users.';

create table public.fcm_tokens (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null,
  device_type text check (device_type in ('android', 'ios', 'web')),
  last_updated_at timestamptz not null default now(),
  constraint fcm_tokens_pkey primary key (id),
  constraint fcm_tokens_token_key unique (token)
);

alter table public.fcm_tokens enable row level security;

CREATE INDEX IF NOT EXISTS idx_fcm_tokens_user_id ON public.fcm_tokens(user_id);

create or replace function public.handle_fcm_token_update()
returns trigger as $$
begin
  new.last_updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger on_fcm_token_update
  before update on public.fcm_tokens
  for each row execute procedure public.handle_fcm_token_update();

create table public.user_settings (
  user_id uuid not null references auth.users(id) on delete cascade,
  marketing_consent boolean not null default false,
  service_notification boolean not null default true,
  updated_at timestamptz not null default now(),
  constraint user_settings_pkey primary key (user_id)
);

alter table public.user_settings enable row level security;

create or replace function public.handle_new_user_settings()
returns trigger as $$
begin
  insert into public.user_settings (user_id) values (new.id);
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created_settings
  after insert on auth.users
  for each row execute procedure public.handle_new_user_settings();

-- ============================================================
-- 2. Social Interactions
-- ============================================================

create table public.social_interactions (
  user_id uuid references auth.users on delete cascade not null,
  target_id uuid not null,
  target_type public.social_target_type not null,
  interaction_type public.social_interaction_type not null,
  created_at timestamptz default now(),
  primary key (user_id, target_id, interaction_type)
);

alter table public.social_interactions enable row level security;

create index idx_social_interactions_target 
  on public.social_interactions(target_id, target_type, interaction_type);
create index idx_social_interactions_user 
  on public.social_interactions(user_id, target_type);

-- ============================================================
-- 3. Matching
-- ============================================================

create table public.match_rules (
  id uuid default gen_random_uuid() primary key,
  event_id uuid not null references public.events(id) on delete cascade,
  source_group_id uuid not null references public.entry_groups(id) on delete cascade,
  target_group_id uuid not null references public.entry_groups(id) on delete cascade,
  created_at timestamptz default now(),
  unique(event_id, source_group_id, target_group_id)
);

create table public.match_votes (
  event_id uuid not null references public.events(id) on delete cascade,
  voter_id uuid not null references public.user_profiles(id) on delete cascade,
  candidate_id uuid not null references public.user_profiles(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (event_id, voter_id, candidate_id),
  check (voter_id <> candidate_id)
);

create table public.match_pairs (
  id uuid default gen_random_uuid() primary key,
  event_id uuid not null references public.events(id) on delete cascade,
  user_lower_id uuid not null references public.user_profiles(id) on delete cascade,
  user_higher_id uuid not null references public.user_profiles(id) on delete cascade,
  matched_at timestamptz default now(),
  check (user_lower_id < user_higher_id),
  unique(event_id, user_lower_id, user_higher_id)
);

alter table public.match_rules enable row level security;
alter table public.match_votes enable row level security;
alter table public.match_pairs enable row level security;

create index idx_match_rules_event on public.match_rules(event_id);
create index idx_match_votes_event on public.match_votes(event_id);
create index idx_match_votes_voter on public.match_votes(voter_id);
create index idx_match_pairs_event on public.match_pairs(event_id);
create index idx_match_pairs_users on public.match_pairs(user_lower_id, user_higher_id);
CREATE INDEX IF NOT EXISTS idx_match_rules_source_group_id ON public.match_rules(source_group_id);
CREATE INDEX IF NOT EXISTS idx_match_rules_target_group_id ON public.match_rules(target_group_id);
CREATE INDEX IF NOT EXISTS idx_match_votes_candidate_id ON public.match_votes(candidate_id);

-- Views
create or replace view public.my_matches_view as
select 
  mp.id as match_id,
  mp.event_id,
  mp.matched_at,
  case 
    when mp.user_lower_id = auth.uid() then mp.user_higher_id
    else mp.user_lower_id 
  end as partner_id
from public.match_pairs mp
where mp.user_lower_id = auth.uid() or mp.user_higher_id = auth.uid();

-- Matching Trigger
create or replace function public.handle_new_match_vote()
returns trigger as $$
declare
  u_lower uuid;
  u_higher uuid;
begin
  if exists (
    select 1 from public.match_votes
    where event_id = new.event_id
      and voter_id = new.candidate_id
      and candidate_id = new.voter_id
  ) then
    u_lower := least(new.voter_id, new.candidate_id);
    u_higher := greatest(new.voter_id, new.candidate_id);

    insert into public.match_pairs (event_id, user_lower_id, user_higher_id)
    values (new.event_id, u_lower, u_higher)
    on conflict do nothing;
  end if;
  
  return new;
end;
$$ language plpgsql security definer;

create trigger on_match_vote_created
  after insert on public.match_votes
  for each row execute procedure public.handle_new_match_vote();

-- Secure Contact Function
create or replace function public.get_matched_user_contact(target_user_id uuid, target_event_id uuid)
returns text
as $$
declare
  contact_info text;
begin
  if exists (
    select 1 from public.match_pairs
    where event_id = target_event_id
      and (
        (user_lower_id = auth.uid() and user_higher_id = target_user_id) or
        (user_lower_id = target_user_id and user_higher_id = auth.uid())
      )
  ) then
    select phone_number into contact_info
    from public.user_profiles
    where id = target_user_id;
    
    return contact_info;
  else
    return null;
  end if;
end;
$$ language plpgsql security definer;

-- ============================================================
-- 4. File Management
-- ============================================================

create table public.minglit_files (
  id uuid primary key default gen_random_uuid(),
  storage_object_id uuid not null references storage.objects(id) on delete cascade,
  bucket_id text not null,
  file_path text not null,
  owner_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz default now()
);

create index idx_minglit_files_owner on public.minglit_files(owner_id);
create index idx_minglit_files_path on public.minglit_files(bucket_id, file_path);
CREATE INDEX IF NOT EXISTS idx_minglit_files_storage_object_id ON public.minglit_files(storage_object_id);

create table public.file_access_grants (
  id uuid primary key default gen_random_uuid(),
  file_id uuid not null references public.minglit_files(id) on delete cascade,
  viewer_id uuid not null references auth.users(id) on delete cascade,
  expires_at timestamptz,
  created_at timestamptz default now()
);

create index idx_file_grants_file_viewer on public.file_access_grants(file_id, viewer_id);

alter table public.minglit_files enable row level security;
alter table public.file_access_grants enable row level security;

-- Storage object sync trigger
create or replace function public.handle_storage_object_created()
returns trigger as $$
begin
  insert into public.minglit_files (storage_object_id, bucket_id, file_path, owner_id)
  values (new.id, new.bucket_id, new.name, new.owner);
  return new;
end;
$$ language plpgsql security definer;

create trigger on_storage_object_created
after insert on storage.objects
for each row execute function public.handle_storage_object_created();

-- Application file grant trigger
create or replace function public.handle_new_application_files()
returns trigger as $$
declare
  v_partner_owner_id uuid;
  v_event_end_time timestamptz;
  v_file_record record;
begin
  select e.end_time, perm.user_id
  into v_event_end_time, v_partner_owner_id
  from public.events e
  join public.parties party on e.party_id = party.id
  join public.partner_member_permissions perm on party.partner_id = perm.partner_id
  where e.id = new.event_id 
  and perm.role = 'owner';

  if v_partner_owner_id is null then
    return new;
  end if;

  for v_file_record in
    select id from public.minglit_files
    where file_path like (new.user_id || '/applications/' || new.event_id || '/%')
  loop
    insert into public.file_access_grants (file_id, viewer_id, expires_at)
    values (
      v_file_record.id, 
      v_partner_owner_id, 
      v_event_end_time + interval '30 days'
    );
  end loop;

  return new;
end;
$$ language plpgsql security definer;

create trigger on_application_created
after insert on public.event_applications
for each row execute function public.handle_new_application_files();

-- Event reschedule grant update
create or replace function public.handle_event_reschedule()
returns trigger as $$
begin
  if old.end_time = new.end_time then
    return new;
  end if;

  update public.file_access_grants g
  set expires_at = new.end_time + interval '30 days'
  from public.minglit_files f
  where g.file_id = f.id
  and f.file_path like ('%/applications/' || new.id || '/%');

  return new;
end;
$$ language plpgsql security definer;

create trigger on_event_reschedule
after update of end_time on public.events
for each row execute function public.handle_event_reschedule();

-- ============================================================
-- 5. Settlements
-- ============================================================

create table public.settlements (
  id uuid default gen_random_uuid() primary key,
  partner_id uuid not null references public.partners(id) on delete cascade,
  event_id uuid not null references public.events(id) on delete cascade,
  event_title text not null,
  event_date timestamptz not null,
  total_sales integer not null default 0,
  total_refunds integer not null default 0,
  pg_fee integer not null default 0,
  platform_fee integer not null default 0,
  vat integer not null default 0,
  net_amount integer not null default 0,
  status text not null default 'pending'
    check (status in ('pending', 'ready', 'requested', 'completed')),
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique (event_id)
);

alter table public.settlements enable row level security;

create index settlements_partner_id_idx on public.settlements(partner_id);
create index settlements_status_idx on public.settlements(status);
create index settlements_event_date_idx on public.settlements(event_date);

create trigger handle_updated_at before update on public.settlements
  for each row execute procedure moddatetime(updated_at);

-- Revenue Views
create or replace view public.partner_revenue_stats as
select
  partner_id,
  coalesce(sum(total_sales), 0) as total_sales,
  coalesce(sum(total_refunds), 0) as total_refunds,
  coalesce(sum(net_amount), 0) as net_amount
from public.settlements
group by partner_id;

create or replace view public.partner_monthly_revenue as
select
  partner_id,
  date_trunc('month', event_date)::date as month,
  coalesce(sum(total_sales), 0) as total_sales,
  coalesce(sum(total_refunds), 0) as total_refunds,
  coalesce(sum(net_amount), 0) as net_amount
from public.settlements
group by partner_id, date_trunc('month', event_date)
order by month;

-- Settlement creation trigger
create or replace function public.create_settlement_on_event_completion()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_partner_id uuid;
  v_event_title text;
  v_event_date timestamptz;
  v_total_sales integer := 0;
  v_total_refunds integer := 0;
  v_pg_fee integer := 0;
  v_platform_fee integer := 0;
  v_vat integer := 0;
  v_net_amount integer := 0;
begin
  if (new.status = 'completed' and old.status is distinct from 'completed') then
    select p.partner_id,
      coalesce(new.title, p.title),
      new.end_time
    into v_partner_id, v_event_title, v_event_date
    from public.parties p
    where p.id = new.party_id;

    select
      coalesce(
        sum(case when ea.status in ('paid', 'approved') then ea.payment_amount else 0 end),
        0
      ),
      coalesce(
        sum(case when ea.refund_status = 'completed' then ea.payment_amount else 0 end),
        0
      )
    into v_total_sales, v_total_refunds
    from public.event_applications ea
    where ea.event_id = new.id;

    v_pg_fee := round(v_total_sales * 0.035)::int;
    v_platform_fee := round(v_total_sales * 0.05)::int;
    v_vat := round((v_pg_fee + v_platform_fee) * 0.1)::int;
    v_net_amount := v_total_sales - v_total_refunds - v_pg_fee - v_platform_fee - v_vat;

    insert into public.settlements (
      partner_id, event_id, event_title, event_date,
      total_sales, total_refunds, pg_fee, platform_fee, vat, net_amount, status
    )
    values (
      v_partner_id, new.id, v_event_title, v_event_date,
      v_total_sales, v_total_refunds, v_pg_fee, v_platform_fee, v_vat, v_net_amount, 'pending'
    )
    on conflict (event_id) do update
    set
      event_title = excluded.event_title,
      event_date = excluded.event_date,
      total_sales = excluded.total_sales,
      total_refunds = excluded.total_refunds,
      pg_fee = excluded.pg_fee,
      platform_fee = excluded.platform_fee,
      vat = excluded.vat,
      net_amount = excluded.net_amount,
      updated_at = now();
  end if;
  return new;
end;
$$;

create trigger on_event_completed
  after update of status on public.events
  for each row execute procedure public.create_settlement_on_event_completion();

-- Settlement status transition function (for cron)
create or replace function public.update_settlement_ready_status()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.settlements
  set status = 'ready', updated_at = now()
  where status = 'pending'
  and event_date <= now() - interval '7 days';
end;
$$;

-- ============================================================
-- 6. Storage Buckets
-- ============================================================

insert into storage.buckets (id, name, public)
values 
  ('verification-proofs', 'verification-proofs', false),
  ('party-assets', 'party-assets', true),
  ('partner-proofs', 'partner-proofs', false)
on conflict (id) do nothing;

-- ============================================================
-- 7. PGMQ Infrastructure Tables
-- ============================================================

create table public.processed_events (
  id uuid primary key,
  processed_at timestamptz not null default now()
);

create table public.dead_letter_queue (
  id uuid default gen_random_uuid() primary key,
  msg_id bigint not null,
  queue_name text not null,
  payload jsonb not null,
  error_reason text,
  failed_at timestamptz not null default now()
);

create table public.debug_logs (
  id uuid default gen_random_uuid() primary key,
  message text,
  payload jsonb,
  created_at timestamptz default now()
);

create table public.event_routes (
  id uuid default gen_random_uuid() primary key,
  event_type public.event_type_name not null, 
  target_queue public.event_queue_name not null,
  is_active boolean default true,
  created_at timestamptz default now()
);

alter table public.processed_events enable row level security;
alter table public.dead_letter_queue enable row level security;
alter table public.debug_logs enable row level security;
alter table public.event_routes enable row level security;

create index processed_events_at_idx on public.processed_events(processed_at);
create index dlq_queue_name_idx on public.dead_letter_queue(queue_name);
