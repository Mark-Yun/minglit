-- feat #1789: retention_policies 달력 기준 보존 단위 컬럼 추가
-- retention_days 고정 일수로 평탄화하면 윤년·월말 경계에서 법정 최소 보존기간이
-- 실제보다 짧아지는 회귀가 발생한다. 달력 기준 컬럼(value + unit)을 추가해
-- process-pending-deletions EF가 addYears/addMonths 기준으로 계산하도록 한다.

ALTER TABLE admin.retention_policies
  ADD COLUMN retention_calendar_value int
    CHECK (retention_calendar_value IS NULL OR retention_calendar_value > 0),
  ADD COLUMN retention_calendar_unit text
    CHECK (retention_calendar_unit IN ('year', 'month', 'day'));

-- 두 컬럼은 함께 설정되거나 함께 NULL이어야 한다
ALTER TABLE admin.retention_policies
  ADD CONSTRAINT retention_calendar_unit_pair_check
    CHECK (
      (retention_calendar_value IS NULL) = (retention_calendar_unit IS NULL)
    );

-- 법적 보존 기간 항목에 달력 단위 설정
UPDATE admin.retention_policies
SET retention_calendar_value = 5, retention_calendar_unit = 'year'
WHERE id IN ('contract_retention', 'payment_retention');

UPDATE admin.retention_policies
SET retention_calendar_value = 3, retention_calendar_unit = 'year'
WHERE id = 'dispute_retention';

UPDATE admin.retention_policies
SET retention_calendar_value = 3, retention_calendar_unit = 'month'
WHERE id = 'login_history_retention';

UPDATE admin.retention_policies
SET retention_calendar_value = 2, retention_calendar_unit = 'year'
WHERE id = 'consent_retention';
