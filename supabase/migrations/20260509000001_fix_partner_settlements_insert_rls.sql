-- Fix #2322: partner_settlements RLS 위반 — INSERT 정책 누락 + NOT NULL 제약 완화
--
-- Root cause:
--   1. partner_settlements에 INSERT RLS 정책이 없어 upsertBankAccount() 첫 실행 시 42501 오류
--   2. biz_type/biz_name/biz_number/representative_name NOT NULL 제약이 은행 계좌만 upsert 시 차단
--
-- Fix:
--   1. INSERT 정책 추가 — SETTLEMENT_EDIT 권한 보유자만 자기 파트너 레코드 INSERT 가능
--   2. 비즈니스 정보 컬럼 nullable 허용 — 승인 트리거가 전체 정보를 채우지만,
--      계좌 정보만 먼저 저장하는 경우(예: 테스트/시드 파트너)도 허용

-- 1. INSERT 정책 추가
CREATE POLICY "settlement_insert"
  ON public.partner_settlements
  FOR INSERT
  WITH CHECK (public.has_partner_permission(partner_id, 'SETTLEMENT_EDIT'));

-- 2. biz 정보 컬럼 nullable — 승인 트리거는 항상 값을 채우므로 프로덕션 영향 없음
ALTER TABLE public.partner_settlements
  ALTER COLUMN biz_type   DROP NOT NULL,
  ALTER COLUMN biz_name   DROP NOT NULL,
  ALTER COLUMN biz_number DROP NOT NULL,
  ALTER COLUMN representative_name DROP NOT NULL;
