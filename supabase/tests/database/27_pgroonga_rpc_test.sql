BEGIN;
SELECT plan(6);

-- 함수 존재
SELECT has_function('public', 'search_events_pgroonga', array['text'],
  'search_events_pgroonga function exists');
SELECT has_function('public', 'search_parties_pgroonga', array['text'],
  'search_parties_pgroonga function exists');

-- 반환 타입
SELECT function_returns('public', 'search_events_pgroonga', array['text'],
  'setof events', 'returns setof events');
SELECT function_returns('public', 'search_parties_pgroonga', array['text'],
  'setof parties', 'returns setof parties');

-- pgroonga 인덱스 존재
SELECT has_index('events', 'events_title_pgroonga_idx',
  'events pgroonga index exists');
SELECT has_index('parties', 'parties_title_pgroonga_idx',
  'parties pgroonga index exists');

SELECT * FROM finish();
ROLLBACK;
