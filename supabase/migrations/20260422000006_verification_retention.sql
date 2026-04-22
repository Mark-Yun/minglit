-- Migration: #1707 Part 1 — db_custom_fn 열거형 추가 (PIPA §21 자격 인증 증빙 보관)
--
-- PostgreSQL에서 ALTER TYPE ... ADD VALUE는 같은 트랜잭션 내에서 새 값을 사용할 수 없다
-- (SQLSTATE 55P04: unsafe_new_enum_value_usage).
-- 이 마이그레이션은 enum 추가만 커밋하고, 실제 정책 등록은 000007에서 수행한다.
--
-- IF NOT EXISTS: PR #1705(event_participants) 와 병행 머지 가능 — 중복 추가 무해.

ALTER TYPE admin.retention_kind ADD VALUE IF NOT EXISTS 'db_custom_fn';
