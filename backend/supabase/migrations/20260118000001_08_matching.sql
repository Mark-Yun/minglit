-- 08. MATCHING: Real-time Party Matching System

-- 1. Tables

-- Matching Rules: Defines which group can vote for which group in an event.
create table public.match_rules (
  id uuid default gen_random_uuid() primary key,
  event_id uuid not null references public.events(id) on delete cascade,
  source_group_id uuid not null references public.entry_groups(id) on delete cascade,
  target_group_id uuid not null references public.entry_groups(id) on delete cascade,
  created_at timestamptz default now(),
  
  -- Prevent duplicate rules for the same pair in an event
  unique(event_id, source_group_id, target_group_id)
);

-- Match Votes: Stores individual votes (지목).
create table public.match_votes (
  event_id uuid not null references public.events(id) on delete cascade,
  voter_id uuid not null references public.user_profiles(id) on delete cascade,
  candidate_id uuid not null references public.user_profiles(id) on delete cascade,
  created_at timestamptz default now(),
  
  primary key (event_id, voter_id, candidate_id),
  -- A user cannot vote for themselves
  check (voter_id <> candidate_id)
);

-- Match Results: Stores successful mutual matches (성사된 매칭).
create table public.match_results (
  id uuid default gen_random_uuid() primary key,
  event_id uuid not null references public.events(id) on delete cascade,
  user_a_id uuid not null references public.user_profiles(id) on delete cascade,
  user_b_id uuid not null references public.user_profiles(id) on delete cascade,
  matched_at timestamptz default now(),
  
  -- Ensure user_a_id is always smaller than user_b_id to prevent duplicate rows for the same pair
  check (user_a_id < user_b_id),
  unique(event_id, user_a_id, user_b_id)
);

-- 2. Indexes
create index idx_match_rules_event on public.match_rules(event_id);
create index idx_match_votes_event on public.match_votes(event_id);
create index idx_match_votes_voter on public.match_votes(voter_id);
create index idx_match_results_event on public.match_results(event_id);
create index idx_match_results_users on public.match_results(user_a_id, user_b_id);

-- 3. Functions & Triggers

-- Real-time Matching Trigger Function:
-- When a vote is cast, check if the candidate has also voted for the voter.
-- If yes, create a match_result.
create or replace function public.handle_new_match_vote()
returns trigger as $$
begin
  -- Check if mutual vote exists
  if exists (
    select 1 from public.match_votes
    where event_id = new.event_id
      and voter_id = new.candidate_id
      and candidate_id = new.voter_id
  ) then
    -- Create match result
    insert into public.match_results (event_id, user_a_id, user_b_id)
    values (
      new.event_id,
      least(new.voter_id, new.candidate_id),
      greatest(new.voter_id, new.candidate_id)
    )
    on conflict do nothing;
  end if;
  
  return new;
end;
$$ language plpgsql security definer;

create trigger on_match_vote_created
  after insert on public.match_votes
  for each row execute procedure public.handle_new_match_vote();

-- 4. RLS Policies
alter table public.match_rules enable row level security;
alter table public.match_votes enable row level security;
alter table public.match_results enable row level security;

-- Rules: Anyone can see the rules for an event they are participating in
create policy "Anyone can read match rules"
  on public.match_rules for select
  using (true);

-- Votes: Users can only see their own votes and create them
create policy "Users can read own votes"
  on public.match_votes for select
  using (auth.uid() = voter_id);

create policy "Users can cast votes"
  on public.match_votes for insert
  with check (auth.uid() = voter_id);

-- Results: Users can only see matches they are part of
create policy "Users can see own matches"
  on public.match_results for select
  using (auth.uid() = user_a_id or auth.uid() = user_b_id);

-- 5. Secure Phone Number Exposure
-- We need a way to show phone number only if matched.
-- Instead of altering user_profiles, we provide a secure view or function.

create or replace function public.get_matched_user_contact(target_user_id uuid, target_event_id uuid)
returns text
as $$
declare
  contact_info text;
begin
  -- Check if a match exists between current user and target user in the event
  if exists (
    select 1 from public.match_results
    where event_id = target_event_id
      and (
        (user_a_id = auth.uid() and user_b_id = target_user_id) or
        (user_a_id = target_user_id and user_b_id = auth.uid())
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
