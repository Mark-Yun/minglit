-- 1. Batch Vector Worker (Every minute)
-- Uses Vault for secure key management with improved robustness
select cron.schedule(
  'vector-worker-batch',
  '* * * * *',
  $$ 
  select net.http_post(
       url := 'http://kong:8000/functions/v1/vector-worker',
       headers := jsonb_build_object(
         'Content-Type', 'application/json',
         'Authorization', (
            select 'Bearer ' || decrypted_secret 
            from vault.decrypted_secrets 
            where name = 'service_role_key' 
            limit 1
         )
       ),
       body := '{"batch_size": 50}'::jsonb
     ) 
  $$
);

-- 2. Real-time Notification Worker (Every minute)
select cron.schedule(
  'notification-worker-polling',
  '* * * * *',
  $$ 
  select net.http_post(
       url := 'http://kong:8000/functions/v1/notification-worker',
       headers := jsonb_build_object(
         'Content-Type', 'application/json',
         'Authorization', (
            select 'Bearer ' || decrypted_secret 
            from vault.decrypted_secrets 
            where name = 'service_role_key' 
            limit 1
         )
       ),
       body := '{}'::jsonb
     ) 
  $$
);
