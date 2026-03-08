-- Fixes #35: pgroonga was never enabled because previous migration silently caught errors.
CREATE EXTENSION IF NOT EXISTS pgroonga;

CREATE INDEX IF NOT EXISTS parties_title_pgroonga_idx ON public.parties USING pgroonga (title);
CREATE INDEX IF NOT EXISTS events_title_pgroonga_idx ON public.events USING pgroonga (title);
CREATE OR REPLACE FUNCTION public.search_events_pgroonga(query text)
RETURNS SETOF public.events
LANGUAGE sql STABLE SECURITY INVOKER AS $$
  SELECT e.* FROM public.events e
  WHERE query <> '' AND e.title &@~ query LIMIT 20;
$$;

CREATE OR REPLACE FUNCTION public.search_parties_pgroonga(query text)
RETURNS SETOF public.parties
LANGUAGE sql STABLE SECURITY INVOKER AS $$
  SELECT p.* FROM public.parties p
  WHERE query <> '' AND p.title &@~ query LIMIT 20;
$$;
