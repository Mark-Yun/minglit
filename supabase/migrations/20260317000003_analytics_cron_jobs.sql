-- ============================================================
-- Analytics Aggregation Functions and pg_cron Jobs
-- ============================================================
-- Schema: analytics (created in 20260317000002_analytics_infrastructure.sql)
-- Tables populated:
--   analytics.daily_active_users (date, app, count)
--   analytics.daily_events       (date, event_name, count)
--   analytics.daily_revenue      (date, gross, net, refunds)
--   analytics.funnel_daily       (date, step, count, conversion_rate)
--
-- Source tables:
--   public.event_applications (user_id, event_id, status, payment_amount, created_at, updated_at)
--   public.parties            (partner_id, created_at)
--
-- Jobs run in UTC off-peak hours (4–5 AM KST = 19:00–20:00 UTC)
-- All inserts are idempotent via ON CONFLICT DO UPDATE

-- ============================================================
-- 1. Aggregate Daily Active Users
-- ============================================================
CREATE OR REPLACE FUNCTION analytics.aggregate_daily_active_users(
  p_date DATE DEFAULT CURRENT_DATE
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
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
-- 2. Aggregate Daily Events
-- ============================================================
CREATE OR REPLACE FUNCTION analytics.aggregate_daily_events(
  p_date DATE DEFAULT CURRENT_DATE
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
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
-- 3. Aggregate Daily Revenue
-- ============================================================
CREATE OR REPLACE FUNCTION analytics.aggregate_daily_revenue(
  p_date DATE DEFAULT CURRENT_DATE
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
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
-- 4. Aggregate Daily Funnel
-- ============================================================
CREATE OR REPLACE FUNCTION analytics.aggregate_funnel_daily(
  p_date DATE DEFAULT CURRENT_DATE
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
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
-- 5. Register pg_cron jobs
-- ============================================================
-- All times are UTC. KST = UTC+9, so:
--   4:00 AM KST = 19:00 UTC (previous day)
--   4:15 AM KST = 19:15 UTC
--   4:30 AM KST = 19:30 UTC
--   5:00 AM KST = 20:00 UTC

SELECT cron.schedule(
  'aggregate_daily_active_users',
  '0 19 * * *',
  $$SELECT analytics.aggregate_daily_active_users()$$
);

SELECT cron.schedule(
  'aggregate_daily_events',
  '15 19 * * *',
  $$SELECT analytics.aggregate_daily_events()$$
);

SELECT cron.schedule(
  'aggregate_daily_revenue',
  '30 19 * * *',
  $$SELECT analytics.aggregate_daily_revenue()$$
);

SELECT cron.schedule(
  'aggregate_funnel_daily',
  '0 20 * * *',
  $$SELECT analytics.aggregate_funnel_daily()$$
);
