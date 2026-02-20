-- 19. PGROONGA: Korean full-text search extension and indexes
set search_path to public, extensions;

-- 1. Extension
create extension if not exists pgroonga;

-- 2. Indexes for full-text search on title columns
-- PGroonga supports Korean (and all CJK languages) natively without dictionary configuration
create index parties_title_pgroonga_idx on public.parties using pgroonga (title);
create index events_title_pgroonga_idx on public.events using pgroonga (title);

-- 3. RPC: Search events by title using PGroonga full-text search
-- Usage: SELECT * FROM search_events_pgroonga('직장인');
-- Operator &@~ supports query syntax: AND (spaces), OR (OR keyword)
create or replace function public.search_events_pgroonga(query text)
returns setof public.events
language sql
stable
security invoker
as $$
  select e.*
  from public.events e
  where query <> '' and e.title &@~ query
  limit 20;
$$;

-- 4. RPC: Search parties by title using PGroonga full-text search
-- Usage: SELECT * FROM search_parties_pgroonga('대학생');
create or replace function public.search_parties_pgroonga(query text)
returns setof public.parties
language sql
stable
security invoker
as $$
  select p.*
  from public.parties p
  where query <> '' and p.title &@~ query
  limit 20;
$$;
