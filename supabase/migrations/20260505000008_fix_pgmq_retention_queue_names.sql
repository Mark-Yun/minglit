-- Fix #2202: retention_policies의 pgmq_archive queue_name이 실제 PGMQ 큐 이름과 불일치.
-- pgmq.create('q_global_events') → 실제 테이블은 pgmq.q_q_global_events.
-- target.queue_name은 create() 에 넘긴 이름과 동일해야 함 → q_ prefix 포함.
UPDATE admin.retention_policies
SET target = jsonb_set(
  target,
  '{queue_name}',
  to_jsonb('q_' || (target->>'queue_name'))
)
WHERE kind = 'pgmq_archive'
  AND target->>'queue_name' NOT LIKE 'q_%';
