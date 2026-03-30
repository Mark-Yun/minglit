BEGIN;
SELECT plan(22);

-- settlements 테이블 컬럼
SELECT has_table('settlements');
SELECT has_column('settlements', 'id');
SELECT has_column('settlements', 'partner_id');
SELECT has_column('settlements', 'event_id');
SELECT has_column('settlements', 'event_title');
SELECT has_column('settlements', 'event_date');
SELECT has_column('settlements', 'total_sales');
SELECT has_column('settlements', 'total_refunds');
SELECT has_column('settlements', 'pg_fee');
SELECT has_column('settlements', 'platform_fee');
SELECT has_column('settlements', 'vat');
SELECT has_column('settlements', 'net_amount');
SELECT has_column('settlements', 'status');
SELECT has_column('settlements', 'created_at');
SELECT has_column('settlements', 'updated_at');

-- 타입 + 제약
SELECT col_is_pk('settlements', 'id');
SELECT col_is_fk('settlements', 'partner_id');
SELECT col_is_fk('settlements', 'event_id');
SELECT col_has_check('settlements', 'status');

-- 인덱스 3개
SELECT has_index('settlements', 'settlements_partner_id_idx');
SELECT has_index('settlements', 'settlements_status_idx');
SELECT has_index('settlements', 'settlements_event_date_idx');

SELECT * FROM finish();
ROLLBACK;
