-- DB State Snapshot Report
-- Outputs current database state in Markdown format
-- Usage: supabase db execute --project-ref $REF --password $PW --sql "$(cat scripts/db-snapshot.sql)"

SELECT string_agg(line, E'\n') FROM (

  -- Tables + Column count + RLS policy count
  SELECT 1 AS section, 0 AS ord,
    format(E'## Tables (%s)\n| Table | Columns | RLS |', count(*)) AS line
  FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE'

  UNION ALL

  SELECT 1, 1, '|-------|---------|-----|'

  UNION ALL

  SELECT 1, row_number() OVER (ORDER BY t.table_name) + 1,
    format('| %s | %s | %s |',
      t.table_name,
      (SELECT count(*) FROM information_schema.columns c
       WHERE c.table_schema = 'public' AND c.table_name = t.table_name),
      COALESCE(
        (SELECT format('✅ %s policies', count(*))
         FROM pg_policies p WHERE p.schemaname = 'public' AND p.tablename = t.table_name
         HAVING count(*) > 0),
        '❌ none'
      )
    )
  FROM information_schema.tables t
  WHERE t.table_schema = 'public' AND t.table_type = 'BASE TABLE'

  UNION ALL

  -- Cron Jobs
  SELECT 2, 0,
    format(E'\n## Cron Jobs (%s)\n| Name | Schedule | Command (truncated) |', count(*))
  FROM cron.job

  UNION ALL

  SELECT 2, 1, '|------|----------|---------------------|'

  UNION ALL

  SELECT 2, row_number() OVER (ORDER BY jobname) + 1,
    format('| %s | `%s` | %s |',
      jobname,
      schedule,
      left(regexp_replace(command, E'[\\n\\r\\t]+', ' ', 'g'), 80)
    )
  FROM cron.job

  UNION ALL

  -- RLS Policies
  SELECT 3, 0,
    format(E'\n## RLS Policies (%s)\n| Table | Policy | Command | Roles |', count(*))
  FROM pg_policies WHERE schemaname = 'public'

  UNION ALL

  SELECT 3, 1, '|-------|--------|---------|-------|'

  UNION ALL

  SELECT 3, row_number() OVER (ORDER BY tablename, policyname) + 1,
    format('| %s | %s | %s | %s |',
      tablename, policyname, cmd,
      array_to_string(roles, ', ')
    )
  FROM pg_policies WHERE schemaname = 'public'

  UNION ALL

  -- Triggers
  SELECT 4, 0,
    format(E'\n## Triggers (%s)\n| Trigger | Table | Event |', count(*))
  FROM information_schema.triggers WHERE trigger_schema = 'public'

  UNION ALL

  SELECT 4, 1, '|---------|-------|-------|'

  UNION ALL

  SELECT 4, row_number() OVER (ORDER BY event_object_table, trigger_name) + 1,
    format('| %s | %s | %s %s |',
      trigger_name,
      event_object_table,
      action_timing,
      event_manipulation
    )
  FROM information_schema.triggers WHERE trigger_schema = 'public'

  UNION ALL

  -- RPC Functions
  SELECT 5, 0,
    format(E'\n## RPC Functions (%s)\n| Name | Args | Returns |', count(*))
  FROM pg_proc p
  JOIN pg_namespace n ON p.pronamespace = n.oid
  WHERE n.nspname = 'public' AND p.prokind = 'f'

  UNION ALL

  SELECT 5, 1, '|------|------|---------|'

  UNION ALL

  SELECT 5, row_number() OVER (ORDER BY p.proname) + 1,
    format('| %s | %s | %s |',
      p.proname,
      p.pronargs,
      pg_catalog.format_type(p.prorettype, NULL)
    )
  FROM pg_proc p
  JOIN pg_namespace n ON p.pronamespace = n.oid
  WHERE n.nspname = 'public' AND p.prokind = 'f'

  UNION ALL

  -- Indexes
  SELECT 6, 0,
    format(E'\n## Indexes (%s)\n| Index | Table | Definition |', count(*))
  FROM pg_indexes WHERE schemaname = 'public'

  UNION ALL

  SELECT 6, 1, '|-------|-------|------------|'

  UNION ALL

  SELECT 6, row_number() OVER (ORDER BY tablename, indexname) + 1,
    format('| %s | %s | %s |',
      indexname,
      tablename,
      left(indexdef, 120)
    )
  FROM pg_indexes WHERE schemaname = 'public'

  UNION ALL

  -- Extensions
  SELECT 7, 0, E'\n## Extensions'

  UNION ALL

  SELECT 7, 1,
    string_agg(extname, ', ' ORDER BY extname)
  FROM pg_extension

  UNION ALL

  -- Enum Types
  SELECT 8, 0,
    format(E'\n## Enum Types (%s)\n| Name | Values |', count(DISTINCT t.typname))
  FROM pg_type t
  JOIN pg_namespace n ON t.typnamespace = n.oid
  WHERE t.typtype = 'e' AND n.nspname = 'public'

  UNION ALL

  SELECT 8, 1, '|------|--------|'

  UNION ALL

  SELECT 8, row_number() OVER (ORDER BY t.typname) + 1,
    format('| %s | %s |',
      t.typname,
      string_agg(e.enumlabel, ', ' ORDER BY e.enumsortorder)
    )
  FROM pg_type t
  JOIN pg_namespace n ON t.typnamespace = n.oid
  JOIN pg_enum e ON e.enumtypid = t.oid
  WHERE t.typtype = 'e' AND n.nspname = 'public'
  GROUP BY t.typname

  UNION ALL

  -- Migration Count
  SELECT 9, 0, E'\n## Migration Count'

  UNION ALL

  SELECT 9, 1,
    format('Applied: %s', count(*))
  FROM supabase_migrations.schema_migrations

  ORDER BY section, ord
) sub;
