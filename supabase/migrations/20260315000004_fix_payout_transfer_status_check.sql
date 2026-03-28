-- Fix #Phase4: Ensure payout_transfers status CHECK constraint is explicit
ALTER TABLE public.payout_transfers DROP CONSTRAINT IF EXISTS payout_transfers_status_check;
ALTER TABLE public.payout_transfers ADD CONSTRAINT payout_transfers_status_check
  CHECK (status IN ('CREATED','REQUESTED','SUCCEEDED','FAILED'));
