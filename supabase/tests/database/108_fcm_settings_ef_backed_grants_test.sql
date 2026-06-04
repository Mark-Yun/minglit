BEGIN;

SELECT plan(6);

SELECT is_empty(
  $$
  SELECT table_name, privilege_type
  FROM information_schema.role_table_grants
  WHERE table_schema = 'public'
    AND table_name IN ('fcm_tokens', 'user_settings')
    AND grantee = 'anon'
  ORDER BY table_name, privilege_type
  $$,
  'anon has no direct grants on EF-backed notification settings tables'
);

SELECT is_empty(
  $$
  SELECT table_name, privilege_type
  FROM information_schema.role_table_grants
  WHERE table_schema = 'public'
    AND table_name IN ('fcm_tokens', 'user_settings')
    AND grantee = 'authenticated'
    AND privilege_type <> 'SELECT'
  ORDER BY table_name, privilege_type
  $$,
  'authenticated can only SELECT EF-backed notification settings tables'
);

SELECT is(
  (
    SELECT count(*)::int
    FROM information_schema.role_table_grants
    WHERE table_schema = 'public'
      AND table_name IN ('fcm_tokens', 'user_settings')
      AND grantee = 'authenticated'
      AND privilege_type = 'SELECT'
  ),
  2,
  'authenticated keeps SELECT on fcm_tokens and user_settings'
);

SELECT is_empty(
  $$
  SELECT tablename, policyname, cmd, roles::text
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename IN ('fcm_tokens', 'user_settings')
    AND (cmd <> 'SELECT' OR roles <> ARRAY['authenticated']::name[])
  ORDER BY tablename, policyname
  $$,
  'fcm_tokens and user_settings policies are authenticated SELECT-only'
);

SELECT is_empty(
  $$
  SELECT tablename, policyname, cmd, roles::text
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename IN ('fcm_tokens', 'user_settings')
    AND cmd IN ('INSERT', 'UPDATE', 'DELETE', 'ALL')
    AND roles && ARRAY['public', 'anon', 'authenticated']::name[]
  ORDER BY tablename, policyname
  $$,
  'publishable roles have no write-capable fcm/user_settings policies'
);

SELECT is(
  (
    SELECT count(*)::int
    FROM information_schema.role_table_grants
    WHERE table_schema = 'public'
      AND table_name IN ('fcm_tokens', 'user_settings')
      AND grantee = 'service_role'
      AND privilege_type IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE')
  ),
  8,
  'service_role remains the EF write path for fcm_tokens and user_settings'
);

SELECT * FROM finish();

ROLLBACK;
