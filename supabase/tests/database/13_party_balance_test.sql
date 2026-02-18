begin;
select plan(7);

-- Test 1: balance_config column exists
select has_column('public', 'parties', 'balance_config',
  'parties table should have balance_config column');

-- Test 2: balance_config is nullable
select col_is_null('public', 'parties', 'balance_config',
  'balance_config should be nullable');

-- Test 3: check_party_balance function exists
select has_function('public', 'check_party_balance',
  array['uuid', 'uuid'],
  'check_party_balance function should exist');

-- Test 4: get_event_ticket_balance_status function exists
select has_function('public', 'get_event_ticket_balance_status',
  array['uuid'],
  'get_event_ticket_balance_status function should exist');

-- Test 5: apply_event function still exists (after replacement)
select has_function('public', 'apply_event',
  array['uuid', 'uuid', 'uuid', 'text', 'int', 'jsonb'],
  'apply_event function should exist with balance check');

-- Test 6: check_party_balance returns jsonb
select function_returns('public', 'check_party_balance',
  array['uuid', 'uuid'],
  'jsonb',
  'check_party_balance should return jsonb');

-- Test 7: get_event_ticket_balance_status returns jsonb
select function_returns('public', 'get_event_ticket_balance_status',
  array['uuid'],
  'jsonb',
  'get_event_ticket_balance_status should return jsonb');

select * from finish();
rollback;
