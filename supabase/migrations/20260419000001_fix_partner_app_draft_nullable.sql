-- Fix #1599: Re-apply DROP NOT NULL for partner_applications draft columns.
--
-- 20260307000002 ran ALTER COLUMN ... DROP NOT NULL inside a transaction block.
-- On the live dev DB the statements were recorded as applied but the constraint
-- was never lifted (identical symptom to the 'draft' enum in #1511).
-- Running DROP NOT NULL on an already-nullable column is a PostgreSQL no-op,
-- so this migration is idempotent and safe to apply on any environment.

ALTER TABLE public.partner_applications
  ALTER COLUMN brand_name        DROP NOT NULL,
  ALTER COLUMN biz_type          DROP NOT NULL,
  ALTER COLUMN biz_name          DROP NOT NULL,
  ALTER COLUMN biz_number        DROP NOT NULL,
  ALTER COLUMN representative_name DROP NOT NULL,
  ALTER COLUMN bank_name         DROP NOT NULL,
  ALTER COLUMN account_number    DROP NOT NULL,
  ALTER COLUMN account_holder    DROP NOT NULL,
  ALTER COLUMN biz_registration_path DROP NOT NULL,
  ALTER COLUMN bankbook_path     DROP NOT NULL;
