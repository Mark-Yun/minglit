BEGIN;
SELECT plan(6);

SELECT tests.create_supabase_user('user_a', 'a@test.com');
SELECT tests.create_supabase_user('user_b', 'b@test.com');

SELECT tests.authenticate_as_service_role();

WITH partner AS (
  INSERT INTO public.partners (name, introduction)
  VALUES ('Partner A', 'Intro A')
  RETURNING id
)
SELECT set_config('tests.partner_id', id::text, true) FROM partner;

INSERT INTO public.partner_member_permissions (partner_id, user_id, role)
VALUES (current_setting('tests.partner_id')::uuid, tests.get_supabase_uid('user_a'), 'owner');

SELECT tests.clear_authentication();
SELECT results_eq(
  $$SELECT count(*)::int
    FROM public.partners
    WHERE id = current_setting('tests.partner_id')::uuid$$,
  $$VALUES (1)$$,
  'partners are publicly readable'
);
SELECT is_empty(
  $$UPDATE public.partners
      SET introduction = 'Anon Update'
      WHERE id = current_setting('tests.partner_id')::uuid
      RETURNING id$$,
  'anon cannot update partner data'
);

SELECT tests.authenticate_as('user_a');
SELECT lives_ok(
  $$UPDATE public.partners
      SET introduction = 'Owner Update'
      WHERE id = current_setting('tests.partner_id')::uuid$$,
  'owner can update partner data'
);
SELECT results_eq(
  $$SELECT introduction
    FROM public.partners
    WHERE id = current_setting('tests.partner_id')::uuid$$,
  $$VALUES ('Owner Update')$$,
  'owner update persists'
);

SELECT tests.authenticate_as('user_b');
SELECT is_empty(
  $$UPDATE public.partners
      SET introduction = 'Hacked'
      WHERE id = current_setting('tests.partner_id')::uuid
      RETURNING id$$,
  'other users cannot update partner data'
);
SELECT results_eq(
  $$SELECT introduction
    FROM public.partners
    WHERE id = current_setting('tests.partner_id')::uuid$$,
  $$VALUES ('Owner Update')$$,
  'cross-user updates are blocked'
);

SELECT * FROM finish();
ROLLBACK;
