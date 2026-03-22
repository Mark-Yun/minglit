-- Issue #305: match_rules에 vote_count 추가 + events에 투표 기간 컬럼 추가

-- 1. match_rules: 그룹별 투표 수 제한
ALTER TABLE public.match_rules
  ADD COLUMN vote_count integer NOT NULL DEFAULT 1;

-- vote_count >= 1 제약
ALTER TABLE public.match_rules
  ADD CONSTRAINT match_rules_vote_count_positive CHECK (vote_count >= 1);

-- 2. events: 투표 기간 설정
ALTER TABLE public.events
  ADD COLUMN vote_start_at timestamptz,
  ADD COLUMN vote_end_at timestamptz;

-- 3. replace_match_rules RPC — 원자적 delete + insert
CREATE OR REPLACE FUNCTION public.replace_match_rules(
  p_event_id uuid,
  p_rules jsonb DEFAULT '[]'::jsonb
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  rule_count integer;
BEGIN
  -- Advisory lock on event_id to serialize concurrent calls
  PERFORM pg_advisory_xact_lock(hashtext(p_event_id::text));

  DELETE FROM public.match_rules WHERE event_id = p_event_id;

  IF jsonb_array_length(p_rules) > 0 THEN
    INSERT INTO public.match_rules (event_id, source_group_id, target_group_id, vote_count)
    SELECT
      p_event_id,
      (r->>'source_group_id')::uuid,
      (r->>'target_group_id')::uuid,
      COALESCE((r->>'vote_count')::integer, 1)
    FROM jsonb_array_elements(p_rules) AS r;
  END IF;

  GET DIAGNOSTICS rule_count = ROW_COUNT;
  RETURN rule_count;
END;
$$;
