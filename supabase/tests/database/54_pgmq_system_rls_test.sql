BEGIN;
SELECT plan(9);

-- ===========================================================================
-- Fix #594: PGMQ 시스템 테이블 RLS 정책 테스트
-- processed_events, dead_letter_queue, event_routes는 service_role만 접근 가능
-- ===========================================================================

SELECT tests.create_supabase_user('rls_user', 'rls@test.com');

-- ---------------------------------------------------------------------------
-- 1. service_role은 모든 테이블에 접근 가능
-- ---------------------------------------------------------------------------
SELECT tests.authenticate_as_service_role();

SELECT lives_ok(
  $$SELECT count(*) FROM public.processed_events$$,
  'service_role can read processed_events'
);

SELECT lives_ok(
  $$SELECT count(*) FROM public.dead_letter_queue$$,
  'service_role can read dead_letter_queue'
);

SELECT lives_ok(
  $$SELECT count(*) FROM public.event_routes$$,
  'service_role can read event_routes'
);

-- ---------------------------------------------------------------------------
-- 2. authenticated 유저는 접근 불가
-- ---------------------------------------------------------------------------
SELECT tests.authenticate_as('rls_user');

SELECT is_empty(
  $$SELECT * FROM public.processed_events$$,
  'authenticated user cannot read processed_events'
);

SELECT is_empty(
  $$SELECT * FROM public.dead_letter_queue$$,
  'authenticated user cannot read dead_letter_queue'
);

SELECT is_empty(
  $$SELECT * FROM public.event_routes$$,
  'authenticated user cannot read event_routes'
);

-- ---------------------------------------------------------------------------
-- 3. anon은 접근 불가
-- ---------------------------------------------------------------------------
SELECT tests.clear_authentication();

SELECT is_empty(
  $$SELECT * FROM public.processed_events$$,
  'anon cannot read processed_events'
);

SELECT is_empty(
  $$SELECT * FROM public.dead_letter_queue$$,
  'anon cannot read dead_letter_queue'
);

SELECT is_empty(
  $$SELECT * FROM public.event_routes$$,
  'anon cannot read event_routes'
);

SELECT * FROM finish();
ROLLBACK;
