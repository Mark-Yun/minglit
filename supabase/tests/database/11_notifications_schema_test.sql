BEGIN;
SELECT plan(65);

-- user_notifications
SELECT has_table('user_notifications');
SELECT has_column('user_notifications', 'id');
SELECT has_column('user_notifications', 'user_id');
SELECT has_column('user_notifications', 'title');
SELECT has_column('user_notifications', 'body');
SELECT has_column('user_notifications', 'category');
SELECT has_column('user_notifications', 'deep_link');
SELECT has_column('user_notifications', 'is_read');
SELECT has_column('user_notifications', 'metadata');
SELECT has_column('user_notifications', 'created_at');
SELECT col_type_is('user_notifications', 'id', 'uuid');
SELECT col_is_pk('user_notifications', 'id');
SELECT col_has_default('user_notifications', 'id');
SELECT col_not_null('user_notifications', 'id');
SELECT col_type_is('user_notifications', 'user_id', 'uuid');
SELECT col_is_fk('user_notifications', 'user_id');
SELECT col_not_null('user_notifications', 'user_id');
SELECT col_not_null('user_notifications', 'title');
SELECT col_not_null('user_notifications', 'body');
SELECT col_type_is('user_notifications', 'category', 'notification_category');
SELECT col_not_null('user_notifications', 'category');
SELECT col_has_default('user_notifications', 'category');
SELECT col_not_null('user_notifications', 'is_read');
SELECT col_has_default('user_notifications', 'is_read');
SELECT col_type_is('user_notifications', 'metadata', 'jsonb');
SELECT col_has_default('user_notifications', 'metadata');
SELECT col_type_is('user_notifications', 'created_at', 'timestamp with time zone');
SELECT col_has_default('user_notifications', 'created_at');
SELECT col_not_null('user_notifications', 'created_at');
SELECT has_index('user_notifications', 'idx_user_notifications_user_id');
SELECT has_index('user_notifications', 'idx_user_notifications_created_at');
SELECT has_index('user_notifications', 'idx_user_notifications_unread');

-- fcm_tokens
SELECT has_table('fcm_tokens');
SELECT has_column('fcm_tokens', 'id');
SELECT has_column('fcm_tokens', 'user_id');
SELECT has_column('fcm_tokens', 'token');
SELECT has_column('fcm_tokens', 'device_type');
SELECT has_column('fcm_tokens', 'last_updated_at');
SELECT col_type_is('fcm_tokens', 'id', 'uuid');
SELECT col_is_pk('fcm_tokens', 'id');
SELECT col_has_default('fcm_tokens', 'id');
SELECT col_not_null('fcm_tokens', 'id');
SELECT col_type_is('fcm_tokens', 'user_id', 'uuid');
SELECT col_is_fk('fcm_tokens', 'user_id');
SELECT col_not_null('fcm_tokens', 'user_id');
SELECT col_not_null('fcm_tokens', 'token');
SELECT col_type_is('fcm_tokens', 'last_updated_at', 'timestamp with time zone');
SELECT col_has_default('fcm_tokens', 'last_updated_at');
SELECT col_not_null('fcm_tokens', 'last_updated_at');

-- user_settings
SELECT has_table('user_settings');
SELECT has_column('user_settings', 'user_id');
SELECT has_column('user_settings', 'marketing_consent');
SELECT has_column('user_settings', 'service_notification');
SELECT has_column('user_settings', 'updated_at');
SELECT col_type_is('user_settings', 'user_id', 'uuid');
SELECT col_is_pk('user_settings', 'user_id');
SELECT col_is_fk('user_settings', 'user_id');
SELECT col_not_null('user_settings', 'user_id');
SELECT col_not_null('user_settings', 'marketing_consent');
SELECT col_has_default('user_settings', 'marketing_consent');
SELECT col_not_null('user_settings', 'service_notification');
SELECT col_has_default('user_settings', 'service_notification');
SELECT col_type_is('user_settings', 'updated_at', 'timestamp with time zone');
SELECT col_has_default('user_settings', 'updated_at');
SELECT col_not_null('user_settings', 'updated_at');

SELECT * FROM finish();
ROLLBACK;
