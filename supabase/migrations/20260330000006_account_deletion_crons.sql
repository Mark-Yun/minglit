-- Account deletion cron jobs:
-- 1. Process soft-deleted users after the 7-day grace period.
-- 2. Remove expired DI re-signup blocks.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM vault.decrypted_secrets WHERE name = 'service_role_key'
  ) THEN
    RAISE WARNING 'vault secret "service_role_key" not found — account deletion cron jobs will fail until it is configured';
  END IF;
END $$;

SELECT cron.unschedule(jobid)
FROM cron.job
WHERE jobname IN ('process-pending-deletions', 'cleanup-blocked-dis');

-- Process pending deletions: daily 09:00 KST (00:00 UTC)
SELECT cron.schedule(
  'process-pending-deletions',
  '0 0 * * *',
  $$
    SELECT net.http_post(
      url := (
        SELECT decrypted_secret FROM vault.decrypted_secrets
        WHERE name = 'supabase_url' LIMIT 1
      ) || '/functions/v1/process-pending-deletions',
      headers := (
        jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || (
            SELECT decrypted_secret FROM vault.decrypted_secrets
            WHERE name = 'service_role_key' LIMIT 1
          )
        )
      ),
      body := '{}'::jsonb
    ) AS request_id;
  $$
);

-- Cleanup blocked DI rows: daily 10:00 KST (01:00 UTC)
SELECT cron.schedule(
  'cleanup-blocked-dis',
  '0 1 * * *',
  $$
    SELECT net.http_post(
      url := (
        SELECT decrypted_secret FROM vault.decrypted_secrets
        WHERE name = 'supabase_url' LIMIT 1
      ) || '/functions/v1/cleanup-blocked-dis',
      headers := (
        jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || (
            SELECT decrypted_secret FROM vault.decrypted_secrets
            WHERE name = 'service_role_key' LIMIT 1
          )
        )
      ),
      body := '{}'::jsonb
    ) AS request_id;
  $$
);
