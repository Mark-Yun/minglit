-- Fix #1954: Add SET search_path to all SECURITY DEFINER functions
-- to prevent schema injection attacks via search_path manipulation.
--
-- Affected functions (originally missing SET search_path):
--   analytics.aggregate_daily_active_users
--   analytics.aggregate_daily_events
--   analytics.aggregate_daily_revenue
--   analytics.aggregate_funnel_daily
--   analytics.check_infra_alert
--   analytics.send_weekly_report
--   public.replace_match_rules

-- ============================================================
-- 1. aggregate_daily_active_users
-- ============================================================
CREATE OR REPLACE FUNCTION analytics.aggregate_daily_active_users(
  p_date DATE DEFAULT CURRENT_DATE
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = analytics, public
AS $$
BEGIN
  -- app_user: distinct users who applied to events on p_date
  INSERT INTO analytics.daily_active_users (date, app, count)
  SELECT
    p_date,
    'app_user',
    COUNT(DISTINCT user_id)
  FROM public.event_applications
  WHERE created_at >= p_date
    AND created_at < p_date + INTERVAL '1 day'
  ON CONFLICT (date, app) DO UPDATE SET count = EXCLUDED.count;

  -- app_partner: distinct partners who had party activity on p_date
  INSERT INTO analytics.daily_active_users (date, app, count)
  SELECT
    p_date,
    'app_partner',
    COUNT(DISTINCT partner_id)
  FROM public.parties
  WHERE created_at >= p_date
    AND created_at < p_date + INTERVAL '1 day'
  ON CONFLICT (date, app) DO UPDATE SET count = EXCLUDED.count;
END;
$$;

-- ============================================================
-- 2. aggregate_daily_events
-- ============================================================
CREATE OR REPLACE FUNCTION analytics.aggregate_daily_events(
  p_date DATE DEFAULT CURRENT_DATE
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = analytics, public
AS $$
BEGIN
  -- Count event applications created on p_date as 'event_applied'
  INSERT INTO analytics.daily_events (date, event_name, count)
  SELECT
    p_date,
    'event_applied',
    COUNT(*)
  FROM public.event_applications
  WHERE created_at >= p_date
    AND created_at < p_date + INTERVAL '1 day'
  ON CONFLICT (date, event_name) DO UPDATE SET count = EXCLUDED.count;

  -- Count successful payments on p_date as 'payment_completed'
  INSERT INTO analytics.daily_events (date, event_name, count)
  SELECT
    p_date,
    'payment_completed',
    COUNT(*)
  FROM public.event_applications
  WHERE updated_at >= p_date
    AND updated_at < p_date + INTERVAL '1 day'
    AND status IN ('approved', 'paid')
  ON CONFLICT (date, event_name) DO UPDATE SET count = EXCLUDED.count;

  -- Count failed payments on p_date as 'payment_failed'
  INSERT INTO analytics.daily_events (date, event_name, count)
  SELECT
    p_date,
    'payment_failed',
    COUNT(*)
  FROM public.event_applications
  WHERE updated_at >= p_date
    AND updated_at < p_date + INTERVAL '1 day'
    AND status = 'payment_failed'
  ON CONFLICT (date, event_name) DO UPDATE SET count = EXCLUDED.count;
END;
$$;

-- ============================================================
-- 3. aggregate_daily_revenue
-- ============================================================
CREATE OR REPLACE FUNCTION analytics.aggregate_daily_revenue(
  p_date DATE DEFAULT CURRENT_DATE
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = analytics, public
AS $$
BEGIN
  INSERT INTO analytics.daily_revenue (date, gross, net, refunds)
  SELECT
    p_date,
    -- gross: sum of payment_amount for approved/paid applications updated on p_date
    COALESCE(SUM(
      CASE WHEN status IN ('approved', 'paid') THEN COALESCE(payment_amount, 0) ELSE 0 END
    ), 0),
    -- net: same as gross (no commission model yet)
    COALESCE(SUM(
      CASE WHEN status IN ('approved', 'paid') THEN COALESCE(payment_amount, 0) ELSE 0 END
    ), 0),
    -- refunds: sum of payment_amount for applications with completed refunds
    COALESCE(SUM(
      CASE WHEN refund_status = 'completed' THEN COALESCE(payment_amount, 0) ELSE 0 END
    ), 0)
  FROM public.event_applications
  WHERE updated_at >= p_date
    AND updated_at < p_date + INTERVAL '1 day'
  ON CONFLICT (date) DO UPDATE SET
    gross   = EXCLUDED.gross,
    net     = EXCLUDED.net,
    refunds = EXCLUDED.refunds;
END;
$$;

-- ============================================================
-- 4. aggregate_funnel_daily
-- ============================================================
CREATE OR REPLACE FUNCTION analytics.aggregate_funnel_daily(
  p_date DATE DEFAULT CURRENT_DATE
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = analytics, public
AS $$
DECLARE
  v_applied   BIGINT;
  v_paid      BIGINT;
BEGIN
  SELECT COUNT(*)      INTO v_applied
  FROM public.event_applications
  WHERE created_at >= p_date
    AND created_at < p_date + INTERVAL '1 day';

  SELECT COUNT(*)      INTO v_paid
  FROM public.event_applications
  WHERE created_at >= p_date
    AND created_at < p_date + INTERVAL '1 day'
    AND status IN ('approved', 'paid');

  -- Step 1: event_applied (base)
  INSERT INTO analytics.funnel_daily (date, step, count, conversion_rate)
  VALUES (p_date, 'event_applied', COALESCE(v_applied, 0), 100.00)
  ON CONFLICT (date, step) DO UPDATE SET
    count           = EXCLUDED.count,
    conversion_rate = EXCLUDED.conversion_rate;

  -- Step 2: payment_completed (conversion from applied)
  INSERT INTO analytics.funnel_daily (date, step, count, conversion_rate)
  VALUES (
    p_date,
    'payment_completed',
    COALESCE(v_paid, 0),
    CASE
      WHEN v_applied > 0 THEN ROUND((v_paid::numeric / v_applied) * 100, 2)
      ELSE 0.00
    END
  )
  ON CONFLICT (date, step) DO UPDATE SET
    count           = EXCLUDED.count,
    conversion_rate = EXCLUDED.conversion_rate;
END;
$$;

-- ============================================================
-- 5. check_infra_alert
-- ============================================================
CREATE OR REPLACE FUNCTION analytics.check_infra_alert()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = analytics, pgmq, public
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

-- ============================================================
-- 6. send_weekly_report
-- ============================================================
CREATE OR REPLACE FUNCTION analytics.send_weekly_report()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = analytics, public
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

-- ============================================================
-- 7. replace_match_rules
-- ============================================================
CREATE OR REPLACE FUNCTION public.replace_match_rules(
  p_event_id uuid,
  p_rules jsonb DEFAULT '[]'::jsonb
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  rule_count integer;
BEGIN
  -- Advisory lock on event_id to serialize concurrent calls
  PERFORM pg_advisory_xact_lock(hashtext(p_event_id::text));

  DELETE FROM public.match_rules WHERE event_id = p_event_id;

  IF jsonb_array_length(p_rules) > 0 THEN
    INSERT INTO public.match_rules (event_id, source_group_id, target_group_id, vote_count)
    SELECT
      p_event_id,
      (r->>'source_group_id')::uuid,
      (r->>'target_group_id')::uuid,
      COALESCE((r->>'vote_count')::integer, 1)
    FROM jsonb_array_elements(p_rules) AS r;
  END IF;

  GET DIAGNOSTICS rule_count = ROW_COUNT;
  RETURN rule_count;
END;
$$;
