-- Issue #2752: restrict direct client execution of internal SECURITY DEFINER helpers.
--
-- These functions are cron/trigger/service-role implementation details. Client
-- RPCs and RLS predicate helpers are intentionally left for separate review.

revoke all on function public.calculate_settlement_amounts(bigint, numeric, numeric, numeric)
  from public, anon, authenticated;
grant execute on function public.calculate_settlement_amounts(bigint, numeric, numeric, numeric)
  to service_role;

revoke all on function public.calculate_settlement_checksum(uuid, date, date, character, bigint, numeric, numeric, numeric, bigint, bigint, bigint, bigint)
  from public, anon, authenticated;
grant execute on function public.calculate_settlement_checksum(uuid, date, date, character, bigint, numeric, numeric, numeric, bigint, bigint, bigint, bigint)
  to service_role;

revoke all on function public.transition_settlement_status(uuid, integer, text, text, text, text, text, text, text, text, jsonb, text)
  from public, anon, authenticated;
grant execute on function public.transition_settlement_status(uuid, integer, text, text, text, text, text, text, text, text, jsonb, text)
  to service_role;

revoke all on function public.create_settlement_on_event_completion()
  from public, anon, authenticated;
grant execute on function public.create_settlement_on_event_completion()
  to service_role;

revoke all on function public.update_settlement_ready_status()
  from public, anon, authenticated;
grant execute on function public.update_settlement_ready_status()
  to service_role;

revoke all on function public.check_stuck_processing_settlements()
  from public, anon, authenticated;
grant execute on function public.check_stuck_processing_settlements()
  to service_role;

revoke all on function public.calculate_next_retry_at(integer)
  from public, anon, authenticated;
grant execute on function public.calculate_next_retry_at(integer)
  to service_role;

revoke all on function public.assemble_payouts()
  from public, anon, authenticated;
grant execute on function public.assemble_payouts()
  to service_role;

revoke all on function public.retry_failed_settlements()
  from public, anon, authenticated;
grant execute on function public.retry_failed_settlements()
  to service_role;

revoke all on function public.calculate_scheduled_at(date, time without time zone)
  from public, anon, authenticated;
grant execute on function public.calculate_scheduled_at(date, time without time zone)
  to service_role;

revoke all on function public.classify_reconciliation_mismatch(bigint, bigint, date, date, text, text)
  from public, anon, authenticated;
grant execute on function public.classify_reconciliation_mismatch(bigint, bigint, date, date, text, text)
  to service_role;

revoke all on function public.force_fail_processing_on_kill_switch()
  from public, anon, authenticated;
grant execute on function public.force_fail_processing_on_kill_switch()
  to service_role;

revoke all on function public.toggle_settlement_kill_switch(boolean, text)
  from public, anon, authenticated;
grant execute on function public.toggle_settlement_kill_switch(boolean, text)
  to service_role;

revoke all on function public.check_settlement_alarms()
  from public, anon, authenticated;
grant execute on function public.check_settlement_alarms()
  to service_role;

revoke all on function public.check_db_invariants()
  from public, anon, authenticated;
grant execute on function public.check_db_invariants()
  to service_role;

revoke all on function public.upsert_github_daily_stat(date, text, integer)
  from public, anon, authenticated;
grant execute on function public.upsert_github_daily_stat(date, text, integer)
  to service_role;
