-- Recreate e2e-simulation cron job using vault-stored supabase_url
-- Fixes: hardcoded project URL breaks if migration runs on a different Supabase project

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM vault.decrypted_secrets WHERE name = 'supabase_url'
  ) THEN
    PERFORM vault.create_secret(
      'https://cnuahgrfzcqkmdyhunuk.supabase.co',
      'supabase_url',
      'Supabase project base URL for Edge Function calls'
    );
  END IF;
END $$;

SELECT cron.schedule(
  'e2e-simulation',
  '0 * * * *',
  $$
    SELECT net.http_post(
      url := (
        SELECT decrypted_secret FROM vault.decrypted_secrets
        WHERE name = 'supabase_url' LIMIT 1
      ) || '/functions/v1/e2e-test-runner',
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
