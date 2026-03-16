-- Tests for 2-tier queue architecture schema (event_type_name enum, event_routes, produce_event, fan_out_event)
BEGIN;
SELECT plan(16);

SELECT tests.authenticate_as_service_role();

-- ============================================================
-- PART 1: event_type_name enum validation
-- ============================================================

-- Test 1: event_type_name enum exists and has 12 values
-- (9 original + 3 settlement: settlement_ready, settlement_completed, settlement_failed)
SELECT ok(
  (SELECT count(*) FROM pg_enum JOIN pg_type ON pg_enum.enumtypid = pg_type.oid WHERE pg_type.typname = 'event_type_name') = 12,
  'event_type_name enum should have 12 values'
);

-- Test 2-10: individual enum values exist
SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_enum JOIN pg_type ON pg_enum.enumtypid = pg_type.oid 
    WHERE pg_type.typname = 'event_type_name' AND enumlabel = 'party_created'
  ),
  'event_type_name should have party_created'
);

SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_enum JOIN pg_type ON pg_enum.enumtypid = pg_type.oid 
    WHERE pg_type.typname = 'event_type_name' AND enumlabel = 'user_interaction'
  ),
  'event_type_name should have user_interaction'
);

SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_enum JOIN pg_type ON pg_enum.enumtypid = pg_type.oid 
    WHERE pg_type.typname = 'event_type_name' AND enumlabel = 'application_approved'
  ),
  'event_type_name should have application_approved'
);

SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_enum JOIN pg_type ON pg_enum.enumtypid = pg_type.oid 
    WHERE pg_type.typname = 'event_type_name' AND enumlabel = 'application_rejected'
  ),
  'event_type_name should have application_rejected'
);

SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_enum JOIN pg_type ON pg_enum.enumtypid = pg_type.oid 
    WHERE pg_type.typname = 'event_type_name' AND enumlabel = 'event_updated'
  ),
  'event_type_name should have event_updated'
);

SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_enum JOIN pg_type ON pg_enum.enumtypid = pg_type.oid 
    WHERE pg_type.typname = 'event_type_name' AND enumlabel = 'event_cancelled'
  ),
  'event_type_name should have event_cancelled'
);

SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_enum JOIN pg_type ON pg_enum.enumtypid = pg_type.oid 
    WHERE pg_type.typname = 'event_type_name' AND enumlabel = 'new_application'
  ),
  'event_type_name should have new_application'
);

SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_enum JOIN pg_type ON pg_enum.enumtypid = pg_type.oid 
    WHERE pg_type.typname = 'event_type_name' AND enumlabel = 'verification_result'
  ),
  'event_type_name should have verification_result'
);

SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_enum JOIN pg_type ON pg_enum.enumtypid = pg_type.oid 
    WHERE pg_type.typname = 'event_type_name' AND enumlabel = 'event_reminder'
  ),
  'event_type_name should have event_reminder'
);

-- ============================================================
-- PART 2: event_routes table and routing validation
-- ============================================================

-- Test 11: event_routes table exists (already tested in 06_system_schema_test.sql, but verify again)
SELECT has_table('event_routes');

-- Test 12: event_routes has required columns
SELECT has_column('event_routes', 'event_type');

-- Test 13: event_routes has target_queue column
SELECT has_column('event_routes', 'target_queue');

-- Test 14: event_routes has is_active column
SELECT has_column('event_routes', 'is_active');

-- ============================================================
-- PART 3: produce_event and fan_out_event functions
-- ============================================================

-- Test 15: produce_event function exists
SELECT has_function('produce_event');

-- Test 16: fan_out_event function exists
SELECT has_function('fan_out_event');

SELECT * FROM finish();
ROLLBACK;
