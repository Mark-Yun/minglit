-- feat #1789: process-pending-deletions 하드코딩 retention 상수 → admin.retention_policies 이관
--
-- 법/규정 기반 보존 기간을 코드가 아닌 DB에서 관리.
-- enabled=false: 자동 cleanup 파이프라인 대상이 아닌 EF 설정값 문서화 행.

INSERT INTO admin.retention_policies
  (id, kind, retention_days, legal_min_days, target, description, enabled)
VALUES
  (
    'deletion_grace',
    'db_table',
    7,
    7,
    '{"schema":"public","table":"user_profiles","ts_col":"deleted_at"}',
    '탈퇴 신청 후 처리 전 grace 기간 — process-pending-deletions cutoff',
    false
  ),
  (
    'blocked_di_records',
    'db_table',
    30,
    30,
    '{"schema":"public","table":"blocked_dis","ts_col":"created_at"}',
    'Fraud DI 차단 기록 보유 기간 — process-pending-deletions blockedUntil',
    false
  ),
  (
    'contract_retention',
    'db_table',
    1825,
    1825,
    '{"schema":"public","table":"event_applications","ts_col":"created_at","archived_record_type":"contract"}',
    '전자상거래법 §6 계약 기록 보존 5년 — archived_records contract 타입 retention_until',
    false
  ),
  (
    'payment_retention',
    'db_table',
    1825,
    1825,
    '{"schema":"public","table":"event_applications","ts_col":"created_at","archived_record_type":"payment"}',
    '전자상거래법 §6 결제 기록 보존 5년 — archived_records payment 타입 retention_until',
    false
  ),
  (
    'dispute_retention',
    'db_table',
    1095,
    1095,
    '{"schema":"public","table":"report_details","ts_col":"created_at","archived_record_type":"dispute"}',
    '전자금융거래법 §22 분쟁 기록 보존 3년 — archived_records dispute 타입 retention_until',
    false
  ),
  (
    'login_history_retention',
    'db_table',
    90,
    90,
    '{"schema":"public","table":"user_profiles","ts_col":"created_at","archived_record_type":"login"}',
    '개인정보보호법 §21 로그인 이력 보존 3개월 — archived_records login 타입 retention_until',
    false
  ),
  (
    'consent_retention',
    'db_table',
    730,
    730,
    '{"schema":"public","table":"user_consents","ts_col":"created_at","archived_record_type":"consent"}',
    '개인정보보호법 §21 동의 기록 보존 2년 — archived_records consent 타입 retention_until',
    false
  )
ON CONFLICT (id) DO NOTHING;
