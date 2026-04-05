-- Fix #964: 자동 이벤트 완료 크론
-- end_time이 지난 scheduled 이벤트를 15분마다 completed로 전환
-- on_event_completed 트리거가 settlement_items를 자동 생성

SELECT cron.unschedule(jobid)
FROM cron.job
WHERE jobname IN ('auto-complete-past-events');

SELECT cron.schedule(
  'auto-complete-past-events',
  '*/15 * * * *',
  $$
    UPDATE public.events
    SET status = 'completed', updated_at = now()
    WHERE status = 'scheduled'
      AND end_time < now();
  $$
);
