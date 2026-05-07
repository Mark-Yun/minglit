-- Fix #2099: Extend event_applications and verification_submissions schema
-- event_applications: refunded_at (환불 처리 시점), cancellation_reason (취소 사유)
-- verification_submissions: review_started_at (심사 시작 시점)

-- event_applications
ALTER TABLE public.event_applications
  ADD COLUMN IF NOT EXISTS refunded_at         timestamptz,
  ADD COLUMN IF NOT EXISTS cancellation_reason text;

COMMENT ON COLUMN public.event_applications.refunded_at IS
  '환불 처리 시점 — PurchaseHistoryDetailPage 환불 카드 "환불일" 표시용';

COMMENT ON COLUMN public.event_applications.cancellation_reason IS
  '취소 사유 — system vs user 구분 ("system:..." prefix 또는 그냥 text). EventApplicationReviewPage ReasonBox 라벨 분기용';

-- verification_submissions
ALTER TABLE public.verification_submissions
  ADD COLUMN IF NOT EXISTS review_started_at timestamptz;

COMMENT ON COLUMN public.verification_submissions.review_started_at IS
  '심사 진행 시작 시점 — review page timeline "심사 진행 중" step time 표시용. reviewed_at은 종료 시점만 기록함';
