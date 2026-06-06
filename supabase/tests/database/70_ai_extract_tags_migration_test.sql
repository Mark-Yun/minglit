-- Fix #1420: ai-extract-tags 마이그레이션 검증 테스트
-- - party_tags.source 컬럼 및 CHECK constraint 검증
-- - event_queue_name enum에 q_tags 값 검증
-- - event_routes 라우팅 행 검증
-- - ai-extract-tags cron job 검증
-- Web MVP pivot (2026-06-06): q_tags/q_vectors 라우트 비활성 + cron 해제가 새 기대 상태
-- (20260606054500_web_mvp_disable_ai_pipeline_ingestion.sql). plan(10) → plan(9).
BEGIN;

SELECT plan(9);

SET ROLE postgres;

-- ============================================================
-- 1. party_tags.source 컬럼 검증
-- ============================================================

SELECT has_column(
  'public', 'party_tags', 'source',
  'party_tags.source column exists'
);

SELECT col_not_null(
  'public', 'party_tags', 'source',
  'party_tags.source is NOT NULL'
);

SELECT col_has_default(
  'public', 'party_tags', 'source',
  'party_tags.source has a default value'
);

-- ============================================================
-- 2. party_tags_source_check CHECK constraint 검증
-- ============================================================

SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'party_tags_source_check'
      AND conrelid = 'public.party_tags'::regclass
      AND contype = 'c'
  ),
  'party_tags_source_check CHECK constraint exists'
);

-- ============================================================
-- 3. event_queue_name enum에 q_tags 값 검증
-- ============================================================

SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_enum
    WHERE enumlabel = 'q_tags'
      AND enumtypid = 'public.event_queue_name'::regtype
  ),
  'event_queue_name enum contains q_tags value'
);

-- ============================================================
-- 4. event_routes 라우팅 행 검증
-- ============================================================

-- Web MVP pivot: 라우트 행은 보존하되 비활성 상태여야 한다 (복구 가능성 유지)
SELECT is(
  (
    SELECT count(*)::int FROM public.event_routes
    WHERE event_type = 'party_created'
      AND target_queue = 'q_tags'
      AND is_active = false
  ),
  1,
  'event_routes preserves party_created → q_tags route as inactive (web-mvp pivot)'
);

-- Web MVP pivot: q_vectors 라우트 2행 (party_created, user_interaction) 도 보존 + 비활성
SELECT is(
  (
    SELECT count(*)::int FROM public.event_routes
    WHERE target_queue = 'q_vectors'
      AND is_active = false
  ),
  2,
  'event_routes preserves 2 q_vectors routes as inactive (web-mvp pivot)'
);

-- AI 유입 경로에 활성 라우트가 하나도 남지 않아야 한다
SELECT is(
  (
    SELECT count(*)::int FROM public.event_routes
    WHERE target_queue IN ('q_vectors', 'q_tags')
      AND is_active = true
  ),
  0,
  'no active q_vectors/q_tags routes remain (web-mvp pivot)'
);

-- ============================================================
-- 5. ai-extract-tags cron job 검증 (web-mvp pivot: 해제 상태)
-- ============================================================

SELECT is(
  (SELECT count(*)::int FROM cron.job WHERE jobname = 'ai-extract-tags'),
  0,
  'ai-extract-tags cron job is unscheduled (web-mvp pivot)'
);

RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
