begin;
select plan(6);

-- Test 1: parties.metadata column exists
select has_column('public', 'parties', 'metadata',
  'parties table should have metadata column');

-- Test 2: parties.metadata is jsonb type
select col_type_is('public', 'parties', 'metadata', 'jsonb',
  'parties.metadata should be jsonb type');

-- Test 3: parties.metadata has default value
select col_has_default('public', 'parties', 'metadata',
  'parties.metadata should have default value');

-- Test 4: events.metadata column exists
select has_column('public', 'events', 'metadata',
  'events table should have metadata column');

-- Test 5: events.metadata is jsonb type
select col_type_is('public', 'events', 'metadata', 'jsonb',
  'events.metadata should be jsonb type');

-- Test 6: events.metadata has default value
select col_has_default('public', 'events', 'metadata',
  'events.metadata should have default value');

select * from finish();
rollback;
