BEGIN;
SELECT plan(6);

SELECT tests.authenticate_as_service_role();

DO $$
DECLARE
  v_partner_id uuid;
  v_party_id   uuid;
  v_event_id   uuid;
  v_group_a_id uuid;
  v_group_b_id uuid;
BEGIN
  INSERT INTO public.partners (name) VALUES ('TEC Test Partner') RETURNING id INTO v_partner_id;
  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
  VALUES (v_partner_id, 'TEC Party', 0, 10) RETURNING id INTO v_party_id;
  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants)
  VALUES (v_party_id, now() + interval '1 day', now() + interval '1 day 2 hours', 0, 10)
  RETURNING id INTO v_event_id;
  INSERT INTO public.entry_groups (event_id, label) VALUES (v_event_id, 'A') RETURNING id INTO v_group_a_id;
  INSERT INTO public.entry_groups (event_id, label) VALUES (v_event_id, 'B') RETURNING id INTO v_group_b_id;
  PERFORM set_config('tests.tec_party_id',   v_party_id::text,   true);
  PERFORM set_config('tests.tec_event_id',   v_event_id::text,   true);
  PERFORM set_config('tests.tec_group_a_id', v_group_a_id::text, true);
  PERFORM set_config('tests.tec_group_b_id', v_group_b_id::text, true);
END $$;

-- Test 1: empty target_entry_group_ids is allowed (global ticket)
SELECT lives_ok(
  format(
    $$INSERT INTO public.tickets (event_id, name, quantity, price, target_entry_group_ids)
      VALUES ('%s'::uuid, 'Global Ticket', 5, 0, '{}')$$,
    current_setting('tests.tec_event_id')
  ),
  'tickets_entry_group_single: empty array (global ticket) is allowed'
);

-- Test 2: single entry group is allowed
SELECT lives_ok(
  format(
    $$INSERT INTO public.tickets (event_id, name, quantity, price, target_entry_group_ids)
      VALUES ('%s'::uuid, 'Group A Ticket', 5, 0, ARRAY['%s'::uuid])$$,
    current_setting('tests.tec_event_id'),
    current_setting('tests.tec_group_a_id')
  ),
  'tickets_entry_group_single: single entry group is allowed'
);

-- Test 3: two entry group ids violates constraint
SELECT throws_ok(
  format(
    $$INSERT INTO public.tickets (event_id, name, quantity, price, target_entry_group_ids)
      VALUES ('%s'::uuid, 'Multi Group Ticket', 5, 0, ARRAY['%s'::uuid, '%s'::uuid])$$,
    current_setting('tests.tec_event_id'),
    current_setting('tests.tec_group_a_id'),
    current_setting('tests.tec_group_b_id')
  ),
  '23514',
  NULL,
  'tickets_entry_group_single: two entry group ids violates constraint'
);

-- Tests 4–6: same invariant must hold at the template source (ticket_templates).
-- Without this, a multi-group template would pass party creation but fail when
-- events are generated and tickets are inserted from the template.

-- Test 4: empty target_entry_group_ids is allowed on ticket_templates (global template)
SELECT lives_ok(
  format(
    $$INSERT INTO public.ticket_templates (party_id, name, quantity, price, target_entry_group_ids)
      VALUES ('%s'::uuid, 'Global Template', 5, 0, '{}')$$,
    current_setting('tests.tec_party_id')
  ),
  'ticket_templates_entry_group_single: empty array (global template) is allowed'
);

-- Test 5: single entry group is allowed on ticket_templates
SELECT lives_ok(
  format(
    $$INSERT INTO public.ticket_templates (party_id, name, quantity, price, target_entry_group_ids)
      VALUES ('%s'::uuid, 'Group A Template', 5, 0, ARRAY['%s'::uuid])$$,
    current_setting('tests.tec_party_id'),
    current_setting('tests.tec_group_a_id')
  ),
  'ticket_templates_entry_group_single: single entry group is allowed'
);

-- Test 6: two entry group ids violates constraint on ticket_templates
SELECT throws_ok(
  format(
    $$INSERT INTO public.ticket_templates (party_id, name, quantity, price, target_entry_group_ids)
      VALUES ('%s'::uuid, 'Multi Group Template', 5, 0, ARRAY['%s'::uuid, '%s'::uuid])$$,
    current_setting('tests.tec_party_id'),
    current_setting('tests.tec_group_a_id'),
    current_setting('tests.tec_group_b_id')
  ),
  '23514',
  NULL,
  'ticket_templates_entry_group_single: two entry group ids violates constraint'
);

SELECT * FROM finish();
ROLLBACK;
