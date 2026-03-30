BEGIN;

SELECT plan(8);

SELECT has_function(
  'analytics', 'aggregate_daily_active_users', ARRAY['date'],
  'aggregate_daily_active_users(date) function exists'
);

SELECT has_function(
  'analytics', 'aggregate_daily_events', ARRAY['date'],
  'aggregate_daily_events(date) function exists'
);

SELECT has_function(
  'analytics', 'aggregate_daily_revenue', ARRAY['date'],
  'aggregate_daily_revenue(date) function exists'
);

SELECT has_function(
  'analytics', 'aggregate_funnel_daily', ARRAY['date'],
  'aggregate_funnel_daily(date) function exists'
);

SELECT lives_ok(
  $$SELECT analytics.aggregate_daily_active_users('2020-01-01'::date)$$,
  'aggregate_daily_active_users runs without error on empty data'
);

SELECT lives_ok(
  $$SELECT analytics.aggregate_daily_events('2020-01-01'::date)$$,
  'aggregate_daily_events runs without error on empty data'
);

SELECT lives_ok(
  $$SELECT analytics.aggregate_daily_revenue('2020-01-01'::date)$$,
  'aggregate_daily_revenue runs without error on empty data'
);

SELECT lives_ok(
  $$SELECT analytics.aggregate_funnel_daily('2020-01-01'::date)$$,
  'aggregate_funnel_daily runs without error on empty data'
);

SELECT * FROM finish();

ROLLBACK;
