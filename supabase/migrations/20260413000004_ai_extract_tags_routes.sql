-- ai-extract-tags EF를 위한 DB 설정 (Part 2)
-- - PGMQ q_tags 큐 생성
-- - event_routes에 party_created → q_tags 라우팅 추가
-- - ai-extract-tags cron 추가
-- Note: event_queue_name enum에 'q_tags'가 이전 마이그레이션에서 추가됨

set search_path to public, extensions;

-- ============================================================
-- 1. PGMQ q_tags 큐 생성
-- ============================================================

-- pgmq.create는 큐가 이미 존재하면 에러를 발생시키지 않음 (idempotent)
SELECT pgmq.create('q_tags');

-- ============================================================
-- 2. event_routes에 q_tags 라우팅 추가
-- ============================================================

-- party_created 이벤트를 q_tags에도 팬아웃하도록 설정.
-- ON CONFLICT는 20260301000008_08_cron_routes.sql에서 추가된 UNIQUE 제약 조건 활용.
INSERT INTO public.event_routes (event_type, target_queue, is_active)
VALUES ('party_created', 'q_tags', true)
ON CONFLICT (event_type, target_queue) DO UPDATE SET is_active = EXCLUDED.is_active;

-- ============================================================
-- 3. Cron: ai-extract-tags (every minute)
-- ============================================================

SELECT cron.schedule(
  'ai-extract-tags',
  '* * * * *',
  $$
    SELECT net.http_post(
      url := (
        SELECT decrypted_secret FROM vault.decrypted_secrets
        WHERE name = 'supabase_url' LIMIT 1
      ) || '/functions/v1/ai-extract-tags',
      headers := (
        jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || (
            SELECT decrypted_secret FROM vault.decrypted_secrets
            WHERE name = 'publishable_key' LIMIT 1
          )
        )
      ),
      body := '{}'::jsonb
    ) as request_id;
  $$
);
