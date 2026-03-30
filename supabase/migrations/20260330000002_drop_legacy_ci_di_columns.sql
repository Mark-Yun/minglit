-- Fix #809: Phase 3 — 레거시 평문 ci, di 컬럼 제거
-- Phase 1(암호화 컬럼 추가 + 배치 암호화) → Phase 2(EF 전환) 완료 후,
-- 평문 컬럼을 제거하여 PII 노출 경로를 완전 차단한다.

-- ============================================================
-- 1. Safety check: 미암호화 행이 없는지 확인
-- ============================================================
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE ci IS NOT NULL AND ci_encrypted IS NULL
  ) THEN
    RAISE EXCEPTION 'Unmigrated rows exist (ci present but ci_encrypted NULL) — abort column drop';
  END IF;
END $$;

-- ============================================================
-- 2. Drop legacy plaintext columns
-- ============================================================
ALTER TABLE public.user_profiles DROP COLUMN ci;
ALTER TABLE public.user_profiles DROP COLUMN di;
