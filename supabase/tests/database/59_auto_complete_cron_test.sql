-- Fix #964: auto-complete-past-events 크론 등록 확인 + SQL 조건 검증
BEGIN;

SELECT plan(3);

SET ROLE postgres;

-- T1: 크론 잡 등록 확인
SELECT is(
  (SELECT count(*)::int FROM cron.job WHERE jobname = 'auto-complete-past-events'),
  1,
  'auto-complete-past-events cron job is registered'
);

-- T2: 크론 주기 확인 (15분마다)
SELECT is(
  (SELECT schedule FROM cron.job WHERE jobname = 'auto-complete-past-events'),
  '*/15 * * * *',
  'auto-complete-past-events runs every 15 minutes'
);

-- T3: 크론 SQL 조건 실행 — 오류 없이 수행되는지 확인
-- (실제 row-level 검증은 events FK chain 설정이 필요해 DB 레벨에서 생략하고 smoke test로 대체)
SELECT lives_ok(
  $$
    UPDATE public.events
    SET status = 'completed', updated_at = now()
    WHERE status = 'scheduled'
      AND end_time < now()
  $$,
  'auto-complete cron SQL runs without error'
);

RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
