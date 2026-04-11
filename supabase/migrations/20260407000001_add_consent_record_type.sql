-- ============================================================
-- Add 'consent' to archived_records.record_type CHECK constraint
-- Korean PIPA (개인정보보호법) requires consent records to be
-- retained for 2 years after account deletion.
-- ============================================================

ALTER TABLE public.archived_records
  DROP CONSTRAINT archived_records_record_type_check,
  ADD CONSTRAINT archived_records_record_type_check
    CHECK (record_type IN ('contract', 'payment', 'dispute', 'login', 'consent'));
