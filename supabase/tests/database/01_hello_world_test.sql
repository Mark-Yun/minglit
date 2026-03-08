BEGIN;
SELECT plan(3);
SELECT has_table('user_profiles', 'user_profiles table should exist');
SELECT has_table('partners', 'partners table should exist');
SELECT has_table('events', 'events table should exist');
SELECT * FROM finish();
ROLLBACK;
