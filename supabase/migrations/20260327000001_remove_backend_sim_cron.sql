-- Remove hourly backend-simulation cron job (moved to GitHub Actions)
SELECT cron.unschedule('backend-simulation');
