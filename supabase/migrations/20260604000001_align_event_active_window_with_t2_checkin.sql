-- Align event active window with the partner T-2 check-in contract.
-- Existing event-checkin allows active/ongoing events, so the state machine
-- must promote scheduled events to active 2 hours before start_time.

set search_path to public, extensions;

UPDATE public.events
SET status = 'active', updated_at = now()
WHERE status = 'scheduled'
  AND start_time - interval '2 hours' <= now()
  AND start_time > now();

SELECT cron.unschedule(jobid)
FROM cron.job
WHERE jobname = 'activate-upcoming-events';

SELECT cron.schedule(
  'activate-upcoming-events',
  '* * * * *',
  $$
    UPDATE public.events
    SET status = 'active', updated_at = now()
    WHERE status = 'scheduled'
      AND start_time - interval '2 hours' <= now()
      AND start_time > now();
  $$
);
