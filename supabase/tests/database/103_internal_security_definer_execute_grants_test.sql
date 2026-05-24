BEGIN;

SELECT plan(3);

-- Issue #2752: internal SECURITY DEFINER helpers should not be directly
-- executable by client roles. They remain callable by service_role Edge
-- Functions, cron jobs, and trigger-owned flows.

SELECT is_empty(
  $$
  WITH target(function_signature) AS (
    VALUES
      ('public.calculate_settlement_amounts(bigint, numeric, numeric, numeric)'),
      ('public.calculate_settlement_checksum(uuid, date, date, character, bigint, numeric, numeric, numeric, bigint, bigint, bigint, bigint)'),
      ('public.transition_settlement_status(uuid, integer, text, text, text, text, text, text, text, text, jsonb, text)'),
      ('public.create_settlement_on_event_completion()'),
      ('public.update_settlement_ready_status()'),
      ('public.check_stuck_processing_settlements()'),
      ('public.calculate_next_retry_at(integer)'),
      ('public.assemble_payouts()'),
      ('public.retry_failed_settlements()'),
      ('public.calculate_scheduled_at(date, time without time zone)'),
      ('public.classify_reconciliation_mismatch(bigint, bigint, date, date, text, text)'),
      ('public.force_fail_processing_on_kill_switch()'),
      ('public.toggle_settlement_kill_switch(boolean, text)'),
      ('public.check_settlement_alarms()'),
      ('public.check_db_invariants()'),
      ('public.upsert_github_daily_stat(date, text, integer)')
  )
  SELECT function_signature
  FROM target
  WHERE has_function_privilege('anon', function_signature, 'EXECUTE')
  ORDER BY function_signature
  $$,
  'anon cannot EXECUTE internal SECURITY DEFINER helpers'
);

SELECT is_empty(
  $$
  WITH target(function_signature) AS (
    VALUES
      ('public.calculate_settlement_amounts(bigint, numeric, numeric, numeric)'),
      ('public.calculate_settlement_checksum(uuid, date, date, character, bigint, numeric, numeric, numeric, bigint, bigint, bigint, bigint)'),
      ('public.transition_settlement_status(uuid, integer, text, text, text, text, text, text, text, text, jsonb, text)'),
      ('public.create_settlement_on_event_completion()'),
      ('public.update_settlement_ready_status()'),
      ('public.check_stuck_processing_settlements()'),
      ('public.calculate_next_retry_at(integer)'),
      ('public.assemble_payouts()'),
      ('public.retry_failed_settlements()'),
      ('public.calculate_scheduled_at(date, time without time zone)'),
      ('public.classify_reconciliation_mismatch(bigint, bigint, date, date, text, text)'),
      ('public.force_fail_processing_on_kill_switch()'),
      ('public.toggle_settlement_kill_switch(boolean, text)'),
      ('public.check_settlement_alarms()'),
      ('public.check_db_invariants()'),
      ('public.upsert_github_daily_stat(date, text, integer)')
  )
  SELECT function_signature
  FROM target
  WHERE has_function_privilege('authenticated', function_signature, 'EXECUTE')
  ORDER BY function_signature
  $$,
  'authenticated cannot EXECUTE internal SECURITY DEFINER helpers'
);

SELECT is_empty(
  $$
  WITH target(function_signature) AS (
    VALUES
      ('public.calculate_settlement_amounts(bigint, numeric, numeric, numeric)'),
      ('public.calculate_settlement_checksum(uuid, date, date, character, bigint, numeric, numeric, numeric, bigint, bigint, bigint, bigint)'),
      ('public.transition_settlement_status(uuid, integer, text, text, text, text, text, text, text, text, jsonb, text)'),
      ('public.create_settlement_on_event_completion()'),
      ('public.update_settlement_ready_status()'),
      ('public.check_stuck_processing_settlements()'),
      ('public.calculate_next_retry_at(integer)'),
      ('public.assemble_payouts()'),
      ('public.retry_failed_settlements()'),
      ('public.calculate_scheduled_at(date, time without time zone)'),
      ('public.classify_reconciliation_mismatch(bigint, bigint, date, date, text, text)'),
      ('public.force_fail_processing_on_kill_switch()'),
      ('public.toggle_settlement_kill_switch(boolean, text)'),
      ('public.check_settlement_alarms()'),
      ('public.check_db_invariants()'),
      ('public.upsert_github_daily_stat(date, text, integer)')
  )
  SELECT function_signature
  FROM target
  WHERE NOT has_function_privilege('service_role', function_signature, 'EXECUTE')
  ORDER BY function_signature
  $$,
  'service_role can EXECUTE internal SECURITY DEFINER helpers'
);

SELECT * FROM finish();

ROLLBACK;
