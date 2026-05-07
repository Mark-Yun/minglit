-- Issue #2206: Batch commit RPC for event matching likes

SET search_path = public, extensions, pgmq, temp;

CREATE OR REPLACE FUNCTION public.commit_match_likes(
  p_event_id uuid,
  p_voter_id uuid,
  p_candidate_ids uuid[],
  p_max_vote_count integer
)
RETURNS TABLE(inserted_count integer, duplicate_count integer)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_count integer;
  new_unique_count integer;
  requested_unique_count integer;
  max_likes_per_commit CONSTANT integer := 3;
BEGIN
  PERFORM pg_advisory_xact_lock(
    hashtext(p_event_id::text || ':' || p_voter_id::text)
  );

  WITH normalized_candidates AS (
    SELECT DISTINCT candidate_id
    FROM unnest(p_candidate_ids) AS candidate_id
    WHERE candidate_id IS NOT NULL
  )
  SELECT count(*) INTO requested_unique_count
  FROM normalized_candidates;

  IF requested_unique_count = 0 THEN
    RAISE EXCEPTION '좋아요를 보낼 상대를 선택해 주세요'
      USING ERRCODE = 'P0001';
  END IF;

  IF requested_unique_count > max_likes_per_commit THEN
    RAISE EXCEPTION '좋아요는 최대 3명까지 보낼 수 있습니다'
      USING ERRCODE = 'P0001';
  END IF;

  SELECT count(*) INTO current_count
  FROM public.match_votes
  WHERE event_id = p_event_id
    AND voter_id = p_voter_id;

  WITH normalized_candidates AS (
    SELECT DISTINCT candidate_id
    FROM unnest(p_candidate_ids) AS candidate_id
    WHERE candidate_id IS NOT NULL
  )
  SELECT count(*) INTO new_unique_count
  FROM normalized_candidates nc
  WHERE NOT EXISTS (
    SELECT 1
    FROM public.match_votes mv
    WHERE mv.event_id = p_event_id
      AND mv.voter_id = p_voter_id
      AND mv.candidate_id = nc.candidate_id
  );

  IF current_count + new_unique_count > p_max_vote_count THEN
    RAISE EXCEPTION '좋아요 수를 초과했습니다'
      USING ERRCODE = 'P0001';
  END IF;

  WITH normalized_candidates AS (
    SELECT DISTINCT candidate_id
    FROM unnest(p_candidate_ids) AS candidate_id
    WHERE candidate_id IS NOT NULL
  )
  INSERT INTO public.match_votes (event_id, voter_id, candidate_id)
  SELECT p_event_id, p_voter_id, nc.candidate_id
  FROM normalized_candidates nc
  ON CONFLICT DO NOTHING;

  GET DIAGNOSTICS inserted_count = ROW_COUNT;
  duplicate_count := GREATEST(requested_unique_count - inserted_count, 0);

  RETURN QUERY
  SELECT inserted_count, duplicate_count;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.commit_match_likes(uuid, uuid, uuid[], integer) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.commit_match_likes(uuid, uuid, uuid[], integer) TO service_role;
