-- Restore block filter lost in 20260311000001 while keeping visibility filter

-- ============================================================
-- search_events_pgroonga: restore block filter + keep visibility
-- ============================================================

CREATE OR REPLACE FUNCTION public.search_events_pgroonga(query text)
RETURNS SETOF public.events
LANGUAGE sql STABLE SECURITY INVOKER AS $$
  SELECT e.* FROM public.events e
  JOIN public.parties p ON e.party_id = p.id
  WHERE query <> ''
    AND p.title &@~ query
    AND e.status = 'scheduled'
    AND e.start_time >= now()
    AND COALESCE(e.visibility, p.visibility) = 'public'
    AND NOT EXISTS (SELECT 1 FROM public.social_interactions si WHERE si.user_id = auth.uid() AND si.target_id = p.partner_id AND si.interaction_type = 'block')
  ORDER BY e.start_time ASC
  LIMIT 20;
$$;

-- ============================================================
-- search_parties_pgroonga: restore block filter + keep visibility
-- ============================================================

CREATE OR REPLACE FUNCTION public.search_parties_pgroonga(query text)
RETURNS SETOF public.parties
LANGUAGE sql STABLE SECURITY INVOKER AS $$
  SELECT p.* FROM public.parties p
  WHERE query <> ''
    AND p.title &@~ query
    AND p.visibility = 'public'
    AND NOT EXISTS (SELECT 1 FROM public.social_interactions si WHERE si.user_id = auth.uid() AND si.target_id = p.partner_id AND si.interaction_type = 'block')
  LIMIT 20;
$$;
