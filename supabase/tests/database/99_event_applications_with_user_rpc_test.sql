BEGIN;
SELECT plan(6);

-- ============================================================
-- Setup: 파트너/이벤트/티켓/신청 데이터 구성
-- ============================================================

SELECT tests.authenticate_as_service_role();

SELECT tests.create_supabase_user('eawu_partner');
SELECT tests.create_supabase_user('eawu_applicant');
SELECT tests.create_supabase_user('eawu_no_perm');

DO $$
DECLARE
  v_partner_id uuid;
  v_party_id   uuid;
  v_event_id   uuid;
  v_ticket_id  uuid;
  v_app_id     uuid;
  v_paid_ts    timestamptz := '2026-05-01 10:00:00+00';
BEGIN
  INSERT INTO public.partners (name) VALUES ('EAWU Test Partner')
  RETURNING id INTO v_partner_id;

  INSERT INTO public.partner_member_permissions (partner_id, user_id, role)
  VALUES (v_partner_id, tests.get_supabase_uid('eawu_partner'), 'owner');

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
  VALUES (v_partner_id, 'EAWU Party', 0, 10)
  RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants)
  VALUES (v_party_id, now() + interval '1 day', now() + interval '1 day' + interval '2 hours', 0, 10)
  RETURNING id INTO v_event_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event_id, 'EAWU Ticket', 5, 10000)
  RETURNING id INTO v_ticket_id;

  INSERT INTO public.event_applications
    (event_id, ticket_id, user_id, status, paid_at, refunded_at)
  VALUES
    (v_event_id, v_ticket_id, tests.get_supabase_uid('eawu_applicant'),
     'approved', v_paid_ts, NULL)
  RETURNING id INTO v_app_id;

  PERFORM set_config('tests.eawu_event_id', v_event_id::text, true);
  PERFORM set_config('tests.eawu_app_id',   v_app_id::text,   true);
  PERFORM set_config('tests.eawu_paid_ts',  v_paid_ts::text,  true);
END $$;

-- ============================================================
-- Test 1: PARTY_MANAGE 파트너 — 신청 1건 반환
-- ============================================================

SELECT tests.authenticate_as('eawu_partner');

SELECT is(
  (SELECT count(*)::int FROM public.get_event_applications_with_user(
    current_setting('tests.eawu_event_id')::uuid
  )),
  1,
  'get_event_applications_with_user: 파트너 — 신청 1건 반환'
);

-- ============================================================
-- Test 2: paid_at 값 정확히 반환
-- ============================================================

SELECT is(
  (SELECT paid_at FROM public.get_event_applications_with_user(
    current_setting('tests.eawu_event_id')::uuid
  ) WHERE application_id = current_setting('tests.eawu_app_id')::uuid),
  current_setting('tests.eawu_paid_ts')::timestamptz,
  'get_event_applications_with_user: paid_at 정확히 반환 (Fix #2272)'
);

-- ============================================================
-- Test 3: refunded_at NULL 반환 (미환불 신청)
-- ============================================================

SELECT is(
  (SELECT refunded_at FROM public.get_event_applications_with_user(
    current_setting('tests.eawu_event_id')::uuid
  ) WHERE application_id = current_setting('tests.eawu_app_id')::uuid),
  NULL::timestamptz,
  'get_event_applications_with_user: refunded_at NULL (미환불 신청) (Fix #2272)'
);

-- ============================================================
-- Test 4: user_email 반환 (auth.users 조인)
-- ============================================================

SELECT isnt(
  (SELECT user_email FROM public.get_event_applications_with_user(
    current_setting('tests.eawu_event_id')::uuid
  ) WHERE application_id = current_setting('tests.eawu_app_id')::uuid),
  NULL,
  'get_event_applications_with_user: user_email NOT NULL (auth.users 조인) (Fix #2272)'
);

-- ============================================================
-- Test 5: PARTY_MANAGE 없는 유저 — 빈 결과 (권한 없음)
-- ============================================================

SELECT tests.authenticate_as('eawu_no_perm');

SELECT is(
  (SELECT count(*)::int FROM public.get_event_applications_with_user(
    current_setting('tests.eawu_event_id')::uuid
  )),
  0,
  'get_event_applications_with_user: PARTY_MANAGE 없는 유저 — 빈 결과'
);

-- ============================================================
-- Test 6: user_username 컬럼 존재 확인 (Fix #2272)
-- ============================================================

SELECT tests.authenticate_as('eawu_partner');

SELECT ok(
  (SELECT count(*) = 1 FROM (
    SELECT user_username FROM public.get_event_applications_with_user(
      current_setting('tests.eawu_event_id')::uuid
    ) WHERE application_id = current_setting('tests.eawu_app_id')::uuid
  ) sub),
  'get_event_applications_with_user: user_username column accessible (Fix #2272)'
);

SELECT * FROM finish();
ROLLBACK;
