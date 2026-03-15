BEGIN;
SELECT no_plan();

-- ============================================================
-- settlement_items
-- ============================================================
SELECT has_table('public', 'settlement_items', 'settlement_items table exists');

-- Required columns
SELECT has_column('settlement_items', 'id');
SELECT has_column('settlement_items', 'partner_id');
SELECT has_column('settlement_items', 'settlement_period_start');
SELECT has_column('settlement_items', 'settlement_period_end');
SELECT has_column('settlement_items', 'currency');
SELECT has_column('settlement_items', 'source_type');
SELECT has_column('settlement_items', 'source_id');
SELECT has_column('settlement_items', 'status');
SELECT has_column('settlement_items', 'gross_amount');
SELECT has_column('settlement_items', 'platform_fee_rate');
SELECT has_column('settlement_items', 'platform_fee_amount');
SELECT has_column('settlement_items', 'pg_fee_rate');
SELECT has_column('settlement_items', 'pg_fee_amount');
SELECT has_column('settlement_items', 'vat_rate');
SELECT has_column('settlement_items', 'vat_amount');
SELECT has_column('settlement_items', 'net_amount');
SELECT has_column('settlement_items', 'hold_reason_code');
SELECT has_column('settlement_items', 'failure_reason_code');
SELECT has_column('settlement_items', 'retryable');
SELECT has_column('settlement_items', 'retry_count');
SELECT has_column('settlement_items', 'payout_id');
SELECT has_column('settlement_items', 'calc_checksum');
SELECT has_column('settlement_items', 'version');
SELECT has_column('settlement_items', 'event_completed_at');
SELECT has_column('settlement_items', 'created_at');
SELECT has_column('settlement_items', 'updated_at');

-- PK
SELECT col_is_pk('settlement_items', 'id');

-- CHECK constraints
SELECT col_has_check('settlement_items', 'status');
SELECT col_has_check('settlement_items', 'gross_amount');
SELECT col_has_check('settlement_items', 'platform_fee_rate');
SELECT col_has_check('settlement_items', 'retry_count');
SELECT col_has_check('settlement_items', 'version');

-- Indexes
SELECT has_index('settlement_items', 'idx_settlement_items_partner_period');
SELECT has_index('settlement_items', 'idx_settlement_items_status');
SELECT has_index('settlement_items', 'idx_settlement_items_payout');
SELECT has_index('settlement_items', 'idx_settlement_items_source');
SELECT has_index('settlement_items', 'uq_settlement_items_source');

-- RLS policy exists
SELECT results_eq(
  $$SELECT count(*)::int FROM pg_policies WHERE tablename='settlement_items' AND policyname='Partner can read own settlement_items'$$,
  $$VALUES (1)$$,
  'settlement_items has Partner can read own settlement_items policy'
);

-- ============================================================
-- settlement_histories
-- ============================================================
SELECT has_table('public', 'settlement_histories', 'settlement_histories table exists');

SELECT has_column('settlement_histories', 'id');
SELECT has_column('settlement_histories', 'settlement_item_id');
SELECT has_column('settlement_histories', 'event_at');
SELECT has_column('settlement_histories', 'event_type');
SELECT has_column('settlement_histories', 'actor_type');
SELECT has_column('settlement_histories', 'actor_id');
SELECT has_column('settlement_histories', 'from_status');
SELECT has_column('settlement_histories', 'to_status');
SELECT has_column('settlement_histories', 'idempotency_key');
SELECT has_column('settlement_histories', 'details');

SELECT col_is_pk('settlement_histories', 'id');
SELECT col_is_fk('settlement_histories', 'settlement_item_id');
SELECT col_has_check('settlement_histories', 'actor_type');

SELECT has_index('settlement_histories', 'idx_settlement_histories_item_eventat');
SELECT has_index('settlement_histories', 'idx_settlement_histories_event_type');
SELECT has_index('settlement_histories', 'idx_settlement_histories_actor');
SELECT has_index('settlement_histories', 'uq_settlement_histories_idempotency');

SELECT results_eq(
  $$SELECT count(*)::int FROM pg_policies WHERE tablename='settlement_histories' AND policyname='Partner can read related settlement_histories'$$,
  $$VALUES (1)$$,
  'settlement_histories has read policy'
);

-- ============================================================
-- payouts
-- ============================================================
SELECT has_table('public', 'payouts', 'payouts table exists');

SELECT has_column('payouts', 'id');
SELECT has_column('payouts', 'partner_id');
SELECT has_column('payouts', 'status');
SELECT has_column('payouts', 'scheduled_at');
SELECT has_column('payouts', 'total_net_amount');
SELECT has_column('payouts', 'bank_account_snapshot');
SELECT has_column('payouts', 'payout_request_idempotency_key');
SELECT has_column('payouts', 'updated_at');

SELECT col_is_pk('payouts', 'id');
SELECT col_has_check('payouts', 'status');
SELECT col_has_check('payouts', 'total_net_amount');

SELECT has_index('payouts', 'uq_payouts_partner_period');
SELECT has_index('payouts', 'idx_payouts_status_scheduled');

SELECT results_eq(
  $$SELECT count(*)::int FROM pg_policies WHERE tablename='payouts' AND policyname='Partner can read own payouts'$$,
  $$VALUES (1)$$,
  'payouts has Partner can read own payouts policy'
);

-- ============================================================
-- payout_transfers
-- ============================================================
SELECT has_table('public', 'payout_transfers', 'payout_transfers table exists');

SELECT has_column('payout_transfers', 'id');
SELECT has_column('payout_transfers', 'payout_id');
SELECT has_column('payout_transfers', 'idempotency_key');
SELECT has_column('payout_transfers', 'status');
SELECT has_column('payout_transfers', 'amount');

SELECT col_is_pk('payout_transfers', 'id');
SELECT col_is_fk('payout_transfers', 'payout_id');
SELECT col_has_check('payout_transfers', 'status');

SELECT has_index('payout_transfers', 'idx_payout_transfers_payout');
SELECT has_index('payout_transfers', 'idx_payout_transfers_status_retry');
SELECT has_index('payout_transfers', 'uq_payout_transfers_idem');

SELECT results_eq(
  $$SELECT count(*)::int FROM pg_policies WHERE tablename='payout_transfers' AND policyname='Partner can read related payout_transfers'$$,
  $$VALUES (1)$$,
  'payout_transfers has read policy'
);

-- ============================================================
-- adjustment_items
-- ============================================================
SELECT has_table('public', 'adjustment_items', 'adjustment_items table exists');

SELECT has_column('adjustment_items', 'id');
SELECT has_column('adjustment_items', 'partner_id');
SELECT has_column('adjustment_items', 'adjustment_type');
SELECT has_column('adjustment_items', 'amount_signed');
SELECT has_column('adjustment_items', 'status');

SELECT col_is_pk('adjustment_items', 'id');
SELECT col_has_check('adjustment_items', 'adjustment_type');
SELECT col_has_check('adjustment_items', 'amount_signed');

SELECT has_index('adjustment_items', 'idx_adjustment_partner_created');
SELECT has_index('adjustment_items', 'idx_adjustment_related');

SELECT results_eq(
  $$SELECT count(*)::int FROM pg_policies WHERE tablename='adjustment_items' AND policyname='Partner can read own adjustment_items'$$,
  $$VALUES (1)$$,
  'adjustment_items has Partner can read own adjustment_items policy'
);

SELECT * FROM finish();
ROLLBACK;

