-- ai-extract-tags EF를 위한 DB 설정 (Part 1)
-- - party_tags에 source 컬럼 추가 (manual/ai 구분)
-- - event_queue_name enum에 q_tags 추가
-- Note: enum ADD VALUE는 별도 트랜잭션이 필요하므로 event_routes INSERT는 다음 마이그레이션에서 수행

set search_path to public, extensions;

-- ============================================================
-- 1. party_tags에 source 컬럼 추가
-- ============================================================

-- AI가 추출한 태그와 수동(파트너가 직접 지정)한 태그를 구분하기 위한 컬럼.
-- 기존 데이터는 모두 'manual'로 설정됨 (DEFAULT 'manual').
ALTER TABLE public.party_tags
  ADD COLUMN IF NOT EXISTS source text NOT NULL DEFAULT 'manual';

-- 유효값 제한
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'party_tags_source_check'
      AND conrelid = 'public.party_tags'::regclass
  ) THEN
    ALTER TABLE public.party_tags
      ADD CONSTRAINT party_tags_source_check
      CHECK (source IN ('manual', 'ai'));
  END IF;
END $$;

-- ============================================================
-- 2. event_queue_name enum에 q_tags 추가
-- ============================================================
-- ALTER TYPE ADD VALUE는 트랜잭션 블록 밖에서 실행해야 하지만,
-- Supabase 마이그레이션은 각 파일을 하나의 트랜잭션으로 실행한다.
-- 새 enum 값을 같은 트랜잭션에서 사용하면 PostgreSQL이 "unsafe use of new value" 에러를 발생시킨다.
-- 따라서 enum 추가만 이 마이그레이션에서 수행하고, 새 값을 사용하는 INSERT는 다음 마이그레이션에서 수행한다.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum
    WHERE enumlabel = 'q_tags'
      AND enumtypid = 'public.event_queue_name'::regtype
  ) THEN
    ALTER TYPE public.event_queue_name ADD VALUE 'q_tags';
  END IF;
END $$;
