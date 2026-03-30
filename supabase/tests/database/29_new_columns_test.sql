BEGIN;
SELECT plan(8);

-- profile_image_url (migration 16)
SELECT has_column('user_profiles', 'profile_image_url',
  'profile_image_url column exists');

-- refund_amount (migration 24)
SELECT has_column('event_applications', 'refund_amount',
  'refund_amount column exists');
SELECT col_has_default('event_applications', 'refund_amount',
  'refund_amount has default');

-- portone_partner_id (migration 24)
SELECT has_column('partners', 'portone_partner_id',
  'portone_partner_id column exists');
SELECT has_index('partners', 'partners_portone_partner_id_idx',
  'portone_partner_id index exists');

-- FK 인덱스 (migration 18) — 대표 3개 확인
SELECT has_index('fcm_tokens', 'idx_fcm_tokens_user_id',
  'fcm_tokens user_id index exists');
SELECT has_index('minglit_files', 'idx_minglit_files_storage_object_id',
  'minglit_files storage_object_id index exists');
SELECT has_index('match_rules', 'idx_match_rules_source_group_id',
  'match_rules source_group index exists');

SELECT * FROM finish();
ROLLBACK;
