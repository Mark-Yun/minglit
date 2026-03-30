-- Issue #306: event_type_name enum에 match_result 값 추가
-- ALTER TYPE ADD VALUE는 별도 트랜잭션에서 실행해야 하므로 분리된 migration

ALTER TYPE public.event_type_name ADD VALUE IF NOT EXISTS 'match_result';
