-- Fix #1758: pg_cron 모든 HTTP EF 호출이 service_role_key를 사용하는지 검증
-- publishable_key(anon JWT) 사용 시 requireServiceRole() 가드에서 401 반환

BEGIN;
SELECT plan(8);

-- Helper: 특정 cron job의 Authorization 헤더가 service_role_key를 참조하는지 확인
CREATE OR REPLACE FUNCTION _check_cron_uses_service_role(p_jobname text)
RETURNS boolean
LANGUAGE plpgsql AS $$
DECLARE
  v_command text;
BEGIN
  SELECT command INTO v_command FROM cron.job WHERE jobname = p_jobname;
  IF v_command IS NULL THEN
    RETURN false;
  END IF;
  RETURN v_command LIKE '%service_role_key%' AND v_command NOT LIKE '%publishable_key%';
END;
$$;

-- 1. backend-simulation: service_role_key 사용
SELECT ok(
  _check_cron_uses_service_role('backend-simulation'),
  'backend-simulation cron uses service_role_key (not publishable_key)'
);

-- 2. process-notifications: service_role_key 사용
SELECT ok(
  _check_cron_uses_service_role('process-notifications'),
  'process-notifications cron uses service_role_key (not publishable_key)'
);

-- 3. settlement-reconciliation-daily: service_role_key 사용
SELECT ok(
  _check_cron_uses_service_role('settlement-reconciliation-daily'),
  'settlement-reconciliation-daily cron uses service_role_key (not publishable_key)'
);

-- 4. settlement-register-transfers: service_role_key 사용
SELECT ok(
  _check_cron_uses_service_role('settlement-register-transfers'),
  'settlement-register-transfers cron uses service_role_key (not publishable_key)'
);

-- 5. settlement-payout-sync: service_role_key 사용
SELECT ok(
  _check_cron_uses_service_role('settlement-payout-sync'),
  'settlement-payout-sync cron uses service_role_key (not publishable_key)'
);

-- 6. settlement-alarm-check: service_role_key 사용
SELECT ok(
  _check_cron_uses_service_role('settlement-alarm-check'),
  'settlement-alarm-check cron uses service_role_key (not publishable_key)'
);

-- 7. ai-extract-tags: service_role_key 사용
SELECT ok(
  _check_cron_uses_service_role('ai-extract-tags'),
  'ai-extract-tags cron uses service_role_key (not publishable_key)'
);

-- 8. sync_github_stats: service_role_key 사용
SELECT ok(
  _check_cron_uses_service_role('sync_github_stats'),
  'sync_github_stats cron uses service_role_key (not publishable_key)'
);

SELECT * FROM finish();
ROLLBACK;
