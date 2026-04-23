-- Fix #1759: net._http_response retention 연장
-- dev: 1일 → 7일, main: 7일 → 14일
-- 이유: #1758 디버깅 시 24시간 이내 cleanup으로 로그 소실 → drift 재발 시 원인 추적 난항

UPDATE admin.retention_policies
SET retention_days = 14
WHERE id = 'net_http_response';
