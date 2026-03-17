-- ============================================================
-- Analytics Infrastructure: Schema, Role, and Aggregation Tables
-- ============================================================

-- 1. Create analytics schema
CREATE SCHEMA IF NOT EXISTS analytics;

-- 2. Create analytics_reader role (NOLOGIN — login credentials provisioned per-environment)
DO $$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'analytics_reader') THEN
    CREATE ROLE analytics_reader WITH NOLOGIN;
  END IF;
END $$;

-- 3. Grant USAGE on analytics schema
GRANT USAGE ON SCHEMA analytics TO analytics_reader;
GRANT USAGE ON SCHEMA analytics TO postgres, anon, authenticated, service_role;

-- 4. Explicitly revoke all on public schema from analytics_reader
REVOKE ALL ON SCHEMA public FROM analytics_reader;

-- 5. Create aggregation tables in analytics schema

-- Daily Active Users by app
CREATE TABLE IF NOT EXISTS analytics.daily_active_users (
  date DATE NOT NULL,
  app TEXT NOT NULL,  -- 'app_user' or 'app_partner'
  count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (date, app)
);

-- Daily Events aggregation
CREATE TABLE IF NOT EXISTS analytics.daily_events (
  date DATE NOT NULL,
  event_name TEXT NOT NULL,
  count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (date, event_name)
);

-- Daily Revenue aggregation
CREATE TABLE IF NOT EXISTS analytics.daily_revenue (
  date DATE NOT NULL,
  gross BIGINT NOT NULL DEFAULT 0,
  net BIGINT NOT NULL DEFAULT 0,
  refunds BIGINT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (date)
);

-- Daily Funnel aggregation
CREATE TABLE IF NOT EXISTS analytics.funnel_daily (
  date DATE NOT NULL,
  step TEXT NOT NULL,
  count INTEGER NOT NULL DEFAULT 0,
  conversion_rate NUMERIC(5,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (date, step)
);

-- 6. Enable RLS on all analytics tables
ALTER TABLE analytics.daily_active_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics.daily_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics.daily_revenue ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics.funnel_daily ENABLE ROW LEVEL SECURITY;

CREATE POLICY service_role_select_dau ON analytics.daily_active_users FOR SELECT TO service_role USING (true);
CREATE POLICY service_role_select_events ON analytics.daily_events FOR SELECT TO service_role USING (true);
CREATE POLICY service_role_select_revenue ON analytics.daily_revenue FOR SELECT TO service_role USING (true);
CREATE POLICY service_role_select_funnel ON analytics.funnel_daily FOR SELECT TO service_role USING (true);

-- 7. Grant SELECT on all tables in analytics schema
GRANT SELECT ON ALL TABLES IN SCHEMA analytics TO analytics_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA analytics TO service_role;

-- 8. Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA analytics GRANT SELECT ON TABLES TO analytics_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA analytics GRANT SELECT ON TABLES TO service_role;
