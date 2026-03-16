-- Settlement Phase 4: Cron Jobs
-- 2 new cron jobs: reconciliation-daily (13:00 UTC = 22:00 KST) + alarm-check (every 30 min)

-- ============================================================
-- 1. settlement-reconciliation-daily — daily at 13:00 UTC (22:00 KST)
-- ============================================================
select cron.schedule(
  'settlement-reconciliation-daily',
  '0 13 * * *',
  $$
    select net.http_post(
      url:='https://cnuahgrfzcqkmdyhunuk.supabase.co/functions/v1/reconciliation-daily',
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

-- ============================================================
-- 2. settlement-alarm-check — every 30 minutes
-- ============================================================
select cron.schedule(
  'settlement-alarm-check',
  '*/30 * * * *',
  $$select public.check_settlement_alarms();$$
);
