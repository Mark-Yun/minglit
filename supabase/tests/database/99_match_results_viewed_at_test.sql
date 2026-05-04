BEGIN;
SELECT plan(6);

-- ============================================================
-- Setup: 파트너/이벤트/신청서 데이터 구성
-- ============================================================

SELECT tests.authenticate_as_service_role();

SELECT tests.create_supabase_user('mrv_user_a');
SELECT tests.create_supabase_user('mrv_user_b');

DO $$
DECLARE
  v_partner_id  uuid;
  v_party_id    uuid;
  v_event_id    uuid;
  v_ticket_id   uuid;
  v_app_a_id    uuid;
  v_app_b_id    uuid;
BEGIN
  INSERT INTO public.partners (name) VALUES ('MRV Test Partner')
  RETURNING id INTO v_partner_id;

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
  VALUES (v_partner_id, 'MRV Party', 0, 10)
  RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants)
  VALUES (v_party_id, now() + interval '7 days', now() + interval '7 days' + interval '2 hours', 0, 10)
  RETURNING id INTO v_event_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event_id, 'General', 10, 0)
  RETURNING id INTO v_ticket_id;

  -- user_a 신청서: match_results_viewed_at NULL (미확인)
  INSERT INTO public.event_applications (event_id, user_id, ticket_id, status)
  VALUES (v_event_id, tests.get_supabase_uid('mrv_user_a'), v_ticket_id, 'pending')
  RETURNING id INTO v_app_a_id;

  -- user_b 신청서: match_results_viewed_at NULL (미확인)
  INSERT INTO public.event_applications (event_id, user_id, ticket_id, status)
  VALUES (v_event_id, tests.get_supabase_uid('mrv_user_b'), v_ticket_id, 'pending')
  RETURNING id INTO v_app_b_id;

  PERFORM set_config('tests.mrv_event_id',  v_event_id::text,  true);
  PERFORM set_config('tests.mrv_app_a_id',  v_app_a_id::text,  true);
  PERFORM set_config('tests.mrv_app_b_id',  v_app_b_id::text,  true);
END $$;

-- ============================================================
-- Test 1: 컬럼 존재 확인
-- ============================================================

SELECT has_column(
  'public',
  'event_applications',
  'match_results_viewed_at',
  'event_applications.match_results_viewed_at 컬럼 존재'
);

-- ============================================================
-- Test 2: 기본값은 NULL
-- ============================================================

SELECT is(
  (SELECT match_results_viewed_at FROM public.event_applications
   WHERE id = current_setting('tests.mrv_app_a_id')::uuid),
  NULL::timestamptz,
  'match_results_viewed_at 기본값은 NULL'
);

-- ============================================================
-- Test 3: 본인 신청서 RPC 호출 → true 반환
-- ============================================================

SELECT tests.authenticate_as('mrv_user_a');

SELECT is(
  (SELECT public.mark_match_results_viewed(
    current_setting('tests.mrv_app_a_id')::uuid
  )),
  true,
  'user_a: mark_match_results_viewed(자기 신청서) → true'
);

-- ============================================================
-- Test 4: 업데이트 후 NULL이 아님
-- ============================================================

SELECT isnt(
  (SELECT match_results_viewed_at FROM public.event_applications
   WHERE id = current_setting('tests.mrv_app_a_id')::uuid),
  NULL::timestamptz,
  'user_a 업데이트 후 match_results_viewed_at != NULL'
);

-- ============================================================
-- Test 5: 타인 신청서 RPC 호출 → permission denied 예외
-- ============================================================

SELECT throws_like(
  format(
    $$SELECT public.mark_match_results_viewed('%s'::uuid)$$,
    current_setting('tests.mrv_app_b_id')
  ),
  '%permission denied%',
  'user_a가 user_b 신청서 호출 시 permission denied 예외'
);

-- ============================================================
-- Test 6: 이미 set된 경우 idempotent (false 반환, 값 변경 없음)
-- ============================================================

SELECT is(
  (SELECT public.mark_match_results_viewed(
    current_setting('tests.mrv_app_a_id')::uuid
  )),
  false,
  'mark_match_results_viewed 재호출 시 false (이미 set, idempotent)'
);

SELECT * FROM finish();
ROLLBACK;
