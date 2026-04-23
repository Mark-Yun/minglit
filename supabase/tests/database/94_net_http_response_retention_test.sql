-- Fix #1759: net._http_response retention 연장 — 값 고정 검증
-- main: 7일 → 14일, dev(seed): 1일 → 7일
-- 이 테스트는 dev 환경(seed.sql 적용 후)에서 실행 → 7일 값 검증
-- drift 재발 시 CI에서 즉시 감지

BEGIN;
SELECT plan(4);

-- 1. net_http_response 정책 존재 확인
SELECT ok(
  EXISTS(
    SELECT 1 FROM admin.retention_policies
    WHERE id = 'net_http_response'
  ),
  'net_http_response retention policy exists'
);

-- 2. 정책이 활성화 상태
SELECT ok(
  (SELECT enabled FROM admin.retention_policies WHERE id = 'net_http_response') = true,
  'net_http_response retention policy is enabled'
);

-- 3. dev 환경(seed override): retention_days = 7
-- seed.sql이 적용된 dev/test 환경에서 7일로 설정되는지 검증
SELECT ok(
  (SELECT retention_days FROM admin.retention_policies WHERE id = 'net_http_response') = 7,
  'net_http_response retention_days = 7 in dev environment (seed override)'
);

-- 4. retention_days >= 7 (최솟값 보장 — main에서는 14, dev에서는 7)
SELECT ok(
  (SELECT retention_days FROM admin.retention_policies WHERE id = 'net_http_response') >= 7,
  'net_http_response retention_days >= 7 (min window for debugging)'
);

SELECT * FROM finish();
ROLLBACK;
