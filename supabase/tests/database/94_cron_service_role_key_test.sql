-- Fix #1758/#2187: pg_cron 모든 HTTP EF 호출이 service_role_key를 사용하고,
-- legacy JWT / sb_secret_ 모두 호환되도록 Authorization + apikey 헤더를 함께 보내는지 검증
-- publishable_key(anon JWT) 사용 시 requireServiceRole() 가드에서 401 반환

BEGIN;
-- Fix #2647: plan(8) → plan(7) — backend-simulation cron 제거됨
-- (20260517000002_rename_backend_simulator_to_event_flow_simulator.sql)
-- Fix #2187: plan(7) → plan(8) — analytics.call_metrics_alert도 sb_secret 호환 검증
SELECT plan(8);

-- Helper: 특정 cron job의 headers가 service_role_key를 apikey + Authorization 양쪽에 참조하는지 확인
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
  RETURN v_command LIKE '%service_role_key%'
    AND v_command NOT LIKE '%publishable_key%'
    AND v_command LIKE '%''apikey''%'
    AND v_command LIKE '%''Authorization''%';
END;
$$;

CREATE OR REPLACE FUNCTION _check_metrics_alert_helper_uses_service_role()
RETURNS boolean
LANGUAGE plpgsql AS $$
DECLARE
  v_definition text;
BEGIN
  SELECT pg_get_functiondef('analytics.call_metrics_alert(text,text,text)'::regprocedure)
    INTO v_definition;

  RETURN v_definition LIKE '%service_role_key%'
    AND v_definition NOT LIKE '%publishable_key%'
    AND v_definition LIKE '%''apikey''%'
    AND v_definition LIKE '%''Authorization''%';
END;
$$;

-- 1. process-notifications: service_role_key 사용
SELECT ok(
  _check_cron_uses_service_role('process-notifications'),
  'process-notifications cron uses service_role_key with apikey + Authorization'
);

-- 2. settlement-reconciliation-daily: service_role_key 사용
SELECT ok(
  _check_cron_uses_service_role('settlement-reconciliation-daily'),
  'settlement-reconciliation-daily cron uses service_role_key with apikey + Authorization'
);

-- 3. settlement-register-transfers: service_role_key 사용
SELECT ok(
  _check_cron_uses_service_role('settlement-register-transfers'),
  'settlement-register-transfers cron uses service_role_key with apikey + Authorization'
);

-- 4. settlement-payout-sync: service_role_key 사용
SELECT ok(
  _check_cron_uses_service_role('settlement-payout-sync'),
  'settlement-payout-sync cron uses service_role_key with apikey + Authorization'
);

-- 5. settlement-alarm-check: service_role_key 사용
SELECT ok(
  _check_cron_uses_service_role('settlement-alarm-check'),
  'settlement-alarm-check cron uses service_role_key with apikey + Authorization'
);

-- 6. ai-extract-tags: service_role_key 사용
SELECT ok(
  _check_cron_uses_service_role('ai-extract-tags'),
  'ai-extract-tags cron uses service_role_key with apikey + Authorization'
);

-- 7. sync_github_stats: service_role_key 사용
SELECT ok(
  _check_cron_uses_service_role('sync_github_stats'),
  'sync_github_stats cron uses service_role_key with apikey + Authorization'
);

-- 8. analytics.call_metrics_alert helper: service_role_key 사용
SELECT ok(
  _check_metrics_alert_helper_uses_service_role(),
  'analytics.call_metrics_alert uses service_role_key with apikey + Authorization'
);

SELECT * FROM finish();
ROLLBACK;
