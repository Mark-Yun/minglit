BEGIN;
SELECT no_plan();

-- ============================================================
-- 1. Schema — table existence + columns + constraints + RLS
-- ============================================================
SELECT has_table('public', 'user_consents', 'user_consents table exists');
SELECT col_is_pk('public', 'user_consents', 'id', 'user_consents.id is primary key');
SELECT col_type_is('public', 'user_consents', 'id', 'uuid', 'user_consents.id is uuid');
SELECT col_type_is('public', 'user_consents', 'user_id', 'uuid', 'user_consents.user_id is uuid');
SELECT col_type_is('public', 'user_consents', 'consent_key', 'text', 'user_consents.consent_key is text');
SELECT col_type_is('public', 'user_consents', 'consented', 'boolean', 'user_consents.consented is boolean');
SELECT col_type_is('public', 'user_consents', 'policy_version', 'integer', 'user_consents.policy_version is integer');
SELECT col_type_is('public', 'user_consents', 'consented_at', 'timestamp with time zone', 'user_consents.consented_at is timestamptz');
SELECT col_type_is('public', 'user_consents', 'withdrawn_at', 'timestamp with time zone', 'user_consents.withdrawn_at is timestamptz');
SELECT col_type_is('public', 'user_consents', 'created_at', 'timestamp with time zone', 'user_consents.created_at is timestamptz');
SELECT col_not_null('public', 'user_consents', 'user_id', 'user_id is NOT NULL');
SELECT col_not_null('public', 'user_consents', 'consent_key', 'consent_key is NOT NULL');
SELECT col_not_null('public', 'user_consents', 'consented', 'consented is NOT NULL');
SELECT has_index('public', 'user_consents', 'idx_user_consents_user_id', 'idx_user_consents_user_id exists');
SELECT has_index('public', 'user_consents', 'user_consents_user_key_unique', 'UNIQUE(user_id, consent_key) constraint exists');
SELECT tests.rls_enabled('public', 'user_consents');

-- ============================================================
-- 2. Function existence
-- ============================================================
SELECT has_function('public', 'has_required_consents', 'has_required_consents function exists');

-- ============================================================
-- 3. Policies seed — consent policy documents inserted
-- ============================================================
SELECT tests.authenticate_as_service_role();

SELECT results_eq(
  $$SELECT count(*)::int FROM public.policies WHERE key IN ('terms_of_service', 'privacy_collection', 'third_party_provision', 'marketing_consent')$$,
  $$VALUES (4)$$,
  'All 4 consent policy seed rows exist'
);

-- ============================================================
-- 4. RLS — anon cannot access user_consents
-- ============================================================
SELECT tests.clear_authentication();

SELECT is_empty(
  $$SELECT * FROM public.user_consents$$,
  'anon cannot SELECT user_consents'
);

-- ============================================================
-- 5. RLS — authenticated user can INSERT own consents
-- ============================================================
SELECT tests.create_supabase_user('consent_user_a', 'consent_a@test.com');
SELECT tests.create_supabase_user('consent_user_b', 'consent_b@test.com');

SELECT tests.authenticate_as('consent_user_a');

-- Insert consent for user A
SELECT lives_ok(
  format(
    $$INSERT INTO public.user_consents (user_id, consent_key, consented, policy_version)
      VALUES ('%s', 'terms_of_service', true, 1)$$,
    tests.get_supabase_uid('consent_user_a')
  ),
  'authenticated user can INSERT own consent'
);

SELECT lives_ok(
  format(
    $$INSERT INTO public.user_consents (user_id, consent_key, consented, policy_version)
      VALUES ('%s', 'privacy_collection', true, 1)$$,
    tests.get_supabase_uid('consent_user_a')
  ),
  'authenticated user can INSERT second consent'
);

SELECT lives_ok(
  format(
    $$INSERT INTO public.user_consents (user_id, consent_key, consented)
      VALUES ('%s', 'age_confirmation', true)$$,
    tests.get_supabase_uid('consent_user_a')
  ),
  'authenticated user can INSERT age_confirmation (no policy_version)'
);

-- ============================================================
-- 6. RLS — user can SELECT only own consents
-- ============================================================
SELECT results_eq(
  $$SELECT count(*)::int FROM public.user_consents$$,
  $$VALUES (3)$$,
  'user A sees only own 3 consents'
);

-- ============================================================
-- 7. RLS — user cannot INSERT consent for another user
-- ============================================================
SAVEPOINT before_cross_insert;
SELECT throws_ok(
  format(
    $$INSERT INTO public.user_consents (user_id, consent_key, consented)
      VALUES ('%s', 'terms_of_service', true)$$,
    tests.get_supabase_uid('consent_user_b')
  ),
  NULL,
  NULL,
  'user A cannot INSERT consent for user B'
);
ROLLBACK TO SAVEPOINT before_cross_insert;

-- ============================================================
-- 8. RLS — user can UPDATE own consents
-- ============================================================
SELECT lives_ok(
  format(
    $$UPDATE public.user_consents SET consented = false, withdrawn_at = now()
      WHERE user_id = '%s' AND consent_key = 'terms_of_service'$$,
    tests.get_supabase_uid('consent_user_a')
  ),
  'user A can UPDATE own consent'
);

-- ============================================================
-- 9. UNIQUE constraint — duplicate (user_id, consent_key) fails
-- ============================================================
SAVEPOINT before_dup;
SELECT throws_ok(
  format(
    $$INSERT INTO public.user_consents (user_id, consent_key, consented)
      VALUES ('%s', 'privacy_collection', true)$$,
    tests.get_supabase_uid('consent_user_a')
  ),
  '23505',
  NULL,
  'duplicate (user_id, consent_key) violates unique constraint'
);
ROLLBACK TO SAVEPOINT before_dup;

-- ============================================================
-- 10. has_required_consents() — returns false when incomplete
-- ============================================================
-- User A withdrew terms_of_service in step 8, so missing required consent
SELECT results_eq(
  $$SELECT public.has_required_consents()$$,
  $$VALUES (false)$$,
  'has_required_consents returns false when terms_of_service is withdrawn'
);

-- Restore terms_of_service
SELECT lives_ok(
  format(
    $$UPDATE public.user_consents SET consented = true, withdrawn_at = NULL
      WHERE user_id = '%s' AND consent_key = 'terms_of_service'$$,
    tests.get_supabase_uid('consent_user_a')
  ),
  'restore terms_of_service consent'
);

-- ============================================================
-- 11. has_required_consents() — returns true when all 3 required
-- ============================================================
SELECT results_eq(
  $$SELECT public.has_required_consents()$$,
  $$VALUES (true)$$,
  'has_required_consents returns true when all 3 required consents present'
);

-- ============================================================
-- 12. has_required_consents() — returns false for user with no consents
-- ============================================================
SELECT tests.authenticate_as('consent_user_b');

SELECT results_eq(
  $$SELECT public.has_required_consents()$$,
  $$VALUES (false)$$,
  'has_required_consents returns false for user with no consents'
);

-- ============================================================
-- 13. User B cannot see User A's consents
-- ============================================================
SELECT is_empty(
  $$SELECT * FROM public.user_consents$$,
  'user B cannot see user A consents'
);

-- ============================================================
-- 14. service_role has full access
-- ============================================================
SELECT tests.authenticate_as_service_role();

SELECT results_eq(
  $$SELECT count(*)::int FROM public.user_consents$$,
  $$VALUES (3)$$,
  'service_role can see all consents'
);

SELECT * FROM finish();
ROLLBACK;
