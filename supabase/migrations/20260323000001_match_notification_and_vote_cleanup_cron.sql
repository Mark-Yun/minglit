-- Issue #306: 매칭 결과 알림 + 투표 데이터 정리 크론잡

SET search_path = public, extensions, pgmq, temp;

-- ============================================================
-- 1. match_pairs에 알림 발송 여부 플래그 추가
-- ============================================================

ALTER TABLE public.match_pairs
  ADD COLUMN notification_sent boolean NOT NULL DEFAULT false;

-- ============================================================
-- 2. event_routes에 match_result 이벤트 타입 추가
-- ============================================================

INSERT INTO public.event_routes (event_type, target_queue, is_active) VALUES
  ('match_result', 'q_notifications', true)
ON CONFLICT (event_type, target_queue) DO UPDATE SET is_active = EXCLUDED.is_active;

-- ============================================================
-- 3. 매칭 결과 알림 함수
-- 이벤트 종료 + 1일 후, 아직 알림 미발송인 match_pairs 처리
-- ============================================================

CREATE OR REPLACE FUNCTION public.notify_match_results()
RETURNS void
SET search_path = public, extensions, pgmq, temp
AS $$
DECLARE
  pair RECORD;
BEGIN
  FOR pair IN
    SELECT
      mp.id AS match_pair_id,
      mp.event_id,
      mp.user_lower_id,
      mp.user_higher_id,
      e.title AS event_title
    FROM public.match_pairs mp
    JOIN public.events e ON e.id = mp.event_id
    WHERE mp.notification_sent = false
      AND e.vote_end_at IS NOT NULL
      AND e.vote_end_at < now() - interval '1 day'
  LOOP
    -- 양쪽 유저에게 알림 발송
    PERFORM public.fan_out_event('match_result', jsonb_build_object(
      'user_id', pair.user_lower_id,
      'event_id', pair.event_id,
      'event_title', COALESCE(pair.event_title, '이벤트')
    ));

    PERFORM public.fan_out_event('match_result', jsonb_build_object(
      'user_id', pair.user_higher_id,
      'event_id', pair.event_id,
      'event_title', COALESCE(pair.event_title, '이벤트')
    ));

    -- 알림 발송 플래그 설정
    UPDATE public.match_pairs
    SET notification_sent = true
    WHERE id = pair.match_pair_id;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE EXECUTE ON FUNCTION public.notify_match_results() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.notify_match_results() TO service_role;

-- ============================================================
-- 4. 투표 데이터 정리 함수
-- 이벤트 완료 + 30일 후 match_votes 삭제 (match_pairs는 영구 보관)
-- ============================================================

CREATE OR REPLACE FUNCTION public.cleanup_expired_match_votes()
RETURNS integer
SET search_path = public, extensions
AS $$
DECLARE
  deleted_count integer;
BEGIN
  DELETE FROM public.match_votes
  WHERE event_id IN (
    SELECT id FROM public.events
    WHERE vote_end_at IS NOT NULL
      AND vote_end_at < now() - interval '30 days'
  );

  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE EXECUTE ON FUNCTION public.cleanup_expired_match_votes() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cleanup_expired_match_votes() TO service_role;

-- ============================================================
-- 5. pg_cron 등록
-- ============================================================

-- 매칭 알림: 매일 09:00 KST (00:00 UTC)
SELECT cron.schedule(
  'notify-match-results',
  '0 0 * * *',
  $$SELECT public.notify_match_results()$$
);

-- 투표 데이터 정리: 매일 03:00 KST (18:00 UTC 전날)
SELECT cron.schedule(
  'cleanup-expired-match-votes',
  '0 18 * * *',
  $$SELECT public.cleanup_expired_match_votes()$$
);
