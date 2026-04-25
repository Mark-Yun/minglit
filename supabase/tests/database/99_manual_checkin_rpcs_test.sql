BEGIN;
SELECT plan(11);

-- ============================================================
-- Setup: service role로 파트너/이벤트/티켓/참가자 데이터 구성
-- ============================================================

SELECT tests.authenticate_as_service_role();

SELECT tests.create_supabase_user('mc_staff');
SELECT tests.create_supabase_user('mc_no_perm');
SELECT tests.create_supabase_user('mc_user_a');
SELECT tests.create_supabase_user('mc_user_b');
SELECT tests.create_supabase_user('mc_user_c');

DO $$
DECLARE
  v_partner_id       uuid;
  v_party_id         uuid;
  v_event_id         uuid;
  v_ticket_id        uuid;
  v_ticket_b_id      uuid;
  v_ticket_c_id      uuid;
  v_cancelled_evt_id uuid;
  v_ticket_d_id      uuid;
BEGIN
  INSERT INTO public.partners (name) VALUES ('Manual Checkin Test Partner')
  RETURNING id INTO v_partner_id;

  INSERT INTO public.partner_member_permissions (partner_id, user_id, role, permissions)
  VALUES (v_partner_id, tests.get_supabase_uid('mc_staff'), 'staff', ARRAY['PARTY_MANAGE']::text[]);

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
  VALUES (v_partner_id, 'Manual Checkin Party', 0, 20)
  RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants)
  VALUES (v_party_id, now() - interval '1 hour', now() + interval '2 hours', 0, 20)
  RETURNING id INTO v_event_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event_id, 'Ticket A', 10, 0) RETURNING id INTO v_ticket_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event_id, 'Ticket B', 10, 0) RETURNING id INTO v_ticket_b_id;

  -- mc_user_a: ticket_issued
  INSERT INTO public.event_participants (event_id, ticket_id, user_id, status, ticket_code, display_name)
  VALUES (v_event_id, v_ticket_id, tests.get_supabase_uid('mc_user_a'), 'ticket_issued', 'MC0001', 'User A');

  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event_id, 'Ticket C', 10, 0) RETURNING id INTO v_ticket_c_id;

  -- mc_user_b: already checked_in
  INSERT INTO public.event_participants (event_id, ticket_id, user_id, status, ticket_code, display_name, checked_in_at)
  VALUES (v_event_id, v_ticket_b_id, tests.get_supabase_uid('mc_user_b'), 'checked_in', 'MC0002', 'User B', now());

  -- mc_user_c: no_show (체크인 불가 상태)
  INSERT INTO public.event_participants (event_id, ticket_id, user_id, status, ticket_code, display_name)
  VALUES (v_event_id, v_ticket_c_id, tests.get_supabase_uid('mc_user_c'), 'no_show', 'MC0003', 'User C');

  -- cancelled 이벤트 (이벤트 상태 게이트 테스트용)
  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
  VALUES (v_party_id, now() - interval '3 hours', now() - interval '1 hour', 0, 20, 'cancelled')
  RETURNING id INTO v_cancelled_evt_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_cancelled_evt_id, 'Ticket D', 10, 0) RETURNING id INTO v_ticket_d_id;

  INSERT INTO public.event_participants (event_id, ticket_id, user_id, status, ticket_code, display_name)
  VALUES (v_cancelled_evt_id, v_ticket_d_id, tests.get_supabase_uid('mc_user_a'), 'ticket_issued', 'MC0004', 'User A Cancelled');

  PERFORM set_config('tests.mc_event_id',         v_event_id::text,         true);
  PERFORM set_config('tests.mc_ticket_id',         v_ticket_id::text,        true);
  PERFORM set_config('tests.mc_ticket_b_id',       v_ticket_b_id::text,      true);
  PERFORM set_config('tests.mc_ticket_c_id',       v_ticket_c_id::text,      true);
  PERFORM set_config('tests.mc_cancelled_evt_id',  v_cancelled_evt_id::text, true);
  PERFORM set_config('tests.mc_ticket_d_id',       v_ticket_d_id::text,      true);
END $$;

-- ============================================================
-- Test 1: PARTY_MANAGE 없는 유저 → get_event_participants_for_checkin permission denied
-- ============================================================

SELECT tests.authenticate_as('mc_no_perm');

SELECT throws_like(
  format(
    $$SELECT public.get_event_participants_for_checkin('%s'::uuid)$$,
    current_setting('tests.mc_event_id')
  ),
  '%permission denied%',
  'get_event_participants_for_checkin: PARTY_MANAGE 없는 유저 → permission denied'
);

-- ============================================================
-- Test 2: 존재하지 않는 event_id → event not found
-- ============================================================

SELECT tests.authenticate_as('mc_staff');

SELECT throws_like(
  $$SELECT public.get_event_participants_for_checkin(gen_random_uuid())$$,
  '%event not found%',
  'get_event_participants_for_checkin: 존재하지 않는 event_id → event not found'
);

-- ============================================================
-- Test 3: 정상 조회 — ticket_issued + checked_in만 반환 (no_show 제외)
-- ============================================================

SELECT is(
  (SELECT jsonb_array_length(
    public.get_event_participants_for_checkin(
      current_setting('tests.mc_event_id')::uuid
    )
  )),
  2,
  'get_event_participants_for_checkin: 참가자 2명 반환 (no_show 제외)'
);

-- ============================================================
-- Test 4: 미체크인 참가자가 먼저 정렬 (User A = ticket_issued)
-- ============================================================

SELECT is(
  (SELECT (elem ->> 'status')
   FROM jsonb_array_elements(
     public.get_event_participants_for_checkin(
       current_setting('tests.mc_event_id')::uuid
     )
   ) WITH ORDINALITY AS t(elem, ord)
   WHERE ord = 1),
  'ticket_issued',
  'get_event_participants_for_checkin: 미체크인 참가자가 첫 번째'
);

-- ============================================================
-- Test 5: PARTY_MANAGE 없는 유저 → process_manual_checkin permission denied
-- ============================================================

SELECT tests.authenticate_as('mc_no_perm');

SELECT throws_like(
  format(
    $$SELECT public.process_manual_checkin('%s'::uuid, '%s'::uuid)$$,
    current_setting('tests.mc_ticket_id'),
    current_setting('tests.mc_event_id')
  ),
  '%permission denied%',
  'process_manual_checkin: PARTY_MANAGE 없는 유저 → permission denied'
);

-- ============================================================
-- Test 6: 존재하지 않는 ticket_id → not_found
-- ============================================================

SELECT tests.authenticate_as('mc_staff');

SELECT is(
  public.process_manual_checkin(
    gen_random_uuid(),
    current_setting('tests.mc_event_id')::uuid
  ),
  'not_found',
  'process_manual_checkin: 존재하지 않는 ticket_id → not_found'
);

-- ============================================================
-- Test 7: 이미 checked_in 상태 → already_checked_in
-- ============================================================

SELECT is(
  public.process_manual_checkin(
    current_setting('tests.mc_ticket_b_id')::uuid,
    current_setting('tests.mc_event_id')::uuid
  ),
  'already_checked_in',
  'process_manual_checkin: 이미 체크인된 참가자 → already_checked_in'
);

-- ============================================================
-- Test 8: 정상 체크인 → success + status 변경 확인
-- ============================================================

SELECT is(
  public.process_manual_checkin(
    current_setting('tests.mc_ticket_id')::uuid,
    current_setting('tests.mc_event_id')::uuid
  ),
  'success',
  'process_manual_checkin: 정상 체크인 → success'
);

SELECT is(
  (SELECT status FROM public.event_participants
   WHERE ticket_id = current_setting('tests.mc_ticket_id')::uuid
     AND event_id  = current_setting('tests.mc_event_id')::uuid),
  'checked_in',
  'process_manual_checkin: 체크인 후 status = checked_in'
);

SELECT tests.authenticate_as_service_role();

-- ============================================================
-- Test 10: no_show 참가자 → not_found (ticket_issued 외 상태 차단)
-- ============================================================

SELECT tests.authenticate_as('mc_staff');

SELECT is(
  public.process_manual_checkin(
    current_setting('tests.mc_ticket_c_id')::uuid,
    current_setting('tests.mc_event_id')::uuid
  ),
  'not_found',
  'process_manual_checkin: no_show 참가자 → not_found (상태 전이 차단)'
);

-- ============================================================
-- Test 11: cancelled 이벤트 → not_found (이벤트 상태 게이트)
-- ============================================================

SELECT is(
  public.process_manual_checkin(
    current_setting('tests.mc_ticket_d_id')::uuid,
    current_setting('tests.mc_cancelled_evt_id')::uuid
  ),
  'not_found',
  'process_manual_checkin: cancelled 이벤트 → not_found (이벤트 상태 게이트)'
);

SELECT * FROM finish();
ROLLBACK;
