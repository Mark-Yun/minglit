-- Idempotent unschedule + reschedule
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'cleanup-retention') THEN
    PERFORM cron.unschedule('cleanup-retention');
  END IF;
END $$;

SELECT cron.schedule(
  'cleanup-retention',
  '0 3 * * *',  -- daily 03:00 UTC (KST 12:00)
  $$
    SELECT net.http_post(
      url := (
        SELECT decrypted_secret FROM vault.decrypted_secrets
        WHERE name = 'supabase_url' LIMIT 1
      ) || '/functions/v1/cleanup-retention',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || (
          SELECT decrypted_secret FROM vault.decrypted_secrets
          WHERE name = 'publishable_key' LIMIT 1
        )
      ),
      body := '{}'::jsonb
    );
  $$
);
