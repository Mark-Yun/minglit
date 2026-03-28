-- ============================================================
-- Analytics Infra Alert and Weekly Report
-- ============================================================
-- Adds infra alert (DLQ check) and weekly report cron jobs
-- to complete the 4-type alert system.

CREATE OR REPLACE FUNCTION analytics.check_infra_alert()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_dlq_count BIGINT := 0;
BEGIN
  BEGIN
    SELECT COUNT(*) INTO v_dlq_count
    FROM pgmq.q_dead_letter_queue;
  EXCEPTION WHEN OTHERS THEN
    v_dlq_count := 0;
  END;

  IF v_dlq_count > 10 THEN
    PERFORM analytics.call_metrics_alert(
      'infra',
      '[Alert] DLQ accumulation detected: ' || v_dlq_count || ' messages',
      '**Infrastructure Alert**' || chr(10) ||
      '- Date: ' || CURRENT_DATE::text || chr(10) ||
      '- DLQ messages: ' || v_dlq_count || ' (threshold: 10)' || chr(10) ||
      '- Action: Check notification-worker and payment-webhook for failures'
    );
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION analytics.send_weekly_report()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_week_start DATE;
  v_week_end DATE;
  v_total_dau BIGINT;
  v_total_revenue BIGINT;
  v_total_applications BIGINT;
BEGIN
  v_week_end := CURRENT_DATE - 1;
  v_week_start := v_week_end - 6;

  SELECT COALESCE(SUM(count), 0) INTO v_total_dau
  FROM analytics.daily_active_users
  WHERE date BETWEEN v_week_start AND v_week_end AND app = 'app_user';

  SELECT COALESCE(SUM(gross), 0) INTO v_total_revenue
  FROM analytics.daily_revenue
  WHERE date BETWEEN v_week_start AND v_week_end;

  SELECT COALESCE(SUM(count), 0) INTO v_total_applications
  FROM analytics.daily_events
  WHERE date BETWEEN v_week_start AND v_week_end AND event_name = 'event_applied';

  PERFORM analytics.call_metrics_alert(
    'report',
    '[Weekly Report] ' || v_week_start::text || ' ~ ' || v_week_end::text,
    '**Weekly Summary — ' || v_week_start::text || ' ~ ' || v_week_end::text || '**' || chr(10) ||
    '| Metric | Value |' || chr(10) ||
    '|--------|-------|' || chr(10) ||
    '| Total DAU (User App) | ' || v_total_dau || ' |' || chr(10) ||
    '| Total Applications | ' || v_total_applications || ' |' || chr(10) ||
    '| Total Revenue | ₩' || v_total_revenue || ' |'
  );
END;
$$;

SELECT cron.schedule(
  'check_infra_alert',
  '*/15 * * * *',
  $$SELECT analytics.check_infra_alert()$$
);

SELECT cron.schedule(
  'send_weekly_report',
  '0 0 * * 1',
  $$SELECT analytics.send_weekly_report()$$
);
