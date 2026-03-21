-- Replace service_role_key with anon_key and hardcoded URL with vault supabase_url
-- in DB triggers and functions that call Edge Functions via pg_net.

-- ============================================================
-- 1. handle_application_rejection: payment-cancel trigger
-- ============================================================
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
  v_anon_key text;
BEGIN
  IF new.status = 'rejected' AND (old.status IS DISTINCT FROM 'rejected') THEN
    v_payment_id := new.payment_id;
    v_reason := new.rejection_reason;

    IF v_payment_id IS NOT NULL THEN
      SELECT decrypted_secret INTO v_project_url
      FROM vault.decrypted_secrets
      WHERE name = 'supabase_url' LIMIT 1;

      SELECT decrypted_secret INTO v_anon_key
      FROM vault.decrypted_secrets
      WHERE name = 'anon_key' LIMIT 1;

      PERFORM net.http_post(
        url := v_project_url || '/functions/v1/payment-cancel',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || v_anon_key
        ),
        body := jsonb_build_object(
          'payment_id', v_payment_id,
          'reason', v_reason
        )
      );

      new.refund_status := 'requested';
    END IF;
  END IF;
  RETURN new;
END;
$$;

-- ============================================================
-- 2. analytics.call_metrics_alert: metrics-alert EF caller
-- ============================================================
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
  v_anon_key TEXT;
  v_supabase_url TEXT;
BEGIN
  SELECT decrypted_secret INTO v_anon_key
  FROM vault.decrypted_secrets
  WHERE name = 'anon_key'
  LIMIT 1;

  SELECT decrypted_secret INTO v_supabase_url
  FROM vault.decrypted_secrets
  WHERE name = 'supabase_url'
  LIMIT 1;

  PERFORM net.http_post(
    url := v_supabase_url || '/functions/v1/metrics-alert',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_anon_key
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
