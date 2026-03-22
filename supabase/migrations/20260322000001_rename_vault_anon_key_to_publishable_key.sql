-- Rename vault secret 'anon_key' → 'publishable_key'
-- anon_key is Supabase legacy naming; publishable_key is the new standard.
-- All cron jobs and trigger functions that reference vault 'anon_key' are updated.

-- ============================================================
-- 1. Rename vault secret
-- ============================================================
DO $$
DECLARE
  v_secret TEXT;
BEGIN
  SELECT decrypted_secret INTO v_secret
  FROM vault.decrypted_secrets WHERE name = 'anon_key' LIMIT 1;

  IF v_secret IS NOT NULL THEN
    -- Delete old, create new
    DELETE FROM vault.secrets WHERE name = 'anon_key';
    PERFORM vault.create_secret(v_secret, 'publishable_key', 'Publishable key for EF cron calls');
    RAISE NOTICE 'vault: anon_key renamed to publishable_key';
  ELSE
    -- Maybe already renamed or never existed
    IF NOT EXISTS (SELECT 1 FROM vault.decrypted_secrets WHERE name = 'publishable_key') THEN
      RAISE WARNING 'vault: neither anon_key nor publishable_key found — CI must inject publishable_key';
    ELSE
      RAISE NOTICE 'vault: publishable_key already exists';
    END IF;
  END IF;
END $$;

-- ============================================================
-- 2. Recreate cron jobs with publishable_key
-- ============================================================

-- 2-1. backend-simulation
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
            WHERE name = 'publishable_key' LIMIT 1
          )
        )
      ),
      body := '{}'::jsonb
    ) AS request_id;
  $$
);

-- 2-2. process-notifications
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
            WHERE name = 'publishable_key' LIMIT 1
          )
        )
      ),
      body := '{}'::jsonb
    ) AS request_id;
  $$
);

-- 2-3. settlement-reconciliation-daily
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
            WHERE name = 'publishable_key' LIMIT 1
          )
        )
      ),
      body := '{}'::jsonb
    ) AS request_id;
  $$
);

-- 2-4. settlement-register-transfers
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
            WHERE name = 'publishable_key' LIMIT 1
          )
        )
      ),
      body := '{}'::jsonb
    ) AS request_id;
  $$
);

-- 2-5. settlement-payout-sync
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
            WHERE name = 'publishable_key' LIMIT 1
          )
        )
      ),
      body := '{}'::jsonb
    ) AS request_id;
  $$
);

-- 2-6. settlement-alarm-check
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
            WHERE name = 'publishable_key' LIMIT 1
          )
        )
      ),
      body := '{}'::jsonb
    ) AS request_id;
  $$
);

-- ============================================================
-- 3. Update trigger functions with publishable_key
-- ============================================================

-- 3-1. handle_application_rejection
CREATE OR REPLACE FUNCTION public.handle_application_rejection()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, net
AS $$
DECLARE
  v_payment_id text;
  v_reason text;
  v_project_url text;
  v_publishable_key text;
BEGIN
  IF new.status = 'rejected' AND (old.status IS DISTINCT FROM 'rejected') THEN
    v_payment_id := new.payment_id;
    v_reason := new.rejection_reason;

    IF v_payment_id IS NOT NULL THEN
      -- Fix #209: set refund_status before vault lookup so it persists even when secrets are missing
      new.refund_status := 'requested';

      SELECT decrypted_secret INTO v_project_url
      FROM vault.decrypted_secrets
      WHERE name = 'supabase_url' LIMIT 1;

      SELECT decrypted_secret INTO v_publishable_key
      FROM vault.decrypted_secrets
      WHERE name = 'publishable_key' LIMIT 1;

      IF v_project_url IS NULL OR v_publishable_key IS NULL THEN
        RAISE WARNING 'handle_application_rejection: vault secret missing (supabase_url=%, publishable_key=%)',
          v_project_url IS NOT NULL, v_publishable_key IS NOT NULL;
        RETURN new;
      END IF;

      PERFORM net.http_post(
        url := v_project_url || '/functions/v1/payment-cancel',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || v_publishable_key
        ),
        body := jsonb_build_object(
          'payment_id', v_payment_id,
          'reason', v_reason
        )
      );
    END IF;
  END IF;
  RETURN new;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'handle_application_rejection failed: [%] %', SQLSTATE, SQLERRM;
  RETURN new;
END;
$$;

-- 3-2. analytics.call_metrics_alert
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
  v_publishable_key TEXT;
  v_supabase_url TEXT;
BEGIN
  SELECT decrypted_secret INTO v_publishable_key
  FROM vault.decrypted_secrets
  WHERE name = 'publishable_key'
  LIMIT 1;

  SELECT decrypted_secret INTO v_supabase_url
  FROM vault.decrypted_secrets
  WHERE name = 'supabase_url'
  LIMIT 1;

  IF v_supabase_url IS NULL OR v_publishable_key IS NULL THEN
    RAISE WARNING 'call_metrics_alert: vault secret missing (supabase_url=%, publishable_key=%)',
      v_supabase_url IS NOT NULL, v_publishable_key IS NOT NULL;
    RETURN;
  END IF;

  PERFORM net.http_post(
    url := v_supabase_url || '/functions/v1/metrics-alert',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_publishable_key
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
