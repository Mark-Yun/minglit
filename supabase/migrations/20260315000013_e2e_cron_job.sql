select cron.schedule(
  'e2e-simulation',
  '0 * * * *',
  $$
    select net.http_post(
      url:='https://cnuahgrfzcqkmdyhunuk.supabase.co/functions/v1/e2e-test-runner',
      headers:=(
        jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'service_role_key' limit 1)
        )
      ),
      body:='{}'::jsonb
    ) as request_id;
  $$
);
