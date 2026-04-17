-- Regression test for Fix #1511:
-- Ensures all expected partner_application_status enum labels exist.
-- The 'draft' value was absent from the live DB because ALTER TYPE ADD VALUE
-- silently failed inside a transaction in the original migration (20260307000001).

BEGIN;
SELECT plan(5);

SELECT has_enum('public', 'partner_application_status',
  'enum partner_application_status should exist');

SELECT enum_has_label('public', 'partner_application_status', 'draft',
  'partner_application_status must include draft (regression: #1511)');

SELECT enum_has_label('public', 'partner_application_status', 'pending',
  'partner_application_status must include pending');

SELECT enum_has_label('public', 'partner_application_status', 'approved',
  'partner_application_status must include approved');

SELECT enum_has_label('public', 'partner_application_status', 'rejected',
  'partner_application_status must include rejected');

SELECT * FROM finish();
ROLLBACK;
