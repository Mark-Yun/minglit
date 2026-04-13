-- Fix #1420: enum ADD VALUE는 트랜잭션 블록 밖에서 실행해야 함
-- DO $$ 블록 안에서 ALTER TYPE ADD VALUE를 실행하면 트랜잭션 내에서
-- 새 enum 값을 즉시 사용할 수 없어 "unsafe use of new value" 에러 발생.
-- 기존 패턴(20260322000008_add_match_result_enum.sql) 처럼 직접 실행.

set search_path to public, extensions;

ALTER TYPE public.event_queue_name ADD VALUE IF NOT EXISTS 'q_tags';
