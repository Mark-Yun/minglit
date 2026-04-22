-- Migration: #1706 부정 이용 기록 1년 보관 정책 (PIPA §21, 개인정보처리방침)
--
-- 개인정보처리방침: "부정 이용 기록 1년 보관"
--
-- 대상 테이블 식별 결과:
--   1. report_details  — 신고 기록 (신고자/피신고자 정보), 1년 보존 → enabled
--   2. blocked_dis     — 기기 식별자 차단 목록, 30일 TTL 운영 중
--                        선언(1년)과 실제 TTL(30일) 불일치 → legal-reviewer 컨설트 필요
--                        enabled=false 로 등록해 추적만 수행
--
-- 제외 테이블:
--   social_interactions (block/report 타입) — 현재 상태(current state) 테이블.
--     이력이 아닌 현재 차단 상태만 저장. 삭제 시 차단 관계 자체가 해제됨.
--     부정 이용 "기록" 범주에 해당하지 않음.

-- ── 1. report_details: 신고 기록 1년 보존 ─────────────────────────────────────
-- 신고 접수 후 1년이 경과한 기록은 파기. (생성일 기준)
INSERT INTO admin.retention_policies (
  id,
  kind,
  retention_days,
  legal_min_days,
  target,
  enabled,
  description
) VALUES (
  'report_details_fraud_record',
  'db_table',
  365,
  365,
  jsonb_build_object(
    'schema', 'public',
    'table',  'report_details',
    'ts_col', 'created_at'
  ),
  true,
  '부정 이용 기록 1년 보관 — 개인정보처리방침 §F5: 신고 기록(report_details) 1년 후 파기'
);

-- ── 2. blocked_dis: 기기 식별자 차단 — 불일치로 인해 비활성 등록 ─────────────
-- blocked_until TTL 30일 운영 중이나 개인정보처리방침은 1년 보관 선언.
-- cleanup-blocked-dis EF가 blocked_until < now() 행을 매일 삭제하므로
-- 1년 보존 약속과 충돌. legal-reviewer 판단 전 enabled=false로 추적만 수행.
INSERT INTO admin.retention_policies (
  id,
  kind,
  retention_days,
  legal_min_days,
  target,
  enabled,
  description,
  metadata
) VALUES (
  'blocked_dis_fraud_record',
  'db_table',
  365,
  NULL,
  jsonb_build_object(
    'schema', 'public',
    'table',  'blocked_dis',
    'ts_col', 'created_at'
  ),
  false,
  '부정 이용 기록 1년 보관 — blocked_dis: TTL 불일치로 비활성 (legal-reviewer 컨설트 필요)',
  jsonb_build_object(
    'conflict', 'blocked_until TTL=30일 vs 개인정보처리방침 선언=1년 불일치',
    'existing_cleanup', 'cleanup-blocked-dis EF가 blocked_until < now() 삭제 중',
    'action_required', 'legal-reviewer가 방침 개정(30일로 단축) 또는 TTL 연장(1년) 결정 필요',
    'issue', 1706
  )
);
