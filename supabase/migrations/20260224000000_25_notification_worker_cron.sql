set search_path to public, extensions;

select cron.schedule(
  'process-notifications',
  '* * * * *',
  $$
    select net.http_post(
      url:='https://pbbfiqjectdyyyucorpa.supabase.co/functions/v1/notification-worker',
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
