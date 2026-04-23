-- feat #1789: process-pending-deletions 하드코딩 retention 상수 → admin.retention_policies 이관
--
-- 법/규정 기반 보존 기간을 코드가 아닌 DB에서 관리.
-- enabled=false + metadata.skip_cleanup=true:
--   이 행들은 process-pending-deletions EF의 설정값 참조용 config 행이다.
--   cleanup-retention 파이프라인의 실행 대상이 아니며, enabled=true로 변경해도
--   cleanup-retention이 skip_cleanup 플래그를 검사하여 실행하지 않는다.
--   archived_records의 실제 파기는 'archived_records_expired' 정책(migration 20260422000002)이 담당한다.

-- validate_retention_policy_legal_min 트리거 수정 (fix #1789):
-- enabled=false config 행은 cleanup 실행 대상이 아니므로 whitelist legal_min_days 검증 생략.
-- dispute(1095d), login(90d), consent(730d) config 행이 archived_records(legal_min=1825)를
-- 대상으로 지정 시 트리거 차단을 우회하기 위함.
-- enabled=true 행은 기존대로 검증이 적용된다.
CREATE OR REPLACE FUNCTION admin.validate_retention_policy_legal_min()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  min_days int;
BEGIN
  -- enabled=false 행은 cleanup 대상이 아니므로 whitelist 검증 생략
  IF NEW.enabled = false THEN
    RETURN NEW;
  END IF;

  IF NEW.kind = 'db_table' THEN
    SELECT legal_min_days INTO min_days
      FROM admin.retention_allowed_targets
      WHERE schema_name = NEW.target->>'schema'
        AND table_name  = NEW.target->>'table';
    IF min_days IS NOT NULL AND NEW.retention_days < min_days THEN
      RAISE EXCEPTION
        'retention_days (%) below table legal_min_days (%) for %.%',
        NEW.retention_days, min_days,
        NEW.target->>'schema', NEW.target->>'table'
        USING ERRCODE = 'check_violation';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

INSERT INTO admin.retention_policies
  (id, kind, retention_days, legal_min_days, target, description, enabled, metadata)
VALUES
  (
    'deletion_grace',
    'db_table',
    7,
    7,
    '{"schema":"public","table":"user_profiles","ts_col":"deleted_at"}',
    '탈퇴 신청 후 처리 전 grace 기간 — process-pending-deletions cutoff (config only)',
    false,
    '{"skip_cleanup":true}'
  ),
  (
    'blocked_di_records',
    'db_table',
    30,
    30,
    '{"schema":"public","table":"blocked_dis","ts_col":"created_at"}',
    'Fraud DI 차단 기록 보유 기간 — process-pending-deletions blockedUntil (config only)',
    false,
    '{"skip_cleanup":true}'
  ),
  (
    'contract_retention',
    'db_table',
    1825,
    1825,
    '{"schema":"public","table":"archived_records","ts_col":"retention_until","record_type":"contract","use_absolute_ts":true}',
    '전자상거래법 §6 계약 기록 보존 5년 — archived_records contract 타입 retention_until 계산 기준 (config only)',
    false,
    '{"skip_cleanup":true}'
  ),
  (
    'payment_retention',
    'db_table',
    1825,
    1825,
    '{"schema":"public","table":"archived_records","ts_col":"retention_until","record_type":"payment","use_absolute_ts":true}',
    '전자상거래법 §6 결제 기록 보존 5년 — archived_records payment 타입 retention_until 계산 기준 (config only)',
    false,
    '{"skip_cleanup":true}'
  ),
  (
    'dispute_retention',
    'db_table',
    1095,
    1095,
    '{"schema":"public","table":"archived_records","ts_col":"retention_until","record_type":"dispute","use_absolute_ts":true}',
    '전자금융거래법 §22 분쟁 기록 보존 3년 — archived_records dispute 타입 retention_until 계산 기준 (config only)',
    false,
    '{"skip_cleanup":true}'
  ),
  (
    'login_history_retention',
    'db_table',
    90,
    90,
    '{"schema":"public","table":"archived_records","ts_col":"retention_until","record_type":"login","use_absolute_ts":true}',
    '개인정보보호법 §21 로그인 이력 보존 3개월 — archived_records login 타입 retention_until 계산 기준 (config only)',
    false,
    '{"skip_cleanup":true}'
  ),
  (
    'consent_retention',
    'db_table',
    730,
    730,
    '{"schema":"public","table":"archived_records","ts_col":"retention_until","record_type":"consent","use_absolute_ts":true}',
    '개인정보보호법 §21 동의 기록 보존 2년 — archived_records consent 타입 retention_until 계산 기준 (config only)',
    false,
    '{"skip_cleanup":true}'
  )
ON CONFLICT (id) DO NOTHING;
