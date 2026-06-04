BEGIN;
SELECT plan(9);

SELECT tests.create_supabase_user('user_a', 'a@test.com');
SELECT tests.create_supabase_user('user_b', 'b@test.com');

SELECT tests.authenticate_as_service_role();

WITH notif_a AS (
  INSERT INTO public.user_notifications (user_id, title, body, category)
  VALUES (
    tests.get_supabase_uid('user_a'),
    'Hello A',
    'Body A',
    'service'
  )
  RETURNING id
)
SELECT set_config('tests.notif_a', id::text, true) FROM notif_a;

WITH notif_b AS (
  INSERT INTO public.user_notifications (user_id, title, body, category)
  VALUES (
    tests.get_supabase_uid('user_b'),
    'Hello B',
    'Body B',
    'service'
  )
  RETURNING id
)
SELECT set_config('tests.notif_b', id::text, true) FROM notif_b;

SELECT lives_ok(
  format(
    $$
      INSERT INTO public.user_notifications (user_id, title, body, category)
      VALUES ('%s', 'Service insert', 'Service body', 'service')
    $$,
    tests.get_supabase_uid('user_a')
  ),
  'service_role can insert notifications'
);

SELECT tests.clear_authentication();

SAVEPOINT before_anon_notification_insert;
SELECT throws_ok(
  format(
    $$
      INSERT INTO public.user_notifications (user_id, title, body, category)
      VALUES ('%s', 'Anon insert', 'Anon body', 'service')
    $$,
    tests.get_supabase_uid('user_a')
  ),
  NULL,
  NULL,
  'anon cannot insert arbitrary notifications'
);
ROLLBACK TO SAVEPOINT before_anon_notification_insert;

SELECT tests.authenticate_as('user_a');

SAVEPOINT before_authenticated_notification_insert;
SELECT throws_ok(
  format(
    $$
      INSERT INTO public.user_notifications (user_id, title, body, category)
      VALUES ('%s', 'Authenticated insert', 'Authenticated body', 'service')
    $$,
    tests.get_supabase_uid('user_a')
  ),
  NULL,
  NULL,
  'authenticated users cannot insert arbitrary notifications'
);
ROLLBACK TO SAVEPOINT before_authenticated_notification_insert;

SELECT tests.clear_authentication();
SELECT is_empty(
  $$SELECT id
    FROM public.user_notifications
    WHERE id = current_setting('tests.notif_a')::uuid$$,
  'anon cannot read notifications'
);

SELECT tests.authenticate_as('user_a');
SELECT results_eq(
  $$SELECT count(*)::int
    FROM public.user_notifications
    WHERE id = current_setting('tests.notif_a')::uuid$$,
  $$VALUES (1)$$,
  'users can read their own notifications'
);

SELECT tests.authenticate_as('user_b');
SELECT is_empty(
  $$SELECT id
    FROM public.user_notifications
    WHERE id = current_setting('tests.notif_a')::uuid$$,
  'users cannot read others notifications'
);

SELECT tests.authenticate_as('user_a');
SELECT throws_ok(
  $$UPDATE public.user_notifications
      SET is_read = true
      WHERE id = current_setting('tests.notif_a')::uuid$$,
  '42501',
  null,
  'users cannot directly update their own notifications'
);
SELECT results_eq(
  $$SELECT is_read
    FROM public.user_notifications
    WHERE id = current_setting('tests.notif_a')::uuid$$,
  $$VALUES (false)$$,
  'direct notification update does not persist'
);

SELECT tests.authenticate_as('user_b');
SELECT throws_ok(
  $$UPDATE public.user_notifications
      SET is_read = false
      WHERE id = current_setting('tests.notif_a')::uuid$$,
  '42501',
  null,
  'users cannot update others notifications'
);

SELECT * FROM finish();
ROLLBACK;
