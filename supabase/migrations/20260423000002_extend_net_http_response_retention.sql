-- Fix #1759: net._http_response retention 연장
-- dev: 1일 → 7일, main: 7일 → 14일
-- 이유: #1758 디버깅 시 24시간 이내 cleanup으로 로그 소실 → drift 재발 시 원인 추적 난항

UPDATE admin.retention_policies
SET retention_days = 14
WHERE id = 'net_http_response';

-- Fix #1759: migration-time assertion — seed.sql은 이 값을 7로 덮어쓰므로
-- pgTAP에서 14를 검증할 수 없음. migration 자체에서 즉시 단언.
DO $$
BEGIN
  ASSERT (
    SELECT retention_days FROM admin.retention_policies WHERE id = 'net_http_response'
  ) = 14,
    'net_http_response retention_days must be 14 after Fix #1759 migration';
END;
$$;
