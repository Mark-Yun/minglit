-- Fix #1420: ai-extract-tags 마이그레이션 검증 테스트
-- - party_tags.source 컬럼 및 CHECK constraint 검증
-- - event_queue_name enum에 q_tags 값 검증
-- - event_routes 라우팅 행 검증
-- - ai-extract-tags cron job 검증
BEGIN;

SELECT plan(10);

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

SELECT is(
  (
    SELECT count(*)::int FROM public.event_routes
    WHERE event_type = 'party_created'
      AND target_queue = 'q_tags'
      AND is_active = true
  ),
  1,
  'event_routes has party_created → q_tags active route'
);

-- ============================================================
-- 5. ai-extract-tags cron job 검증
-- ============================================================

SELECT is(
  (SELECT count(*)::int FROM cron.job WHERE jobname = 'ai-extract-tags'),
  1,
  'ai-extract-tags cron job is registered'
);

SELECT is(
  (SELECT schedule FROM cron.job WHERE jobname = 'ai-extract-tags'),
  '* * * * *',
  'ai-extract-tags cron runs every minute'
);

-- cron SQL이 supabase_url Vault 시크릿을 참조하는지 확인
SELECT ok(
  (SELECT command FROM cron.job WHERE jobname = 'ai-extract-tags') LIKE '%supabase_url%',
  'ai-extract-tags cron uses vault supabase_url (not hardcoded URL)'
);

-- Fix #1758: cron SQL이 service_role_key Vault 시크릿을 참조하는지 확인
-- (이전: publishable_key — requireServiceRole() 가드 추가 후 401 발생, 교체됨)
SELECT ok(
  (SELECT command FROM cron.job WHERE jobname = 'ai-extract-tags') LIKE '%service_role_key%',
  'ai-extract-tags cron uses vault service_role_key (not publishable_key)'
);

RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
