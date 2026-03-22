-- GitHub issue/PR daily stats for Metabase dashboard
-- Populated by github-stats-sync Edge Function

CREATE TABLE IF NOT EXISTS analytics.github_daily_stats (
  date DATE NOT NULL,
  metric TEXT NOT NULL,  -- 'issues_opened', 'issues_closed', 'prs_opened', 'prs_merged'
  count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (date, metric)
);

ALTER TABLE analytics.github_daily_stats ENABLE ROW LEVEL SECURITY;
CREATE POLICY service_role_select_github ON analytics.github_daily_stats FOR SELECT TO service_role USING (true);
GRANT SELECT ON analytics.github_daily_stats TO analytics_reader;
GRANT SELECT ON analytics.github_daily_stats TO service_role;

-- RPC function for Edge Function to upsert stats (analytics schema not exposed via REST)
CREATE OR REPLACE FUNCTION public.upsert_github_daily_stat(
  p_date DATE,
  p_metric TEXT,
  p_count INTEGER
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = analytics
AS $$
BEGIN
  INSERT INTO analytics.github_daily_stats (date, metric, count)
  VALUES (p_date, p_metric, p_count)
  ON CONFLICT (date, metric) DO UPDATE SET count = EXCLUDED.count;
END;
$$;

-- Cron: daily at 5:30 AM KST (20:30 UTC)
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
            WHERE name = 'publishable_key' LIMIT 1
          )
        )
      ),
      body := '{}'::jsonb
    ) AS request_id;
  $$
);
