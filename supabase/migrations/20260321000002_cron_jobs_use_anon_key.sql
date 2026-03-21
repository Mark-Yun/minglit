-- Replace service_role_key with anon_key in vault for all cron jobs
-- service_role_key was removed (legacy), anon_key is the official recommended approach
-- See: https://supabase.com/docs/guides/functions/schedule-functions

-- 1. Store anon_key in vault (if not exists)
-- NOTE: Run this in SQL Editor first if vault doesn't have anon_key yet:
--   SELECT vault.create_secret('<YOUR_ANON_KEY>', 'anon_key', 'Anon key for EF cron calls');
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM vault.decrypted_secrets WHERE name = 'anon_key'
  ) THEN
    RAISE WARNING 'vault secret "anon_key" not found — cron jobs will fail until it is created manually';
  END IF;
END $$;

-- 2. Recreate backend-simulation cron job with anon_key
SELECT cron.unschedule('backend-simulation');
SELECT cron.schedule(
  'backend-simulation',
  '0 * * * *',
  $$
    SELECT net.http_post(
      url := (
        SELECT decrypted_secret FROM vault.decrypted_secrets
        WHERE name = 'supabase_url' LIMIT 1
      ) || '/functions/v1/backend-simulator',
      headers := (
        jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || (
            SELECT decrypted_secret FROM vault.decrypted_secrets
            WHERE name = 'anon_key' LIMIT 1
          )
        )
      ),
      body := '{}'::jsonb
    ) AS request_id;
  $$
);

-- 3. Recreate process-notifications cron job with anon_key
SELECT cron.unschedule('process-notifications');
SELECT cron.schedule(
  'process-notifications',
  '* * * * *',
  $$
    SELECT net.http_post(
      url := (
        SELECT decrypted_secret FROM vault.decrypted_secrets
        WHERE name = 'supabase_url' LIMIT 1
      ) || '/functions/v1/notification-worker',
      headers := (
        jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || (
            SELECT decrypted_secret FROM vault.decrypted_secrets
            WHERE name = 'anon_key' LIMIT 1
          )
        )
      ),
      body := '{}'::jsonb
    ) AS request_id;
  $$
);

-- 4. Recreate settlement-reconciliation-daily with anon_key
SELECT cron.unschedule('settlement-reconciliation-daily');
SELECT cron.schedule(
  'settlement-reconciliation-daily',
  '0 13 * * *',
  $$
    SELECT net.http_post(
      url := (
        SELECT decrypted_secret FROM vault.decrypted_secrets
        WHERE name = 'supabase_url' LIMIT 1
      ) || '/functions/v1/reconciliation-daily',
      headers := (
        jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || (
            SELECT decrypted_secret FROM vault.decrypted_secrets
            WHERE name = 'anon_key' LIMIT 1
          )
        )
      ),
      body := '{}'::jsonb
    ) AS request_id;
  $$
);

-- 5. Recreate settlement-register-transfers with anon_key
SELECT cron.unschedule('settlement-register-transfers');
SELECT cron.schedule(
  'settlement-register-transfers',
  '*/15 * * * *',
  $$
    SELECT net.http_post(
      url := (
        SELECT decrypted_secret FROM vault.decrypted_secrets
        WHERE name = 'supabase_url' LIMIT 1
      ) || '/functions/v1/settlement-register-transfers',
      headers := (
        jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || (
            SELECT decrypted_secret FROM vault.decrypted_secrets
            WHERE name = 'anon_key' LIMIT 1
          )
        )
      ),
      body := '{}'::jsonb
    ) AS request_id;
  $$
);

-- 6. Recreate settlement-payout-sync with anon_key
SELECT cron.unschedule('settlement-payout-sync');
SELECT cron.schedule(
  'settlement-payout-sync',
  '0 2,5,8 * * *',
  $$
    SELECT net.http_post(
      url := (
        SELECT decrypted_secret FROM vault.decrypted_secrets
        WHERE name = 'supabase_url' LIMIT 1
      ) || '/functions/v1/payout-sync',
      headers := (
        jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || (
            SELECT decrypted_secret FROM vault.decrypted_secrets
            WHERE name = 'anon_key' LIMIT 1
          )
        )
      ),
      body := '{}'::jsonb
    ) AS request_id;
  $$
);

-- 7. Recreate settlement-alarm-check with anon_key
SELECT cron.unschedule('settlement-alarm-check');
SELECT cron.schedule(
  'settlement-alarm-check',
  '*/30 * * * *',
  $$
    SELECT net.http_post(
      url := (
        SELECT decrypted_secret FROM vault.decrypted_secrets
        WHERE name = 'supabase_url' LIMIT 1
      ) || '/functions/v1/metrics-alert',
      headers := (
        jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || (
            SELECT decrypted_secret FROM vault.decrypted_secrets
            WHERE name = 'anon_key' LIMIT 1
          )
        )
      ),
      body := '{}'::jsonb
    ) AS request_id;
  $$
);
