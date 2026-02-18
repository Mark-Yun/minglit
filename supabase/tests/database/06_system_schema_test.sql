BEGIN;
SELECT plan(58);

-- processed_events
SELECT has_table('processed_events');
SELECT has_column('processed_events', 'id');
SELECT has_column('processed_events', 'processed_at');
SELECT col_type_is('processed_events', 'id', 'uuid');
SELECT col_is_pk('processed_events', 'id');
SELECT col_not_null('processed_events', 'id');
SELECT col_type_is('processed_events', 'processed_at', 'timestamp with time zone');
SELECT col_not_null('processed_events', 'processed_at');
SELECT col_has_default('processed_events', 'processed_at');
SELECT has_index('processed_events', 'processed_events_at_idx');

-- dead_letter_queue
SELECT has_table('dead_letter_queue');
SELECT has_column('dead_letter_queue', 'id');
SELECT has_column('dead_letter_queue', 'msg_id');
SELECT has_column('dead_letter_queue', 'queue_name');
SELECT has_column('dead_letter_queue', 'payload');
SELECT has_column('dead_letter_queue', 'error_reason');
SELECT has_column('dead_letter_queue', 'failed_at');
SELECT col_type_is('dead_letter_queue', 'id', 'uuid');
SELECT col_is_pk('dead_letter_queue', 'id');
SELECT col_has_default('dead_letter_queue', 'id');
SELECT col_not_null('dead_letter_queue', 'id');
SELECT col_not_null('dead_letter_queue', 'msg_id');
SELECT col_not_null('dead_letter_queue', 'queue_name');
SELECT col_type_is('dead_letter_queue', 'payload', 'jsonb');
SELECT col_not_null('dead_letter_queue', 'payload');
SELECT col_type_is('dead_letter_queue', 'failed_at', 'timestamp with time zone');
SELECT col_not_null('dead_letter_queue', 'failed_at');
SELECT col_has_default('dead_letter_queue', 'failed_at');
SELECT has_index('dead_letter_queue', 'dlq_queue_name_idx');

-- debug_logs
SELECT has_table('debug_logs');
SELECT has_column('debug_logs', 'id');
SELECT has_column('debug_logs', 'message');
SELECT has_column('debug_logs', 'payload');
SELECT has_column('debug_logs', 'created_at');
SELECT col_type_is('debug_logs', 'id', 'uuid');
SELECT col_is_pk('debug_logs', 'id');
SELECT col_has_default('debug_logs', 'id');
SELECT col_not_null('debug_logs', 'id');
SELECT col_type_is('debug_logs', 'payload', 'jsonb');
SELECT col_type_is('debug_logs', 'created_at', 'timestamp with time zone');
SELECT col_has_default('debug_logs', 'created_at');

-- event_routes
SELECT has_table('event_routes');
SELECT has_column('event_routes', 'id');
SELECT has_column('event_routes', 'event_type');
SELECT has_column('event_routes', 'target_queue');
SELECT has_column('event_routes', 'is_active');
SELECT has_column('event_routes', 'created_at');
SELECT col_type_is('event_routes', 'id', 'uuid');
SELECT col_is_pk('event_routes', 'id');
SELECT col_has_default('event_routes', 'id');
SELECT col_not_null('event_routes', 'id');
SELECT col_type_is('event_routes', 'event_type', 'event_type_name');
SELECT col_not_null('event_routes', 'event_type');
SELECT col_type_is('event_routes', 'target_queue', 'event_queue_name');
SELECT col_not_null('event_routes', 'target_queue');
SELECT col_has_default('event_routes', 'is_active');
SELECT col_type_is('event_routes', 'created_at', 'timestamp with time zone');
SELECT col_has_default('event_routes', 'created_at');

SELECT * FROM finish();
ROLLBACK;
