-- 19. SEARCH: ILIKE-based Korean text search functions
-- Originally used PGroonga but removed due to Groonga engine consuming ~700MB
-- of disk space (incompatible with Free plan 0.5GB limit).
-- ILIKE is sufficient for small datasets; re-evaluate when data grows.
set search_path to public, extensions;

-- RPC: Search events by title using ILIKE
-- Usage: SELECT * FROM search_events_pgroonga('직장인');
create or replace function public.search_events_pgroonga(query text)
returns setof public.events
language sql
stable
security invoker
as $$
  select e.*
  from public.events e
  where query <> '' and e.title ilike '%' || query || '%'
  limit 20;
$$;

-- RPC: Search parties by title using ILIKE
-- Usage: SELECT * FROM search_parties_pgroonga('대학생');
create or replace function public.search_parties_pgroonga(query text)
returns setof public.parties
language sql
stable
security invoker
as $$
  select p.*
  from public.parties p
  where query <> '' and p.title ilike '%' || query || '%'
  limit 20;
$$;
