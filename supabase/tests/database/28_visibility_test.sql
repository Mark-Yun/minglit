BEGIN;
SELECT plan(7);

-- Setup: create test partner and parties
INSERT INTO public.partners (id, name, business_number) 
VALUES ('11111111-1111-1111-1111-111111111111', 'Test Partner', '1234567890')
ON CONFLICT (id) DO NOTHING;

-- Public party
INSERT INTO public.parties (id, partner_id, title, status, visibility)
VALUES ('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'PublicPartyTest', 'active', 'public')
ON CONFLICT (id) DO NOTHING;

-- Private party
INSERT INTO public.parties (id, partner_id, title, status, visibility)
VALUES ('33333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', 'PrivatePartyTest', 'active', 'private')
ON CONFLICT (id) DO NOTHING;

-- Public event on public party
INSERT INTO public.events (id, party_id, title, status, start_time, end_time)
VALUES ('44444444-4444-4444-4444-444444444444', '22222222-2222-2222-2222-222222222222', 'PublicEvent', 'scheduled', now() + interval '1 day', now() + interval '2 days')
ON CONFLICT (id) DO NOTHING;

-- Event on private party (inherits private)
INSERT INTO public.events (id, party_id, title, status, start_time, end_time)
VALUES ('55555555-5555-5555-5555-555555555555', '33333333-3333-3333-3333-333333333333', 'PrivateInheritEvent', 'scheduled', now() + interval '1 day', now() + interval '2 days')
ON CONFLICT (id) DO NOTHING;

-- Event with independent visibility override (public event on private party)
INSERT INTO public.events (id, party_id, title, status, start_time, end_time, visibility)
VALUES ('66666666-6666-6666-6666-666666666666', '33333333-3333-3333-3333-333333333333', 'PublicOverrideEvent', 'scheduled', now() + interval '1 day', now() + interval '2 days', 'public')
ON CONFLICT (id) DO NOTHING;

-- Test 1: Private party excluded from search_parties_pgroonga
SELECT is(
  (SELECT count(*)::int FROM search_parties_pgroonga('PrivatePartyTest')),
  0,
  'Private party should not appear in search_parties_pgroonga'
);

-- Test 2: Public party found in search_parties_pgroonga
SELECT is(
  (SELECT count(*)::int FROM search_parties_pgroonga('PublicPartyTest')),
  1,
  'Public party should appear in search_parties_pgroonga'
);

-- Test 3: Private party event excluded from search_events_pgroonga (COALESCE inheritance)
SELECT is(
  (SELECT count(*)::int FROM search_events_pgroonga('PrivatePartyTest')),
  0,
  'Event on private party should not appear in search_events_pgroonga'
);

-- Test 4: Public party event found in search_events_pgroonga
SELECT is(
  (SELECT count(*)::int FROM search_events_pgroonga('PublicPartyTest')),
  1,
  'Event on public party should appear in search_events_pgroonga'
);

-- Test 5: Direct SELECT still accessible (RLS not changed)
SELECT is(
  (SELECT count(*)::int FROM public.parties WHERE id = '33333333-3333-3333-3333-333333333333'),
  1,
  'Private party should still be accessible via direct SELECT'
);

-- Test 6: Default visibility is public
SELECT is(
  (SELECT visibility FROM public.parties WHERE id = '22222222-2222-2222-2222-222222222222'),
  'public',
  'Default party visibility should be public'
);

-- Test 7: Event visibility can be null (inherits from party)
SELECT is(
  (SELECT visibility FROM public.events WHERE id = '55555555-5555-5555-5555-555555555555'),
  NULL::text,
  'Event visibility should be null by default (inherits from party)'
);

SELECT * FROM finish();
ROLLBACK;
