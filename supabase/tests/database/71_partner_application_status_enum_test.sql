-- Regression test for Fix #1511:
-- Ensures all expected partner_application_status enum labels exist.
-- The 'draft' value was absent from the live DB because ALTER TYPE ADD VALUE
-- silently failed inside a transaction in the original migration (20260307000001).

BEGIN;
SELECT plan(6);

SELECT has_type('public', 'partner_application_status',
  'enum partner_application_status should exist');

SELECT ok(
  EXISTS(
    SELECT 1 FROM pg_enum
    WHERE enumlabel = 'draft'
      AND enumtypid = 'public.partner_application_status'::regtype
  ),
  'partner_application_status must include draft (regression: #1511)'
);

SELECT ok(
  EXISTS(
    SELECT 1 FROM pg_enum
    WHERE enumlabel = 'pending'
      AND enumtypid = 'public.partner_application_status'::regtype
  ),
  'partner_application_status must include pending'
);

SELECT ok(
  EXISTS(
    SELECT 1 FROM pg_enum
    WHERE enumlabel = 'approved'
      AND enumtypid = 'public.partner_application_status'::regtype
  ),
  'partner_application_status must include approved'
);

SELECT ok(
  EXISTS(
    SELECT 1 FROM pg_enum
    WHERE enumlabel = 'rejected'
      AND enumtypid = 'public.partner_application_status'::regtype
  ),
  'partner_application_status must include rejected'
);

SELECT ok(
  EXISTS(
    SELECT 1 FROM pg_enum
    WHERE enumlabel = 'needs_correction'
      AND enumtypid = 'public.partner_application_status'::regtype
  ),
  'partner_application_status must include needs_correction'
);

SELECT * FROM finish();
ROLLBACK;
