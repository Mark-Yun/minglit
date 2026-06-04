-- Issue #3047: Partner bank account onboarding verification state.
-- Existing account rows were previously treated as complete after a plain upsert.
-- Backfill them as manual_review_approved to avoid re-opening onboarding todos.

ALTER TABLE public.partner_settlements
  ADD COLUMN IF NOT EXISTS bank_code text,
  ADD COLUMN IF NOT EXISTS bank_verification_status text NOT NULL DEFAULT 'not_started',
  ADD COLUMN IF NOT EXISTS bank_verification_reason text,
  ADD COLUMN IF NOT EXISTS bank_verification_requested_at timestamptz,
  ADD COLUMN IF NOT EXISTS bank_verified_at timestamptz;

ALTER TABLE public.partner_settlements
  DROP CONSTRAINT IF EXISTS partner_settlements_bank_verification_status_check;

ALTER TABLE public.partner_settlements
  ADD CONSTRAINT partner_settlements_bank_verification_status_check
  CHECK (
    bank_verification_status IN (
      'not_started',
      'verification_failed',
      'manual_review_pending',
      'manual_review_approved',
      'verified'
    )
  );

UPDATE public.partner_settlements
SET
  bank_verification_status = 'manual_review_approved',
  bank_verification_reason = COALESCE(
    bank_verification_reason,
    'legacy_account_backfill'
  ),
  bank_verified_at = COALESCE(bank_verified_at, updated_at, now())
WHERE bank_name IS NOT NULL
  AND account_number IS NOT NULL
  AND account_holder IS NOT NULL
  AND bank_verification_status = 'not_started';

CREATE INDEX IF NOT EXISTS partner_settlements_bank_verification_status_idx
  ON public.partner_settlements(bank_verification_status);
