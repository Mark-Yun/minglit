-- pgTAP regression test for Fix #2203: public.report_details must be in retention whitelist
BEGIN;

SELECT plan(2);

SELECT ok(
  EXISTS (
    SELECT 1 FROM admin.retention_allowed_targets
    WHERE schema_name = 'public'
      AND table_name  = 'report_details'
      AND ts_col      = 'created_at'
  ),
  'public.report_details is in retention_allowed_targets whitelist'
);

SELECT ok(
  (
    SELECT legal_min_days FROM admin.retention_allowed_targets
    WHERE schema_name = 'public' AND table_name = 'report_details'
  ) = 365,
  'report_details whitelist entry has legal_min_days = 365'
);

SELECT * FROM finish();
ROLLBACK;
