BEGIN;
SELECT plan(3);

SELECT has_view('public', 'partner_revenue_stats',
  'partner_revenue_stats view exists');
SELECT has_view('public', 'partner_monthly_revenue',
  'partner_monthly_revenue view exists');
SELECT has_view('public', 'my_matches_view',
  'my_matches_view exists');

SELECT * FROM finish();
ROLLBACK;
