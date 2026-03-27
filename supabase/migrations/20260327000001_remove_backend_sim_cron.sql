-- Remove pg_cron backend-simulation job.
-- Replaced by hourly-user-activity.yml GitHub Actions workflow
-- which provides better frequency control and visibility.
SELECT cron.unschedule('backend-simulation');
