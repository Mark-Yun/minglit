-- Fix #809: CI/DI 레거시 평문 컬럼 제거
-- Phase 3 (최종): Phase 1(암호화 컬럼 추가) + Phase 2(EF 전환) 완료 후
-- 평문 ci, di 컬럼을 제거하여 평문 노출 경로를 완전히 차단한다.

-- ============================================================
-- 1. Safety check: 미마이그레이션 행 존재 여부 검증
-- ============================================================
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE ci IS NOT NULL AND ci_encrypted IS NULL
  ) THEN
    RAISE EXCEPTION 'Unmigrated rows exist — abort column drop. Run Phase 1 batch encryption first.';
  END IF;
END $$;

-- ============================================================
-- 2. Drop legacy plaintext columns
-- ============================================================
ALTER TABLE public.user_profiles DROP COLUMN IF EXISTS ci;
ALTER TABLE public.user_profiles DROP COLUMN IF EXISTS di;
