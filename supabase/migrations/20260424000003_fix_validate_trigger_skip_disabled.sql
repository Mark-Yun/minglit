-- Fix #1789: validate_retention_policy_legal_min 트리거 — enabled=false 행 예외 처리
--
-- enabled=false (skip_cleanup=true) 행은 process-pending-deletions EF 설정값 참조용
-- config 행으로, 실제 cleanup 파이프라인에서 실행되지 않는다.
-- 화이트리스트 legal_min_days 검증은 실제로 cleanup을 수행하는 enabled=true 행에만 적용한다.

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
