BEGIN;
SELECT plan(7);

-- get_personalized_recommendations
SELECT has_function('public', 'get_personalized_recommendations',
  array['uuid', 'integer'],
  'AI rec function exists');

-- get_events_within_radius
SELECT has_function('public', 'get_events_within_radius',
  array['double precision', 'double precision', 'integer', 'integer'],
  'geo distance function exists');

-- get_bulk_eligibility_data
SELECT has_function('public', 'get_bulk_eligibility_data',
  array['uuid'],
  'bulk eligibility function exists');

-- 반환 타입
SELECT function_returns('public', 'get_bulk_eligibility_data',
  array['uuid'], 'jsonb', 'returns jsonb');

-- SECURITY DEFINER
SELECT is_definer('public', 'get_personalized_recommendations',
  array['uuid', 'integer'],
  'AI rec is security definer');
SELECT is_definer('public', 'get_events_within_radius',
  array['double precision', 'double precision', 'integer', 'integer'],
  'geo is security definer');
SELECT is_definer('public', 'get_bulk_eligibility_data',
  array['uuid'],
  'bulk eligibility is security definer');

SELECT * FROM finish();
ROLLBACK;
