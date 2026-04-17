-- Fix #1511: Re-apply 'draft' enum value for partner_application_status.
--
-- The original migration (20260307000001) was recorded as applied by the CLI
-- but ALTER TYPE ADD VALUE failed inside a transaction block, leaving the
-- 'draft' value absent from the live enum. IF NOT EXISTS makes this idempotent.
--
-- NOTE: ALTER TYPE ADD VALUE cannot run inside a transaction block.
ALTER TYPE public.partner_application_status ADD VALUE IF NOT EXISTS 'draft';
