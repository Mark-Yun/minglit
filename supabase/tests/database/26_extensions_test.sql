BEGIN;
SELECT plan(10);

-- extensions 존재 확인
SELECT ok(EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'pgroonga'), 'pgroonga installed');
SELECT ok(EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'vector'), 'vector installed');
SELECT ok(EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'pg_cron'), 'pg_cron installed');
SELECT ok(EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'pg_net'), 'pg_net installed');
SELECT ok(EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'pgmq'), 'pgmq installed');
SELECT ok(EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'supabase_vault'), 'supabase_vault installed');

-- cron jobs 3개
SET ROLE postgres;
SELECT is(
  (SELECT count(*)::int FROM cron.job WHERE jobname = 'settlement-status-transition'),
  1,
  'settlement cron registered'
);
SELECT is(
  (SELECT count(*)::int FROM cron.job WHERE jobname = 'process-notifications'),
  1,
  'notification cron registered'
);
SELECT is(
  (SELECT count(*)::int FROM cron.job WHERE jobname = 'send-event-reminders'),
  1,
  'reminder cron registered'
);

-- process-global-events는 없어야 함 (비활성화 제거)
SELECT is(
  (SELECT count(*)::int FROM cron.job WHERE jobname = 'process-global-events'),
  0,
  'process-global-events cron NOT registered'
);
RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
