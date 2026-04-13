-- ai-extract-tags EF를 위한 DB 설정
-- - party_tags에 source 컬럼 추가 (manual/ai 구분)
-- - PGMQ q_tags 큐 생성
-- - event_queue_name enum에 q_tags 추가
-- - event_routes에 party_created → q_tags 라우팅 추가
-- - ai-extract-tags cron 추가

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

-- ============================================================
-- 3. PGMQ q_tags 큐 생성
-- ============================================================

-- pgmq.create는 큐가 이미 존재하면 에러를 발생시키지 않음 (idempotent)
SELECT pgmq.create('q_tags');

-- ============================================================
-- 4. event_routes에 q_tags 라우팅 추가
-- ============================================================

-- party_created 이벤트를 q_tags에도 팬아웃하도록 설정.
-- ON CONFLICT는 20260301000008_08_cron_routes.sql에서 추가된 UNIQUE 제약 조건 활용.
INSERT INTO public.event_routes (event_type, target_queue, is_active)
VALUES ('party_created', 'q_tags', true)
ON CONFLICT (event_type, target_queue) DO UPDATE SET is_active = EXCLUDED.is_active;

-- ============================================================
-- 5. Cron: ai-extract-tags (every minute)
-- ============================================================

select cron.schedule(
  'ai-extract-tags',
  '* * * * *',
  $$
    select net.http_post(
      url:='https://cnuahgrfzcqkmdyhunuk.supabase.co/functions/v1/ai-extract-tags',
      headers:=(
        jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'service_role_key' limit 1)
        )
      ),
      body:='{}'::jsonb
    ) as request_id;
  $$
);
