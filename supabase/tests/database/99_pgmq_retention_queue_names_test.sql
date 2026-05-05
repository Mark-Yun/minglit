-- pgTAP regression test for Fix #2202: pgmq_archive retention queue_name must include q_ prefix
BEGIN;

SELECT plan(3);

-- All pgmq_archive policies must use queue_name matching actual pgmq.create() arg (q_* prefix)
SELECT ok(
  (
    SELECT bool_and((target->>'queue_name') LIKE 'q_%')
    FROM admin.retention_policies
    WHERE kind = 'pgmq_archive'
  ),
  'all pgmq_archive retention policies have q_ prefix in queue_name'
);

SELECT ok(
  EXISTS (
    SELECT 1 FROM admin.retention_policies
    WHERE id = 'pgmq_global_events_archive'
      AND target->>'queue_name' = 'q_global_events'
  ),
  'pgmq_global_events_archive uses q_global_events'
);

SELECT ok(
  NOT EXISTS (
    SELECT 1 FROM admin.retention_policies
    WHERE kind = 'pgmq_archive'
      AND target->>'queue_name' NOT LIKE 'q_%'
  ),
  'no pgmq_archive policy has bare queue_name without q_ prefix'
);

SELECT * FROM finish();
ROLLBACK;
