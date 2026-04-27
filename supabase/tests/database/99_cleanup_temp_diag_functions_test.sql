-- pgTAP test: verify temp diagnostic SECURITY DEFINER functions are removed
BEGIN;
SELECT plan(3);

SELECT ok(
  NOT EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = 'temp_auth_diag'
  ),
  'temp_auth_diag() should not exist'
);

SELECT ok(
  NOT EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = 'temp_auth_diag2'
  ),
  'temp_auth_diag2() should not exist'
);

SELECT ok(
  NOT EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = 'temp_compare_users'
  ),
  'temp_compare_users() should not exist'
);

SELECT * FROM finish();
ROLLBACK;
