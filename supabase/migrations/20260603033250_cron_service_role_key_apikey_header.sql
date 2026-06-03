-- Fix #2187: pg_cron -> Edge Function system auth must be compatible with
-- both legacy service_role JWT and new sb_secret_ secret API keys.
--
-- Legacy JWT path:
--   Authorization: Bearer <service_role_key>
--
-- New secret key path:
--   apikey: <service_role_key>
--
-- The Vault secret name remains service_role_key so existing deploy sync and
-- tests keep one source of truth. If the value is legacy JWT, bearer auth wins.
-- If the value is sb_secret_..., the wrapper rejects bearer and accepts apikey.

DO $$
DECLARE
  cron_target record;
  command_sql text;
BEGIN
  FOR cron_target IN
    SELECT *
    FROM (VALUES
      ('process-notifications', 'notification-worker', '* * * * *'),
      ('settlement-reconciliation-daily', 'reconciliation-daily', '0 13 * * *'),
      ('settlement-register-transfers', 'settlement-register-transfers', '*/15 * * * *'),
      ('settlement-payout-sync', 'payout-sync', '0 2,5,8 * * *'),
      ('settlement-alarm-check', 'metrics-alert', '*/30 * * * *'),
      ('sync_github_stats', 'github-stats-sync', '30 20 * * *'),
      ('ai-extract-tags', 'ai-extract-tags', '* * * * *'),
      ('process-pending-deletions', 'process-pending-deletions', '0 0 * * *'),
      ('cleanup-blocked-dis', 'cleanup-blocked-dis', '0 1 * * *'),
      ('cleanup-retention', 'cleanup-retention', '0 3 * * *'),
      ('recurrence-cron-daily', 'recurrence-cron', '0 0 * * *')
    ) AS jobs(jobname, function_name, cron_expr)
  LOOP
    IF EXISTS (
      SELECT 1 FROM cron.job AS cj WHERE cj.jobname = cron_target.jobname
    ) THEN
      PERFORM cron.unschedule(cron_target.jobname);
    END IF;

    command_sql := format(
      $command$
        SELECT net.http_post(
          url := (
            SELECT decrypted_secret FROM vault.decrypted_secrets
            WHERE name = 'supabase_url' LIMIT 1
          ) || '/functions/v1/%s',
          headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'apikey', (
              SELECT decrypted_secret FROM vault.decrypted_secrets
              WHERE name = 'service_role_key' LIMIT 1
            ),
            'Authorization', 'Bearer ' || (
              SELECT decrypted_secret FROM vault.decrypted_secrets
              WHERE name = 'service_role_key' LIMIT 1
            )
          ),
          body := '{}'::jsonb
        ) AS request_id;
      $command$,
      cron_target.function_name
    );

    PERFORM cron.schedule(
      cron_target.jobname,
      cron_target.cron_expr,
      command_sql
    );
  END LOOP;
END $$;

-- analytics.call_metrics_alert is not stored in cron.job.command; it is called
-- by analytics cron functions and then invokes the system-only metrics-alert EF.
-- Keep it compatible with both legacy service_role JWT and sb_secret_ keys too.
CREATE OR REPLACE FUNCTION analytics.call_metrics_alert(
  p_type TEXT,
  p_title TEXT,
  p_body TEXT
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_service_role_key TEXT;
  v_supabase_url TEXT;
BEGIN
  SELECT decrypted_secret INTO v_service_role_key
  FROM vault.decrypted_secrets
  WHERE name = 'service_role_key'
  LIMIT 1;

  SELECT decrypted_secret INTO v_supabase_url
  FROM vault.decrypted_secrets
  WHERE name = 'supabase_url'
  LIMIT 1;

  IF v_supabase_url IS NULL OR v_service_role_key IS NULL THEN
    RAISE WARNING 'call_metrics_alert: vault secret missing (supabase_url=%, service_role_key=%)',
      v_supabase_url IS NOT NULL, v_service_role_key IS NOT NULL;
    RETURN;
  END IF;

  PERFORM net.http_post(
    url := v_supabase_url || '/functions/v1/metrics-alert',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'apikey', v_service_role_key,
      'Authorization', 'Bearer ' || v_service_role_key
    ),
    body := jsonb_build_object(
      'type', p_type,
      'title', p_title,
      'body', p_body
    )
  );
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'analytics.call_metrics_alert failed: [%] %', SQLSTATE, SQLERRM;
END;
$$;

REVOKE EXECUTE ON FUNCTION analytics.call_metrics_alert(TEXT, TEXT, TEXT)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION analytics.call_metrics_alert(TEXT, TEXT, TEXT)
  TO service_role;
