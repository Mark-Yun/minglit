-- Ref #1563: matching trigger behavior tests migrated from Dart S04 scenario
-- Verifies handle_new_match_vote trigger (TC-S04-2, TC-S04-3):
--   bidirectional votes → match_pair auto-creation
--   one-directional vote → no match_pair
BEGIN;
SELECT plan(5);

SELECT tests.authenticate_as_service_role();

-- Setup: partner, party, event, two entry groups, two users, two participants
CREATE TEMP TABLE matching_setup (
  partner_id uuid,
  party_id    uuid,
  event_id    uuid,
  group_a_id  uuid,
  group_b_id  uuid,
  user_a_id   uuid,
  user_b_id   uuid
);

DO $$
DECLARE
  v_partner_id uuid;
  v_party_id   uuid;
  v_event_id   uuid;
  v_group_a    uuid;
  v_group_b    uuid;
  v_user_a     uuid;
  v_user_b     uuid;
BEGIN
  v_user_a := tests.create_supabase_user('match_trigger_user_a');
  v_user_b := tests.create_supabase_user('match_trigger_user_b');

  INSERT INTO public.partners (name)
  VALUES ('Match Trigger Partner')
  RETURNING id INTO v_partner_id;

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
  VALUES (v_partner_id, 'Match Trigger Party', 0, 20)
  RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants)
  VALUES (v_party_id, now() - interval '3 hours', now() + interval '1 hour', 0, 20)
  RETURNING id INTO v_event_id;

  INSERT INTO public.entry_groups (event_id, gender)
  VALUES (v_event_id, 'male')
  RETURNING id INTO v_group_a;

  INSERT INTO public.entry_groups (event_id, gender)
  VALUES (v_event_id, 'female')
  RETURNING id INTO v_group_b;

  -- Both participants checked_in (required for voting eligibility at EF layer;
  -- trigger itself does not check check-in status, but we mirror real usage)
  INSERT INTO public.event_participants (event_id, user_id, entry_group_id, status)
  VALUES
    (v_event_id, v_user_a, v_group_a, 'checked_in'),
    (v_event_id, v_user_b, v_group_b, 'checked_in');

  INSERT INTO matching_setup (partner_id, party_id, event_id, group_a_id, group_b_id, user_a_id, user_b_id)
  VALUES (v_partner_id, v_party_id, v_event_id, v_group_a, v_group_b, v_user_a, v_user_b);
END $$;

-- TC-S04-2a: First vote (A → B) alone must NOT create a match_pair
DO $$
DECLARE
  v_event_id uuid := (SELECT event_id FROM matching_setup);
  v_user_a   uuid := (SELECT user_a_id FROM matching_setup);
  v_user_b   uuid := (SELECT user_b_id FROM matching_setup);
BEGIN
  INSERT INTO public.match_votes (event_id, voter_id, candidate_id)
  VALUES (v_event_id, v_user_a, v_user_b);
END $$;

SELECT is(
  (SELECT count(*)::int FROM public.match_pairs mp
   JOIN matching_setup s ON mp.event_id = s.event_id),
  0,
  'TC-S04-2a: single vote A→B must not create a match_pair'
);

-- TC-S04-2b: Reverse vote (B → A) completes bidirectional match → pair must be created
DO $$
DECLARE
  v_event_id uuid := (SELECT event_id FROM matching_setup);
  v_user_a   uuid := (SELECT user_a_id FROM matching_setup);
  v_user_b   uuid := (SELECT user_b_id FROM matching_setup);
BEGIN
  INSERT INTO public.match_votes (event_id, voter_id, candidate_id)
  VALUES (v_event_id, v_user_b, v_user_a);
END $$;

SELECT is(
  (SELECT count(*)::int FROM public.match_pairs mp
   JOIN matching_setup s ON mp.event_id = s.event_id),
  1,
  'TC-S04-2b: bidirectional votes A↔B must create exactly 1 match_pair'
);

-- TC-S04-2c: Canonical ordering — user_lower_id < user_higher_id lexicographically
SELECT ok(
  (SELECT (mp.user_lower_id::text < mp.user_higher_id::text)
   FROM public.match_pairs mp
   JOIN matching_setup s ON mp.event_id = s.event_id
   LIMIT 1),
  'TC-S04-2c: match_pair user_lower_id must be lexicographically less than user_higher_id'
);

-- TC-S04-2d: Pair must contain exactly user_a and user_b
SELECT ok(
  (SELECT
     (mp.user_lower_id = LEAST(s.user_a_id, s.user_b_id) AND
      mp.user_higher_id = GREATEST(s.user_a_id, s.user_b_id))
   FROM public.match_pairs mp
   JOIN matching_setup s ON mp.event_id = s.event_id
   LIMIT 1),
  'TC-S04-2d: match_pair must contain exactly user_a and user_b in canonical order'
);

-- TC-S04-3: One-directional vote (A → third user, no reverse) must NOT create pair
DO $$
DECLARE
  v_event_id uuid := (SELECT event_id FROM matching_setup);
  v_user_a   uuid := (SELECT user_a_id FROM matching_setup);
  v_group_b  uuid := (SELECT group_b_id FROM matching_setup);
  v_user_c   uuid;
BEGIN
  v_user_c := tests.create_supabase_user('match_trigger_user_c');

  INSERT INTO public.event_participants (event_id, user_id, entry_group_id, status)
  VALUES (v_event_id, v_user_c, v_group_b, 'checked_in');

  -- Only A → C; no reverse vote
  INSERT INTO public.match_votes (event_id, voter_id, candidate_id)
  VALUES (v_event_id, v_user_a, v_user_c);

  -- Pair count for A-C must still be 0 (only the A-B pair from TC-S04-2 exists)
  IF EXISTS (
    SELECT 1 FROM public.match_pairs
    WHERE event_id = v_event_id
      AND ((user_lower_id = LEAST(v_user_a, v_user_c) AND user_higher_id = GREATEST(v_user_a, v_user_c)))
  ) THEN
    RAISE EXCEPTION 'One-directional vote A→C must not create match_pair';
  END IF;
END $$;

SELECT ok(
  true,
  'TC-S04-3: one-directional vote A→C must not create a match_pair for A-C'
);

SELECT * FROM finish();
ROLLBACK;
