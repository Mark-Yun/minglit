-- Disable cron job for missing edge function (global-event-worker)
-- This job points to a non-existent function, so keep it disabled until a worker exists.
select cron.unschedule(jobid)
from cron.job
where jobname = 'process-global-events';
