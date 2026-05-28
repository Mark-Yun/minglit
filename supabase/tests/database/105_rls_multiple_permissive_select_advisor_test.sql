-- Issue #2798: Supabase Performance Advisor multiple_permissive_policies
-- regression for SELECT policy groups.
BEGIN;

SELECT plan(2);

CREATE TEMP TABLE affected_select_policy_tables (
  schemaname text NOT NULL,
  tablename text NOT NULL
) ON COMMIT DROP;

INSERT INTO affected_select_policy_tables (schemaname, tablename)
VALUES
  ('public', 'business_calendar'),
  ('public', 'entry_group_templates'),
  ('public', 'entry_groups'),
  ('public', 'event_applications'),
  ('public', 'events'),
  ('public', 'locations'),
  ('public', 'minglit_files'),
  ('public', 'parties'),
  ('public', 'partners'),
  ('public', 'party_tags'),
  ('public', 'policies'),
  ('public', 'social_interactions'),
  ('public', 'tag_usage_daily'),
  ('public', 'tag_usage_monthly'),
  ('public', 'ticket_templates'),
  ('public', 'tickets'),
  ('public', 'user_profiles'),
  ('public', 'verification_submissions'),
  ('public', 'verifications');

SELECT is_empty(
  $$
    SELECT a.*
    FROM affected_select_policy_tables a
    WHERE NOT EXISTS (
      SELECT 1
      FROM pg_policies p
      WHERE p.schemaname = a.schemaname
        AND p.tablename = a.tablename
        AND p.permissive = 'PERMISSIVE'
        AND p.cmd IN ('SELECT', 'ALL')
    )
  $$,
  'affected tables retain at least one permissive SELECT path'
);

SELECT is_empty(
  $$
    WITH expanded_select_policies AS (
      SELECT
        p.schemaname,
        p.tablename,
        p.policyname,
        r.role_name
      FROM pg_policies p
      JOIN affected_select_policy_tables a
        ON a.schemaname = p.schemaname
       AND a.tablename = p.tablename
      CROSS JOIN (VALUES
        ('anon'::name),
        ('authenticated'::name),
        ('service_role'::name)
      ) AS r(role_name)
      WHERE p.permissive = 'PERMISSIVE'
        AND p.cmd IN ('SELECT', 'ALL')
        AND (
          'public'::name = ANY(p.roles)
          OR r.role_name = ANY(p.roles)
        )
    )
    SELECT
      schemaname,
      tablename,
      role_name,
      array_agg(policyname ORDER BY policyname) AS policies
    FROM expanded_select_policies
    GROUP BY schemaname, tablename, role_name
    HAVING count(*) > 1
  $$,
  'affected tables do not have multiple permissive SELECT policies per role'
);

SELECT * FROM finish();
ROLLBACK;
