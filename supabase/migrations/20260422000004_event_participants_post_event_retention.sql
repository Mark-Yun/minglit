-- Migration: #1705 Part 1 — event_participants 스키마 변경 (PIPA §21)
--
-- PostgreSQL에서 ALTER TYPE ... ADD VALUE는 같은 트랜잭션 내에서 새 값을 사용할 수 없다
-- (SQLSTATE 55P04: unsafe_new_enum_value_usage).
-- 이 마이그레이션은 스키마/enum 변경만 커밋하고, 함수·정책 등록은 000009에서 수행한다.
--
-- IF NOT EXISTS: PR #1707(verification_retention)의 000006과 병행 머지 가능.

-- user_id NOT NULL 제약 해제: 이벤트 종료 30일 후 NULL화 허용.
-- FK(user_profiles)는 NULL 값에는 적용되지 않으므로 참조 무결성에 영향 없음.
-- UNIQUE(event_id, user_id)는 PostgreSQL에서 NULL 여러 개를 허용함(NULL ≠ NULL).
ALTER TABLE public.event_participants ALTER COLUMN user_id DROP NOT NULL;

-- db_custom_fn: events.end_time 기준 JOIN 등 단순 timestamp 비교 외 커스텀 로직에 사용.
ALTER TYPE admin.retention_kind ADD VALUE IF NOT EXISTS 'db_custom_fn';
