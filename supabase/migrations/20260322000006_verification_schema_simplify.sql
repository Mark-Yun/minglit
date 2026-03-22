-- Migration: Simplify verification schema for EF transition
-- Related: #301 (user-update-verification + user-submit-verification)
--
-- 1. Reduce verification_status enum: pending, approved, rejected (drop needs_correction, cancelled)
-- 2. Drop verification_comments table (data migrated into snapshot_data JSON)
-- 3. Remove admin_comment column from verification_submissions (replaced by JSON comments)
-- 4. Update trigger to remove needs_correction reference

-- ============================================================
-- 1. Enum reduction: verification_status → 3 values
-- ============================================================
-- PostgreSQL doesn't support DROP VALUE from enum, so we recreate it.

-- 1a. Create new enum
CREATE TYPE public.verification_status_new AS ENUM ('pending', 'approved', 'rejected');

-- 1b. Alter columns using old enum → text → new enum
ALTER TABLE public.verification_submissions
  ALTER COLUMN status DROP DEFAULT,
  ALTER COLUMN status TYPE public.verification_status_new
    USING status::text::public.verification_status_new,
  ALTER COLUMN status SET DEFAULT 'pending'::public.verification_status_new;

-- 1c. Drop old enum and rename
DROP TYPE public.verification_status;
ALTER TYPE public.verification_status_new RENAME TO verification_status;

-- ============================================================
-- 2. Drop verification_comments table + RLS policies
-- ============================================================
-- Policies are dropped automatically with the table.
DROP TABLE IF EXISTS public.verification_comments;

-- Revoke grants (no-op if table already dropped, but explicit for clarity)
-- REVOKE ALL ON public.verification_comments FROM authenticated;

-- ============================================================
-- 3. Remove admin_comment column (replaced by snapshot_data JSON comments)
-- ============================================================
ALTER TABLE public.verification_submissions DROP COLUMN IF EXISTS admin_comment;

-- ============================================================
-- 4. Update trigger function: remove needs_correction from IN list
-- ============================================================
CREATE OR REPLACE FUNCTION public.trigger_produce_event_verification()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pgmq, temp
AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND (OLD.status IS DISTINCT FROM NEW.status) THEN
    IF NEW.status IN ('approved', 'rejected') THEN
      PERFORM public.produce_event(
        'verification_result'::public.event_type_name,
        'verification_submissions',
        NEW.id,
        row_to_json(NEW)::jsonb
      );
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

-- ============================================================
-- 5. Revoke write grants on user_verifications (writes go through EF now)
-- ============================================================
-- Keep SELECT only for authenticated users
REVOKE INSERT, UPDATE, DELETE ON public.user_verifications FROM authenticated;

-- ============================================================
-- 6. Update RLS: user_verifications → read-only for clients
-- ============================================================
DROP POLICY IF EXISTS "Users can read/write own verifications" ON public.user_verifications;
CREATE POLICY "Users can read own verifications" ON public.user_verifications
  FOR SELECT USING (auth.uid() = user_id);
