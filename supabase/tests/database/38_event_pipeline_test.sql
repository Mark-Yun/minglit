BEGIN;
SELECT plan(6);

SELECT tests.authenticate_as_service_role();

-- ============================================================
-- Test 1+2: party_created → q_notifications, q_vectors 모두 도착
-- ============================================================

-- 큐 초기화
SELECT pgmq.purge_queue('q_notifications');
SELECT pgmq.purge_queue('q_vectors');

-- party_created 이벤트 발송
SELECT public.fan_out_event('party_created', '{"id": "test-party-1", "title": "Test Party"}'::jsonb);

SELECT is(
  (SELECT count(*)::int FROM pgmq.q_notifications),
  1,
  'party_created → q_notifications에 메시지 1개 도착'
);

SELECT is(
  (SELECT count(*)::int FROM pgmq.q_vectors),
  1,
  'party_created → q_vectors에 메시지 1개 도착'
);

-- ============================================================
-- Test 3+4: application_approved → q_notifications에만 도착
-- ============================================================

-- 큐 초기화
SELECT pgmq.purge_queue('q_notifications');
SELECT pgmq.purge_queue('q_vectors');

-- application_approved 이벤트 발송
SELECT public.fan_out_event('application_approved', '{"id": "test-app-1"}'::jsonb);

SELECT is(
  (SELECT count(*)::int FROM pgmq.q_notifications),
  1,
  'application_approved → q_notifications에 메시지 1개 도착'
);

SELECT is(
  (SELECT count(*)::int FROM pgmq.q_vectors),
  0,
  'application_approved → q_vectors에 메시지 없음'
);

-- ============================================================
-- Test 5: 미등록 event_type → 어떤 큐에도 메시지 없음 (에러 없이 처리)
-- ============================================================

-- 큐 초기화
SELECT pgmq.purge_queue('q_notifications');
SELECT pgmq.purge_queue('q_vectors');

-- 미등록 event_type 발송
SELECT public.fan_out_event('unknown_event_type', '{}'::jsonb);

SELECT is(
  (SELECT count(*)::int FROM pgmq.q_notifications) + (SELECT count(*)::int FROM pgmq.q_vectors),
  0,
  '미등록 event_type → 어떤 큐에도 메시지 없음'
);

-- ============================================================
-- Test 6: user_interaction → q_notifications, q_vectors 모두 도착
-- ============================================================

-- 큐 초기화
SELECT pgmq.purge_queue('q_notifications');
SELECT pgmq.purge_queue('q_vectors');

-- user_interaction 이벤트 발송
SELECT public.fan_out_event('user_interaction', '{"user_id": "test-user-1", "action": "like"}'::jsonb);

SELECT is(
  (SELECT count(*)::int FROM pgmq.q_notifications) + (SELECT count(*)::int FROM pgmq.q_vectors),
  2,
  'user_interaction → q_notifications + q_vectors 합계 2개 도착'
);

SELECT * FROM finish();
ROLLBACK;
