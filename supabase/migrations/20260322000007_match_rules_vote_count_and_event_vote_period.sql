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
