BEGIN;
SELECT plan(6);

SELECT tests.create_supabase_user('user_a', 'sa@test.com');
SELECT tests.create_supabase_user('user_b', 'sb@test.com');

SELECT tests.authenticate_as_service_role();

-- Insert a social interaction for user_a
INSERT INTO public.social_interactions (user_id, target_id, target_type, interaction_type)
VALUES (
  tests.get_supabase_uid('user_a'),
  gen_random_uuid(),
  'party',
  'like'
);

-- Test 1: RLS is enabled
SELECT tests.rls_enabled('public', 'social_interactions');

-- Test 2: anon cannot read
SELECT tests.clear_authentication();
SELECT is_empty(
  $$SELECT user_id FROM public.social_interactions
    WHERE user_id = tests.get_supabase_uid('user_a')$$,
  'anon cannot read social interactions'
);

-- Test 3: user_a can read own interactions
SELECT tests.authenticate_as('user_a');
SELECT results_eq(
  $$SELECT count(*)::int FROM public.social_interactions
    WHERE user_id = tests.get_supabase_uid('user_a')$$,
  $$VALUES (1)$$,
  'user can read own social interactions'
);

-- Test 4: user_b cannot read user_a's interactions
SELECT tests.authenticate_as('user_b');
SELECT is_empty(
  $$SELECT user_id FROM public.social_interactions
    WHERE user_id = tests.get_supabase_uid('user_a')$$,
  'user cannot read other users social interactions'
);

-- Test 5: user_a can insert own interaction
SELECT tests.authenticate_as('user_a');
SELECT lives_ok(
  $$INSERT INTO public.social_interactions (user_id, target_id, target_type, interaction_type)
    VALUES (
      tests.get_supabase_uid('user_a'),
      gen_random_uuid(),
      'party',
      'bookmark'
    )$$,
  'user can insert own social interaction'
);

-- Test 6: anon cannot insert interaction (throws permission denied)
SELECT tests.clear_authentication();
SELECT throws_ok(
  $$INSERT INTO public.social_interactions (user_id, target_id, target_type, interaction_type)
    VALUES (
      tests.get_supabase_uid('user_a'),
      gen_random_uuid(),
      'party',
      'subscribe'
    )$$,
  '42501',
  null,
  'anon cannot insert social interaction'
);

SELECT * FROM finish();
ROLLBACK;
