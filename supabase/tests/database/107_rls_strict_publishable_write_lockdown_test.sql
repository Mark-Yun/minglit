-- Issue #2991: publishable-key roles are read-only for public app tables.
BEGIN;

SELECT plan(7);

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

SELECT is_empty(
  $$
    WITH write_security_definer_functions AS (
      SELECT
        p.oid,
        n.nspname AS schema_name,
        p.proname AS function_name,
        pg_get_function_identity_arguments(p.oid) AS identity_arguments
      FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
      WHERE n.nspname = 'public'
        AND p.prokind = 'f'
        AND p.prosecdef
        AND p.prosrc ~* (
          '(^|[^[:alnum:]_])(' ||
          'insert[[:space:]]+into|' ||
          'update[[:space:]]+[[:alnum:]_".]+[[:space:]]+set|' ||
          'delete[[:space:]]+from|' ||
          'truncate[[:space:]]+table|' ||
          'merge[[:space:]]+into' ||
          ')'
        )
    ),
    publishable_roles AS (
      SELECT unnest(ARRAY['anon', 'authenticated']) AS role_name
    )
    SELECT
      pr.role_name,
      format(
        '%I.%I(%s)',
        wsdf.schema_name,
        wsdf.function_name,
        wsdf.identity_arguments
      ) AS function_signature
    FROM write_security_definer_functions wsdf
    CROSS JOIN publishable_roles pr
    WHERE has_function_privilege(pr.role_name, wsdf.oid, 'EXECUTE')
    ORDER BY pr.role_name, function_signature
  $$,
  'anon/authenticated cannot execute write-capable SECURITY DEFINER RPCs'
);

SELECT is_empty(
  $$
    WITH reviewed_functions(function_signature) AS (
      VALUES
        ('public.save_user_consents(uuid, jsonb)'),
        ('public.process_qr_checkin(uuid, uuid, uuid)'),
        ('public.process_manual_checkin(uuid, uuid)'),
        ('public.request_retry_payout(uuid, uuid)'),
        ('public.set_social_interaction(text, text, text, boolean)'),
        ('public.create_party_with_tags(jsonb, uuid[])'),
        ('public.update_party_tags(uuid, uuid[])'),
        ('public.upsert_user_interest_tags(uuid[])')
    )
    SELECT function_signature
    FROM reviewed_functions
    WHERE NOT has_function_privilege(
      'service_role',
      function_signature,
      'EXECUTE'
    )
    ORDER BY function_signature
  $$,
  'service_role keeps EXECUTE on reviewed write RPCs'
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
