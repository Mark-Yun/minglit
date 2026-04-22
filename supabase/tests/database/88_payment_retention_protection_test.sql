-- pgTAP tests for payment retention protection (feat #1704)
-- 전자상거래법 §6 — 결제 원본 테이블 5년 보호 메타 등록 검증
BEGIN;

SELECT plan(13);

-- 1. 3개 보호 레코드 존재 확인
SELECT ok(
  EXISTS (SELECT 1 FROM admin.retention_policies WHERE id = 'event_applications_payment'),
  'event_applications_payment policy exists'
);
SELECT ok(
  EXISTS (SELECT 1 FROM admin.retention_policies WHERE id = 'tickets_payment'),
  'tickets_payment policy exists'
);
SELECT ok(
  EXISTS (SELECT 1 FROM admin.retention_policies WHERE id = 'ticket_templates_payment'),
  'ticket_templates_payment policy exists'
);

-- 2. enabled = false 확인 (자동 파기 대상 아님)
SELECT ok(
  NOT (SELECT enabled FROM admin.retention_policies WHERE id = 'event_applications_payment'),
  'event_applications_payment is disabled (no auto-purge)'
);
SELECT ok(
  NOT (SELECT enabled FROM admin.retention_policies WHERE id = 'tickets_payment'),
  'tickets_payment is disabled (no auto-purge)'
);
SELECT ok(
  NOT (SELECT enabled FROM admin.retention_policies WHERE id = 'ticket_templates_payment'),
  'ticket_templates_payment is disabled (no auto-purge)'
);

-- 3. legal_min_days >= 1825 확인 (전자상거래법 §6 5년)
SELECT ok(
  (SELECT legal_min_days FROM admin.retention_policies WHERE id = 'event_applications_payment') >= 1825,
  'event_applications_payment legal_min_days >= 1825'
);
SELECT ok(
  (SELECT legal_min_days FROM admin.retention_policies WHERE id = 'tickets_payment') >= 1825,
  'tickets_payment legal_min_days >= 1825'
);
SELECT ok(
  (SELECT legal_min_days FROM admin.retention_policies WHERE id = 'ticket_templates_payment') >= 1825,
  'ticket_templates_payment legal_min_days >= 1825'
);

-- 4. retention_days >= legal_min_days 확인 (CHECK 제약 통과 보장)
SELECT ok(
  (SELECT retention_days FROM admin.retention_policies WHERE id = 'event_applications_payment')
    >= (SELECT legal_min_days FROM admin.retention_policies WHERE id = 'event_applications_payment'),
  'event_applications_payment retention_days >= legal_min_days'
);
SELECT ok(
  (SELECT retention_days FROM admin.retention_policies WHERE id = 'tickets_payment')
    >= (SELECT legal_min_days FROM admin.retention_policies WHERE id = 'tickets_payment'),
  'tickets_payment retention_days >= legal_min_days'
);
SELECT ok(
  (SELECT retention_days FROM admin.retention_policies WHERE id = 'ticket_templates_payment')
    >= (SELECT legal_min_days FROM admin.retention_policies WHERE id = 'ticket_templates_payment'),
  'ticket_templates_payment retention_days >= legal_min_days'
);

-- 5. CHECK 제약 `retention_above_legal_min` 동작 확인
--    retention_days < legal_min_days 인 레코드 삽입 시 예외 발생 검증
SELECT throws_ok(
  $$
    INSERT INTO admin.retention_policies
      (id, kind, retention_days, legal_min_days, target, enabled)
    VALUES (
      'test_check_violation',
      'db_table',
      100,
      1825,
      '{"schema":"public","table":"test","ts_col":"created_at"}',
      false
    )
  $$,
  '23514',
  NULL,
  'retention_above_legal_min CHECK rejects retention_days < legal_min_days'
);

SELECT * FROM finish();
ROLLBACK;
