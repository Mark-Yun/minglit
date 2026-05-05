BEGIN;
SELECT plan(2);

-- ============================================================
-- Test 1: 컬럼 존재 확인
-- ============================================================

SELECT has_column(
  'public',
  'event_applications',
  'match_results_viewed_at',
  'event_applications.match_results_viewed_at 컬럼 존재'
);

-- ============================================================
-- Test 2: partial index 존재 확인
-- ============================================================

SELECT has_index(
  'public',
  'event_applications',
  'idx_event_applications_match_results_viewed',
  'idx_event_applications_match_results_viewed exists'
);

SELECT * FROM finish();
ROLLBACK;
