-- feat #1704: 결제 레코드 원본 테이블 삭제 방어 (전자상거래법 §6 5년)
-- enabled=false: 자동 파기 대상 아님 (원본 유지)
-- legal_min_days=1825: 최소 5년 보관 강제 (전자상거래법 §6)

INSERT INTO admin.retention_policies
  (id, kind, retention_days, legal_min_days, target, enabled, description)
VALUES
  (
    'event_applications_payment',
    'db_table',
    1825,
    1825,
    '{"schema":"public","table":"event_applications","ts_col":"created_at"}',
    false,
    '전자상거래법 §6 — 결제/계약 기록 5년 보존. enabled=false: 자동 파기 없음, legal_min_days로 최소 기간 방어'
  ),
  (
    'tickets_payment',
    'db_table',
    1825,
    1825,
    '{"schema":"public","table":"tickets","ts_col":"created_at"}',
    false,
    '전자상거래법 §6 — 티켓/재화공급 기록 5년 보존. enabled=false: 자동 파기 없음'
  ),
  (
    'ticket_templates_payment',
    'db_table',
    1825,
    1825,
    '{"schema":"public","table":"ticket_templates","ts_col":"created_at"}',
    false,
    '전자상거래법 §6 — 티켓 템플릿 기록 5년 보존. enabled=false: 자동 파기 없음'
  )
ON CONFLICT (id) DO NOTHING;
