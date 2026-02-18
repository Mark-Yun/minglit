BEGIN;
SELECT plan(7);

SELECT tests.create_supabase_user('user_a', 'a@test.com');
SELECT tests.create_supabase_user('user_b', 'b@test.com');

SELECT tests.authenticate_as_service_role();
UPDATE public.user_profiles
  SET name = 'User A'
  WHERE id = tests.get_supabase_uid('user_a');
UPDATE public.user_profiles
  SET name = 'User B'
  WHERE id = tests.get_supabase_uid('user_b');

SELECT tests.clear_authentication();
SELECT is_empty(
  $$UPDATE public.user_profiles
      SET name = 'Anon Update'
      WHERE id = tests.get_supabase_uid('user_a')
      RETURNING id$$,
  'anon cannot update user profiles'
);

SELECT tests.authenticate_as('user_a');
SELECT results_eq(
  $$SELECT count(*)::int
    FROM public.user_profiles
    WHERE id = tests.get_supabase_uid('user_a')$$,
  $$VALUES (1)$$,
  'users can read own profile'
);
SELECT results_eq(
  $$SELECT count(*)::int
    FROM public.user_profiles
    WHERE id = tests.get_supabase_uid('user_b')$$,
  $$VALUES (1)$$,
  'profiles are publicly readable'
);

SELECT lives_ok(
  $$UPDATE public.user_profiles
      SET name = 'Updated User A'
      WHERE id = tests.get_supabase_uid('user_a')$$,
  'user can update own profile'
);
SELECT results_eq(
  $$SELECT name
    FROM public.user_profiles
    WHERE id = tests.get_supabase_uid('user_a')$$,
  $$VALUES ('Updated User A')$$,
  'own profile update persists'
);

SELECT tests.authenticate_as('user_b');
SELECT is_empty(
  $$UPDATE public.user_profiles
      SET name = 'Hacked'
      WHERE id = tests.get_supabase_uid('user_a')
      RETURNING id$$,
  'users cannot update other profiles'
);
SELECT results_eq(
  $$SELECT name
    FROM public.user_profiles
    WHERE id = tests.get_supabase_uid('user_a')$$,
  $$VALUES ('Updated User A')$$,
  'other users cannot change profiles'
);

SELECT * FROM finish();
ROLLBACK;
