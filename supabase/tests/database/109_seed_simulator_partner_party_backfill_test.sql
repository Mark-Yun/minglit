-- Regression test for event-flow-simulator supply:
-- seed.dev.sql must give every authenticatable partner at least one non-closed
-- party so partner_create_event can keep producing events.
--
-- Self-contained: creates its own fixtures and mirrors the Phase 11 seed block.
BEGIN;

SELECT plan(5);

SELECT tests.authenticate_as_service_role();

CREATE TEMP TABLE _seed_sim_backfill_state (
  no_party_partner_id uuid,
  closed_only_partner_id uuid,
  active_partner_id uuid
) ON COMMIT DROP;

DO $$
DECLARE
  no_party_partner_id uuid;
  closed_only_partner_id uuid;
  active_partner_id uuid;
  no_party_user_id uuid;
  closed_only_user_id uuid;
  active_user_id uuid;
BEGIN
  no_party_user_id := tests.create_supabase_user(
    'seed_sim_no_party',
    'seed_sim_no_party@pgtap.local'
  );
  closed_only_user_id := tests.create_supabase_user(
    'seed_sim_closed_only',
    'seed_sim_closed_only@pgtap.local'
  );
  active_user_id := tests.create_supabase_user(
    'seed_sim_active',
    'seed_sim_active@pgtap.local'
  );

  INSERT INTO public.partners (name)
  VALUES ('Seed Sim No Party Partner')
  RETURNING id INTO no_party_partner_id;

  INSERT INTO public.partners (name)
  VALUES ('Seed Sim Closed Only Partner')
  RETURNING id INTO closed_only_partner_id;

  INSERT INTO public.partners (name)
  VALUES ('Seed Sim Active Partner')
  RETURNING id INTO active_partner_id;

  INSERT INTO public.partner_member_permissions (partner_id, user_id, role)
  VALUES
    (no_party_partner_id, no_party_user_id, 'owner'),
    (closed_only_partner_id, closed_only_user_id, 'owner'),
    (active_partner_id, active_user_id, 'owner');

  INSERT INTO public.parties (partner_id, title, status, image_urls)
  VALUES
    (closed_only_partner_id, 'Closed Seed Sim Party', 'closed', '{}'),
    (active_partner_id, 'Existing Active Seed Sim Party', 'active', '{}');

  INSERT INTO _seed_sim_backfill_state
  VALUES (no_party_partner_id, closed_only_partner_id, active_partner_id);
END $$;

CREATE OR REPLACE FUNCTION pg_temp._seed_simulator_party_backfill()
RETURNS void AS $$
DECLARE
  sim_partner_id uuid;
  sim_location_id uuid;
BEGIN
  FOR sim_partner_id IN
    SELECT DISTINCT pmp.partner_id
    FROM public.partner_member_permissions pmp
    WHERE NOT EXISTS (
      SELECT 1 FROM public.parties pa
      WHERE pa.partner_id = pmp.partner_id
        AND pa.status <> 'closed'
    )
  LOOP
    SELECT id INTO sim_location_id FROM public.locations
    WHERE partner_id = sim_partner_id LIMIT 1;

    INSERT INTO public.parties (
      partner_id,
      location_id,
      title,
      max_participants,
      status,
      image_urls
    )
    VALUES (
      sim_partner_id,
      sim_location_id,
      '[SIM] 시뮬레이터 파티',
      20,
      'active',
      ARRAY[
        'https://picsum.photos/seed/minglit-sim-' ||
        replace(sim_partner_id::text, '-', '') ||
        '/800/600'
      ]
    );
  END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT is(
  (
    SELECT count(*)::int
    FROM public.parties
    WHERE partner_id IN (
      SELECT no_party_partner_id FROM _seed_sim_backfill_state
      UNION ALL
      SELECT closed_only_partner_id FROM _seed_sim_backfill_state
    )
      AND status <> 'closed'
  ),
  0,
  'fixtures start without non-closed parties for exhausted partners'
);

SELECT pg_temp._seed_simulator_party_backfill();

SELECT is(
  (
    SELECT count(*)::int
    FROM public.parties
    WHERE partner_id = (
      SELECT no_party_partner_id FROM _seed_sim_backfill_state
    )
      AND status <> 'closed'
  ),
  1,
  'backfill creates a non-closed party when partner has no parties'
);

SELECT is(
  (
    SELECT count(*)::int
    FROM public.parties
    WHERE partner_id = (
      SELECT closed_only_partner_id FROM _seed_sim_backfill_state
    )
      AND status <> 'closed'
  ),
  1,
  'backfill creates a non-closed party when partner only has closed parties'
);

SELECT is(
  (
    SELECT count(*)::int
    FROM public.parties
    WHERE partner_id = (
      SELECT active_partner_id FROM _seed_sim_backfill_state
    )
      AND status <> 'closed'
  ),
  1,
  'backfill does not duplicate partners that already have a non-closed party'
);

SELECT is(
  (
    SELECT count(*)::int
    FROM public.parties
    WHERE title = '[SIM] 시뮬레이터 파티'
      AND status = 'active'
      AND partner_id IN (
        SELECT no_party_partner_id FROM _seed_sim_backfill_state
        UNION ALL
        SELECT closed_only_partner_id FROM _seed_sim_backfill_state
      )
  ),
  2,
  'backfilled simulator parties use the expected active marker'
);

SELECT * FROM finish();
ROLLBACK;
