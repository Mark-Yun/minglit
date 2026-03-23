-- Issue #306: 원자적 투표 RPC + 매칭 결과 알림 + 투표 데이터 정리 크론잡

SET search_path = public, extensions, pgmq, temp;

-- ============================================================
-- 1. 원자적 투표 RPC (race condition 방지)
-- advisory lock으로 동일 voter의 동시 투표를 직렬화
-- ============================================================

CREATE OR REPLACE FUNCTION public.cast_match_vote(
  p_event_id uuid,
  p_voter_id uuid,
  p_candidate_id uuid,
  p_max_vote_count integer
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_count integer;
BEGIN
  -- Advisory lock on voter+event to serialize concurrent votes
  PERFORM pg_advisory_xact_lock(
    hashtext(p_event_id::text || ':' || p_voter_id::text)
  );

  -- Check current vote count
  SELECT count(*) INTO current_count
  FROM public.match_votes
  WHERE event_id = p_event_id AND voter_id = p_voter_id;

  IF current_count >= p_max_vote_count THEN
    RAISE EXCEPTION '투표 수를 초과했습니다'
      USING ERRCODE = 'P0001';
  END IF;

  -- Check duplicate vote
  IF EXISTS (
    SELECT 1 FROM public.match_votes
    WHERE event_id = p_event_id
      AND voter_id = p_voter_id
      AND candidate_id = p_candidate_id
  ) THEN
    RAISE EXCEPTION '이미 투표한 후보입니다'
      USING ERRCODE = 'P0002';
  END IF;

  -- Insert vote (trigger handles match_pairs creation)
  INSERT INTO public.match_votes (event_id, voter_id, candidate_id)
  VALUES (p_event_id, p_voter_id, p_candidate_id);
END;
$$;

REVOKE EXECUTE ON FUNCTION public.cast_match_vote(uuid, uuid, uuid, integer) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cast_match_vote(uuid, uuid, uuid, integer) TO service_role;

-- ============================================================
-- 2. match_pairs에 알림 발송 여부 플래그 추가
-- ============================================================

ALTER TABLE public.match_pairs
  ADD COLUMN notification_sent boolean NOT NULL DEFAULT false;

-- ============================================================
-- 3. event_type_name enum에 match_result 추가 + event_routes 등록
-- ============================================================

ALTER TYPE public.event_type_name ADD VALUE IF NOT EXISTS 'match_result';

INSERT INTO public.event_routes (event_type, target_queue, is_active) VALUES
  ('match_result', 'q_notifications', true)
ON CONFLICT (event_type, target_queue) DO UPDATE SET is_active = EXCLUDED.is_active;

-- ============================================================
-- 4. 매칭 결과 알림 함수 (FOR UPDATE SKIP LOCKED으로 중복 방지)
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
    FOR UPDATE OF mp SKIP LOCKED
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
-- 5. 투표 데이터 정리 함수
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
-- 6. pg_cron 등록
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
