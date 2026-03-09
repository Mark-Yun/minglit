-- Fix search_events_pgroonga to search parties.title instead of events.title
-- (events.title is almost always null; real titles are in parties.title)
-- Also add status + date filters to only return upcoming scheduled events.

CREATE OR REPLACE FUNCTION public.search_events_pgroonga(query text)
RETURNS SETOF public.events
LANGUAGE sql STABLE SECURITY INVOKER AS $$
  SELECT e.* FROM public.events e
  JOIN public.parties p ON e.party_id = p.id
  WHERE query <> ''
    AND p.title &@~ query
    AND e.status = 'scheduled'
    AND e.start_time >= now()
  ORDER BY e.start_time ASC
  LIMIT 20;
$$;
