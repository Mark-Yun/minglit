-- Issue #2798: representative behavior checks for consolidated SELECT RLS
-- policy groups.
BEGIN;

SELECT no_plan();

SELECT tests.create_supabase_user('select_rls_owner', 'select-rls-owner@test.com');
SELECT tests.create_supabase_user('select_rls_applicant', 'select-rls-applicant@test.com');
SELECT tests.create_supabase_user('select_rls_outsider', 'select-rls-outsider@test.com');

SELECT tests.authenticate_as_service_role();

WITH partner AS (
  INSERT INTO public.partners (name, introduction)
  VALUES ('Select RLS Partner', 'RLS consolidation behavior test')
  RETURNING id
)
SELECT set_config('tests.select_rls_partner_id', id::text, true) FROM partner;

INSERT INTO public.partner_member_permissions (partner_id, user_id, role)
VALUES (
  current_setting('tests.select_rls_partner_id')::uuid,
  tests.get_supabase_uid('select_rls_owner'),
  'owner'
);

WITH party AS (
  INSERT INTO public.parties (partner_id, title, status)
  VALUES (
    current_setting('tests.select_rls_partner_id')::uuid,
    'Select RLS Party',
    'active'
  )
  RETURNING id
)
SELECT set_config('tests.select_rls_party_id', id::text, true) FROM party;

WITH event_row AS (
  INSERT INTO public.events (party_id, title, start_time, end_time, status)
  VALUES (
    current_setting('tests.select_rls_party_id')::uuid,
    'Select RLS Event',
    now() + interval '1 day',
    now() + interval '1 day' + interval '2 hours',
    'scheduled'
  )
  RETURNING id
)
SELECT set_config('tests.select_rls_event_id', id::text, true) FROM event_row;

WITH ticket AS (
  INSERT INTO public.tickets (event_id, name, price, quantity, status)
  VALUES (
    current_setting('tests.select_rls_event_id')::uuid,
    'Select RLS Ticket',
    0,
    20,
    'on_sale'
  )
  RETURNING id
)
SELECT set_config('tests.select_rls_ticket_id', id::text, true) FROM ticket;

WITH application AS (
  INSERT INTO public.event_applications (event_id, ticket_id, user_id, status)
  VALUES (
    current_setting('tests.select_rls_event_id')::uuid,
    current_setting('tests.select_rls_ticket_id')::uuid,
    tests.get_supabase_uid('select_rls_applicant'),
    'pending'
  )
  RETURNING id
)
SELECT set_config('tests.select_rls_application_id', id::text, true) FROM application;

WITH refund_request AS (
  INSERT INTO public.refund_requests (
    application_id,
    user_id,
    event_id,
    partner_id,
    reason_code,
    response_deadline_at
  )
  VALUES (
    current_setting('tests.select_rls_application_id')::uuid,
    tests.get_supabase_uid('select_rls_applicant'),
    current_setting('tests.select_rls_event_id')::uuid,
    current_setting('tests.select_rls_partner_id')::uuid,
    'schedule_change',
    now() + interval '2 days'
  )
  RETURNING id
)
SELECT set_config('tests.select_rls_refund_request_id', id::text, true) FROM refund_request;

WITH verification AS (
  INSERT INTO public.verifications (
    partner_id,
    category,
    internal_name,
    display_name,
    form_schema
  )
  VALUES (
    current_setting('tests.select_rls_partner_id')::uuid,
    'etc',
    'select_rls_verification',
    'Select RLS Verification',
    '[]'::jsonb
  )
  RETURNING id
)
SELECT set_config('tests.select_rls_verification_id', id::text, true) FROM verification;

WITH submission AS (
  INSERT INTO public.verification_submissions (
    partner_id,
    user_id,
    verification_id,
    application_id,
    snapshot_data
  )
  VALUES (
    current_setting('tests.select_rls_partner_id')::uuid,
    tests.get_supabase_uid('select_rls_applicant'),
    current_setting('tests.select_rls_verification_id')::uuid,
    current_setting('tests.select_rls_application_id')::uuid,
    '{}'::jsonb
  )
  RETURNING id
)
SELECT set_config('tests.select_rls_submission_id', id::text, true) FROM submission;

WITH tag AS (
  INSERT INTO public.tags (name, is_featured)
  VALUES ('select_rls_tag', false)
  RETURNING id
)
SELECT set_config('tests.select_rls_tag_id', id::text, true) FROM tag;

-- Public-read + strict write lockdown: public read remains, but partner owner
-- direct table writes must now go through Edge Functions.
SELECT tests.clear_authentication();
SELECT results_eq(
  $$SELECT count(*)::int FROM public.parties
    WHERE id = current_setting('tests.select_rls_party_id')::uuid$$,
  $$VALUES (1)$$,
  'anon can still read public party rows'
);

SELECT tests.authenticate_as('select_rls_owner');
SELECT throws_ok(
  $$UPDATE public.parties
      SET title = 'Select RLS Party Updated'
    WHERE id = current_setting('tests.select_rls_party_id')::uuid$$,
  '42501',
  NULL,
  'partner owner cannot directly update own party after strict write lockdown'
);

-- Self-read + partner-staff SELECT merge: one policy preserves both access
-- branches and excludes unrelated authenticated users.
SELECT tests.authenticate_as('select_rls_applicant');
SELECT results_eq(
  $$SELECT count(*)::int FROM public.event_applications
    WHERE id = current_setting('tests.select_rls_application_id')::uuid$$,
  $$VALUES (1)$$,
  'applicant can read own event application'
);
SELECT results_eq(
  $$SELECT count(*)::int FROM public.refund_requests
    WHERE id = current_setting('tests.select_rls_refund_request_id')::uuid$$,
  $$VALUES (1)$$,
  'applicant can read own refund request'
);
SELECT results_eq(
  $$SELECT count(*)::int FROM public.verification_submissions
    WHERE id = current_setting('tests.select_rls_submission_id')::uuid$$,
  $$VALUES (1)$$,
  'applicant can read own verification submission'
);

SELECT tests.authenticate_as('select_rls_owner');
SELECT results_eq(
  $$SELECT count(*)::int FROM public.event_applications
    WHERE id = current_setting('tests.select_rls_application_id')::uuid$$,
  $$VALUES (1)$$,
  'partner owner can read event applications for owned party'
);
SELECT results_eq(
  $$SELECT count(*)::int FROM public.refund_requests
    WHERE id = current_setting('tests.select_rls_refund_request_id')::uuid$$,
  $$VALUES (1)$$,
  'partner owner can read refund requests for owned partner'
);
SELECT results_eq(
  $$SELECT count(*)::int FROM public.verification_submissions
    WHERE id = current_setting('tests.select_rls_submission_id')::uuid$$,
  $$VALUES (1)$$,
  'partner owner can read verification submissions for owned partner'
);

SELECT tests.authenticate_as('select_rls_outsider');
SELECT is_empty(
  $$SELECT id FROM public.event_applications
    WHERE id = current_setting('tests.select_rls_application_id')::uuid$$,
  'unrelated user cannot read event application'
);
SELECT is_empty(
  $$SELECT id FROM public.refund_requests
    WHERE id = current_setting('tests.select_rls_refund_request_id')::uuid$$,
  'unrelated user cannot read refund request'
);
SELECT is_empty(
  $$SELECT id FROM public.verification_submissions
    WHERE id = current_setting('tests.select_rls_submission_id')::uuid$$,
  'unrelated user cannot read verification submission'
);

-- Service-role/read groups: authenticated users keep read access but not
-- direct writes; service_role keeps explicit write access.
SELECT lives_ok(
  $$SELECT count(*) FROM public.tag_usage_daily$$,
  'authenticated user can still read tag_usage_daily'
);

SAVEPOINT before_auth_tag_usage_insert;
SELECT throws_ok(
  format(
    $$
      INSERT INTO public.tag_usage_daily (tag_id, date, daily_count)
      VALUES ('%s', CURRENT_DATE, 1)
    $$,
    current_setting('tests.select_rls_tag_id')
  ),
  NULL,
  NULL,
  'authenticated user cannot directly insert tag_usage_daily'
);
ROLLBACK TO SAVEPOINT before_auth_tag_usage_insert;

SELECT tests.authenticate_as_service_role();
SELECT lives_ok(
  format(
    $$
      INSERT INTO public.tag_usage_daily (tag_id, date, daily_count)
      VALUES ('%s', CURRENT_DATE, 1)
      ON CONFLICT (tag_id, date) DO UPDATE
        SET daily_count = public.tag_usage_daily.daily_count + EXCLUDED.daily_count
    $$,
    current_setting('tests.select_rls_tag_id')
  ),
  'service_role can still write tag_usage_daily'
);

SELECT * FROM finish();
ROLLBACK;
