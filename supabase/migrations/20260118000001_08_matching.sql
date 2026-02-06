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

-- Match Pairs: Stores successful mutual matches (성사된 매칭).
-- Normalized structure: user_lower_id < user_higher_id
create table public.match_pairs (
  id uuid default gen_random_uuid() primary key,
  event_id uuid not null references public.events(id) on delete cascade,
  user_lower_id uuid not null references public.user_profiles(id) on delete cascade,
  user_higher_id uuid not null references public.user_profiles(id) on delete cascade,
  matched_at timestamptz default now(),
  
  -- Ensure ID ordering for uniqueness
  check (user_lower_id < user_higher_id),
  unique(event_id, user_lower_id, user_higher_id)
);

-- 2. Indexes
create index idx_match_rules_event on public.match_rules(event_id);
create index idx_match_votes_event on public.match_votes(event_id);
create index idx_match_votes_voter on public.match_votes(voter_id);
create index idx_match_pairs_event on public.match_pairs(event_id);
create index idx_match_pairs_users on public.match_pairs(user_lower_id, user_higher_id);

-- 3. Views (Convenience Layer)

-- View for Client: Unfolds the pair into a simple "Me -> Partner" structure
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

-- 4. Functions & Triggers

-- Real-time Matching Trigger Function:
-- When a vote is cast, check if the candidate has also voted for the voter.
-- If yes, create a match_pair.
create or replace function public.handle_new_match_vote()
returns trigger as $$
declare
  u_lower uuid;
  u_higher uuid;
begin
  -- Check if mutual vote exists
  if exists (
    select 1 from public.match_votes
    where event_id = new.event_id
      and voter_id = new.candidate_id
      and candidate_id = new.voter_id
  ) then
    -- Determine lower/higher IDs
    u_lower := least(new.voter_id, new.candidate_id);
    u_higher := greatest(new.voter_id, new.candidate_id);

    -- Create match pair (Normalized)
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

-- Secure Phone Number Function
-- Returns phone number ONLY if a match exists in match_pairs
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

-- 5. RLS Policies
alter table public.match_rules enable row level security;
alter table public.match_votes enable row level security;
alter table public.match_pairs enable row level security;

-- Rules
create policy "Anyone can read match rules"
  on public.match_rules for select
  using (true);

-- Votes
create policy "Users can read own votes"
  on public.match_votes for select
  using (auth.uid() = voter_id);

create policy "Users can cast votes"
  on public.match_votes for insert
  with check (auth.uid() = voter_id);

-- Match Pairs (Direct access is restrictive, use View mostly)
create policy "Users can see own matches"
  on public.match_pairs for select
  using (auth.uid() = user_lower_id or auth.uid() = user_higher_id);