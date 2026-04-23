-- Fix #1758: pg_cron → EF 호출 401 — publishable_key → service_role_key 교체
--
-- 원인: PR #1494에서 requireServiceRole() 가드 추가 후 anon JWT(publishable_key)가
--      service_role 가드를 통과하지 못해 모든 system EF 호출이 401.
--
-- 전제 조건: Supabase Vault에 'service_role_key' 시크릿이 등록되어 있어야 함.
--   Dashboard → Database → Vault → New Secret
--   Name: service_role_key  |  Secret: SUPABASE_SERVICE_ROLE_KEY 값
--
-- 대상 (publishable_key → service_role_key):
--   backend-simulation, process-notifications, settlement-reconciliation-daily,
--   settlement-register-transfers, settlement-payout-sync, settlement-alarm-check,
--   sync_github_stats, ai-extract-tags
--
-- 제외 (이미 service_role_key 사용 중):
--   cleanup-retention (20260421000003), cleanup-blocked-dis / process-pending-deletions (20260330000006)
--
-- 제외 (HTTP 미사용, SQL 함수 직접 호출):
--   notify-match-results, cleanup-expired-match-votes

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM vault.decrypted_secrets WHERE name = 'service_role_key'
  ) THEN
    RAISE WARNING
      'vault secret "service_role_key" not found — cron jobs will be rescheduled '
      'but will return NULL JWT until the secret is added to Vault. '
      'Add it via Dashboard → Database → Vault before applying this migration.';
  END IF;
END $$;

-- ============================================================
-- 1. backend-simulation  (매시간)
-- ============================================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'backend-simulation') THEN
    PERFORM cron.unschedule('backend-simulation');
  END IF;
END $$;

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
            WHERE name = 'service_role_key' LIMIT 1
          )
        )
      ),
      body := '{}'::jsonb
    ) AS request_id;
  $$
);

-- ============================================================
-- 2. process-notifications  (매분)
-- ============================================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'process-notifications') THEN
    PERFORM cron.unschedule('process-notifications');
  END IF;
END $$;

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
            WHERE name = 'service_role_key' LIMIT 1
          )
        )
      ),
      body := '{}'::jsonb
    ) AS request_id;
  $$
);

-- ============================================================
-- 3. settlement-reconciliation-daily  (매일 13:00 UTC)
-- ============================================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'settlement-reconciliation-daily') THEN
    PERFORM cron.unschedule('settlement-reconciliation-daily');
  END IF;
END $$;

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
            WHERE name = 'service_role_key' LIMIT 1
          )
        )
      ),
      body := '{}'::jsonb
    ) AS request_id;
  $$
);

-- ============================================================
-- 4. settlement-register-transfers  (매 15분)
-- ============================================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'settlement-register-transfers') THEN
    PERFORM cron.unschedule('settlement-register-transfers');
  END IF;
END $$;

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
            WHERE name = 'service_role_key' LIMIT 1
          )
        )
      ),
      body := '{}'::jsonb
    ) AS request_id;
  $$
);

-- ============================================================
-- 5. settlement-payout-sync  (매일 02:00, 05:00, 08:00 UTC)
-- ============================================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'settlement-payout-sync') THEN
    PERFORM cron.unschedule('settlement-payout-sync');
  END IF;
END $$;

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
            WHERE name = 'service_role_key' LIMIT 1
          )
        )
      ),
      body := '{}'::jsonb
    ) AS request_id;
  $$
);

-- ============================================================
-- 6. settlement-alarm-check  (매 30분)
-- ============================================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'settlement-alarm-check') THEN
    PERFORM cron.unschedule('settlement-alarm-check');
  END IF;
END $$;

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
            WHERE name = 'service_role_key' LIMIT 1
          )
        )
      ),
      body := '{}'::jsonb
    ) AS request_id;
  $$
);

-- ============================================================
-- 7. sync_github_stats  (매일 20:30 UTC)
-- ============================================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'sync_github_stats') THEN
    PERFORM cron.unschedule('sync_github_stats');
  END IF;
END $$;

SELECT cron.schedule(
  'sync_github_stats',
  '30 20 * * *',
  $$
    SELECT net.http_post(
      url := (
        SELECT decrypted_secret FROM vault.decrypted_secrets
        WHERE name = 'supabase_url' LIMIT 1
      ) || '/functions/v1/github-stats-sync',
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

-- ============================================================
-- 8. ai-extract-tags  (매분)
-- ============================================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'ai-extract-tags') THEN
    PERFORM cron.unschedule('ai-extract-tags');
  END IF;
END $$;

SELECT cron.schedule(
  'ai-extract-tags',
  '* * * * *',
  $$
    SELECT net.http_post(
      url := (
        SELECT decrypted_secret FROM vault.decrypted_secrets
        WHERE name = 'supabase_url' LIMIT 1
      ) || '/functions/v1/ai-extract-tags',
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
