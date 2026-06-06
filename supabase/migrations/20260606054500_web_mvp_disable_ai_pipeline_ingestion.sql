-- Web MVP pivot (2026-06-06, docs/architecture/web-mvp-pivot.md):
-- AI 파이프라인 유입 차단 — 코어(이벤트 생성 → 구매·신청 → 정산)와 무관한
-- 임베딩/태그 추출 비용(OpenAI + 매분 EF 호출)을 멈춘다.
--
-- 1) event_routes: q_vectors(2행) / q_tags(1행) 라우트 비활성화 — 큐 적재 중단.
--    행은 삭제하지 않는다 (복구 = is_active=true 재설정).
-- 2) ai-extract-tags 매분 pg_cron 해제 (복구는 20260423000001 migration 의
--    cron.schedule 블록 참조).
--
-- EF 코드(ai-embed, ai-extract-tags)와 테이블(user_embeddings, party_embeddings,
-- party_tags 등)은 보존 — 매칭/투표 EF 도 idle 상태로 보존 (Mark 결정).

UPDATE public.event_routes
SET is_active = false
WHERE target_queue IN ('q_vectors', 'q_tags');

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'ai-extract-tags') THEN
    PERFORM cron.unschedule('ai-extract-tags');
  END IF;
END $$;
