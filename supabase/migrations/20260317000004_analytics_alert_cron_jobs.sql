-- ============================================================
-- Analytics Alert Threshold Functions and pg_cron Jobs
-- ============================================================
-- Calls metrics-alert Edge Function when thresholds are exceeded.
-- Uses net.http_post() to call Edge Function from pg_cron.
-- Vault secret: service_role_key (already used in existing cron jobs)

-- ============================================================
-- 1. Helper: call metrics-alert Edge Function
-- ============================================================
CREATE OR REPLACE FUNCTION analytics.call_metrics_alert(
  p_type TEXT,
  p_title TEXT,
  p_body TEXT
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_service_role_key TEXT;
  v_supabase_url TEXT;
BEGIN
  SELECT decrypted_secret INTO v_service_role_key
  FROM vault.decrypted_secrets
  WHERE name = 'service_role_key'
  LIMIT 1;

  v_supabase_url := 'https://cnuahgrfzcqkmdyhunuk.supabase.co';

  PERFORM net.http_post(
    url := v_supabase_url || '/functions/v1/metrics-alert',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_service_role_key
    ),
    body := jsonb_build_object(
      'type', p_type,
      'title', p_title,
      'body', p_body
    )
  );
EXCEPTION WHEN OTHERS THEN
  NULL;
END;
$$;

-- ============================================================
-- 2. Performance alert: check error rate
-- ============================================================
CREATE OR REPLACE FUNCTION analytics.check_performance_alert()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_error_count BIGINT;
  v_total_count BIGINT;
  v_error_rate NUMERIC;
BEGIN
  SELECT COALESCE(count, 0) INTO v_error_count
  FROM analytics.daily_events
  WHERE date = CURRENT_DATE AND event_name = 'error_occurred';

  SELECT COALESCE(SUM(count), 0) INTO v_total_count
  FROM analytics.daily_events
  WHERE date = CURRENT_DATE;

  IF v_total_count > 100 THEN
    v_error_rate := (v_error_count::numeric / v_total_count) * 100;
    IF v_error_rate > 5 THEN
      PERFORM analytics.call_metrics_alert(
        'performance',
        '[Alert] High error rate detected: ' || ROUND(v_error_rate, 1) || '%',
        '**Error Rate Alert**' || chr(10) ||
        '- Date: ' || CURRENT_DATE::text || chr(10) ||
        '- Error count: ' || v_error_count || chr(10) ||
        '- Total events: ' || v_total_count || chr(10) ||
        '- Error rate: ' || ROUND(v_error_rate, 1) || '% (threshold: 5%)'
      );
    END IF;
  END IF;
END;
$$;

-- ============================================================
-- 3. Business alert: check revenue drop
-- ============================================================
CREATE OR REPLACE FUNCTION analytics.check_business_alert()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_today_revenue BIGINT;
  v_yesterday_revenue BIGINT;
  v_drop_pct NUMERIC;
BEGIN
  SELECT COALESCE(gross, 0) INTO v_today_revenue
  FROM analytics.daily_revenue
  WHERE date = CURRENT_DATE;

  SELECT COALESCE(gross, 0) INTO v_yesterday_revenue
  FROM analytics.daily_revenue
  WHERE date = CURRENT_DATE - 1;

  IF v_yesterday_revenue > 0 AND v_today_revenue < v_yesterday_revenue THEN
    v_drop_pct := ((v_yesterday_revenue - v_today_revenue)::numeric / v_yesterday_revenue) * 100;
    IF v_drop_pct > 30 THEN
      PERFORM analytics.call_metrics_alert(
        'business',
        '[Alert] Revenue drop detected: -' || ROUND(v_drop_pct, 1) || '%',
        '**Revenue Drop Alert**' || chr(10) ||
        '- Date: ' || CURRENT_DATE::text || chr(10) ||
        '- Today: ' || v_today_revenue || chr(10) ||
        '- Yesterday: ' || v_yesterday_revenue || chr(10) ||
        '- Drop: ' || ROUND(v_drop_pct, 1) || '% (threshold: 30%)'
      );
    END IF;
  END IF;
END;
$$;

-- ============================================================
-- 4. Daily report: send summary at 9 AM KST (0:00 UTC)
-- ============================================================
CREATE OR REPLACE FUNCTION analytics.send_daily_report()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_dau_user BIGINT;
  v_dau_partner BIGINT;
  v_revenue BIGINT;
  v_applications BIGINT;
BEGIN
  SELECT COALESCE(count, 0) INTO v_dau_user
  FROM analytics.daily_active_users
  WHERE date = CURRENT_DATE - 1 AND app = 'app_user';

  SELECT COALESCE(count, 0) INTO v_dau_partner
  FROM analytics.daily_active_users
  WHERE date = CURRENT_DATE - 1 AND app = 'app_partner';

  SELECT COALESCE(gross, 0) INTO v_revenue
  FROM analytics.daily_revenue
  WHERE date = CURRENT_DATE - 1;

  SELECT COALESCE(count, 0) INTO v_applications
  FROM analytics.daily_events
  WHERE date = CURRENT_DATE - 1 AND event_name = 'event_applied';

  PERFORM analytics.call_metrics_alert(
    'report',
    '[Daily Report] ' || (CURRENT_DATE - 1)::text,
    '**Daily Summary — ' || (CURRENT_DATE - 1)::text || '**' || chr(10) ||
    '| Metric | Value |' || chr(10) ||
    '|--------|-------|' || chr(10) ||
    '| DAU (User App) | ' || v_dau_user || ' |' || chr(10) ||
    '| DAU (Partner App) | ' || v_dau_partner || ' |' || chr(10) ||
    '| Applications | ' || v_applications || ' |' || chr(10) ||
    '| Revenue | ₩' || v_revenue || ' |'
  );
END;
$$;

-- ============================================================
-- 5. Register pg_cron jobs
-- ============================================================

SELECT cron.schedule(
  'check_performance_alert',
  '*/15 * * * *',
  $$SELECT analytics.check_performance_alert()$$
);

SELECT cron.schedule(
  'check_business_alert',
  '*/15 * * * *',
  $$SELECT analytics.check_business_alert()$$
);

SELECT cron.schedule(
  'send_daily_report',
  '0 0 * * *',
  $$SELECT analytics.send_daily_report()$$
);
