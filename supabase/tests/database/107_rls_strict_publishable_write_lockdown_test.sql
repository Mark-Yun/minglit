-- Issue #2991: publishable-key roles are read-only for public app tables.
BEGIN;

SELECT plan(5);

SELECT is_empty(
  $$
    WITH app_public_relations AS (
      SELECT c.relname
      FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
      JOIN pg_roles owner_role ON owner_role.oid = c.relowner
      WHERE n.nspname = 'public'
        AND c.relkind IN ('r', 'p', 'v', 'm')
        AND owner_role.rolname = 'postgres'
    )
    SELECT
      tp.grantee,
      tp.table_schema,
      tp.table_name,
      tp.privilege_type
    FROM information_schema.table_privileges tp
    JOIN app_public_relations apr ON apr.relname = tp.table_name
    WHERE tp.table_schema = 'public'
      AND tp.grantee IN ('anon', 'authenticated')
      AND tp.privilege_type IN ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE')
    ORDER BY tp.grantee, tp.table_name, tp.privilege_type
  $$,
  'anon/authenticated have no direct write grants on public app relations'
);

SELECT is_empty(
  $$
    SELECT schemaname, tablename, policyname, cmd, roles
    FROM pg_policies
    WHERE schemaname = 'public'
      AND cmd IN ('INSERT', 'UPDATE', 'DELETE', 'ALL')
      AND roles && ARRAY['public', 'anon', 'authenticated']::name[]
    ORDER BY tablename, policyname
  $$,
  'public schema has no public/anon/authenticated write-capable RLS policies'
);

SET LOCAL ROLE authenticated;
SELECT throws_ok(
  $$INSERT INTO public.tags (name, is_featured)
    VALUES ('rls_strict_authenticated_write_denied', false)$$,
  '42501',
  NULL,
  'authenticated direct table write is denied before RLS policy evaluation'
);
RESET ROLE;

SET LOCAL ROLE anon;
SELECT throws_ok(
  $$INSERT INTO public.tags (name, is_featured)
    VALUES ('rls_strict_anon_write_denied', false)$$,
  '42501',
  NULL,
  'anon direct table write is denied before RLS policy evaluation'
);
RESET ROLE;

SET LOCAL ROLE service_role;
SELECT lives_ok(
  $$INSERT INTO public.tags (name, is_featured)
    VALUES ('rls_strict_service_role_write_allowed', false)$$,
  'service_role keeps direct DB writes for Edge Function execution'
);
RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
