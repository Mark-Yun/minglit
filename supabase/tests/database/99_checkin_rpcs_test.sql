BEGIN;
SELECT plan(9);

-- ============================================================
-- Setup: service role로 파트너/이벤트/참가자 데이터 구성
-- ============================================================

SELECT tests.authenticate_as_service_role();

SELECT tests.create_supabase_user('checkin_staff');
SELECT tests.create_supabase_user('checkin_no_perm');

DO $$
DECLARE
  v_partner_id  uuid;
  v_party_id    uuid;
  v_event_id    uuid;
  v_ticket_id   uuid;
BEGIN
  INSERT INTO public.partners (name)
  VALUES ('Checkin RPC Test Partner')
  RETURNING id INTO v_partner_id;

  -- PARTY_MANAGE 권한 부여
  INSERT INTO public.partner_member_permissions (partner_id, user_id, role, permissions)
  VALUES (
    v_partner_id,
    tests.get_supabase_uid('checkin_staff'),
    'staff',
    ARRAY['PARTY_MANAGE']::text[]
  );

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
  VALUES (v_partner_id, 'Checkin Test Party', 0, 10)
  RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants)
  VALUES (v_party_id, now() - interval '1 hour', now() + interval '2 hours', 0, 10)
  RETURNING id INTO v_event_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event_id, 'Checkin Ticket', 10, 0)
  RETURNING id INTO v_ticket_id;

  -- 체크인 대상 참가자: ticket_issued 1명, already_checked_in 테스트용 1명
  INSERT INTO public.event_participants (event_id, ticket_id, user_id, status, ticket_code, display_name)
  VALUES
    (v_event_id, v_ticket_id, tests.get_supabase_uid('checkin_staff'),   'ticket_issued', 'CODE0001', 'Staff User'),
    (v_event_id, v_ticket_id, tests.get_supabase_uid('checkin_no_perm'), 'checked_in',    'CODE0002', 'No Perm User');

  PERFORM set_config('tests.checkin_event_id',  v_event_id::text,  true);
  PERFORM set_config('tests.checkin_ticket_id', v_ticket_id::text, true);
END $$;

-- ============================================================
-- Test 1: process_qr_checkin — PARTY_MANAGE 없는 유저 → permission denied
-- ============================================================

SELECT tests.authenticate_as('checkin_no_perm');

SELECT throws_like(
  format(
    $$SELECT public.process_qr_checkin('%s'::uuid, '%s'::uuid, '%s'::uuid)$$,
    current_setting('tests.checkin_ticket_id'),
    current_setting('tests.checkin_event_id'),
    tests.get_supabase_uid('checkin_no_perm')
  ),
  '%permission denied%',
  'process_qr_checkin: PARTY_MANAGE 없는 유저 → permission denied 예외'
);

-- ============================================================
-- Test 2: process_qr_checkin — 존재하지 않는 ticket_id → not_found
-- ============================================================

SELECT tests.authenticate_as('checkin_staff');

SELECT is(
  public.process_qr_checkin(
    gen_random_uuid(),
    current_setting('tests.checkin_event_id')::uuid,
    tests.get_supabase_uid('checkin_staff')
  ),
  'not_found',
  'process_qr_checkin: 존재하지 않는 ticket_id → not_found'
);

-- ============================================================
-- Test 3: process_qr_checkin — 이미 checked_in 상태 → already_checked_in
-- (checkin_staff이 checkin_no_perm의 이미 체크인된 레코드를 재시도)
-- ============================================================

SELECT is(
  public.process_qr_checkin(
    current_setting('tests.checkin_ticket_id')::uuid,
    current_setting('tests.checkin_event_id')::uuid,
    tests.get_supabase_uid('checkin_no_perm')
  ),
  'already_checked_in',
  'process_qr_checkin: 이미 checked_in 상태 → already_checked_in'
);

-- ============================================================
-- Test 4~6: process_qr_checkin — 정상 체크인 → success + 상태 검증
-- ============================================================

SELECT is(
  public.process_qr_checkin(
    current_setting('tests.checkin_ticket_id')::uuid,
    current_setting('tests.checkin_event_id')::uuid,
    tests.get_supabase_uid('checkin_staff')
  ),
  'success',
  'process_qr_checkin: 정상 체크인 → success 반환'
);

SELECT tests.authenticate_as_service_role();

SELECT is(
  (SELECT status FROM public.event_participants
   WHERE event_id = current_setting('tests.checkin_event_id')::uuid
     AND user_id  = tests.get_supabase_uid('checkin_staff')),
  'checked_in',
  'process_qr_checkin: success 후 status = checked_in'
);

SELECT isnt(
  (SELECT checked_in_at FROM public.event_participants
   WHERE event_id = current_setting('tests.checkin_event_id')::uuid
     AND user_id  = tests.get_supabase_uid('checkin_staff')),
  null,
  'process_qr_checkin: success 후 checked_in_at 설정됨'
);

-- ============================================================
-- Test 7: get_event_checkin_stats — PARTY_MANAGE 없는 유저 → permission denied
-- ============================================================

SELECT tests.authenticate_as('checkin_no_perm');

SELECT throws_like(
  format(
    $$SELECT public.get_event_checkin_stats('%s'::uuid)$$,
    current_setting('tests.checkin_event_id')
  ),
  '%permission denied%',
  'get_event_checkin_stats: PARTY_MANAGE 없는 유저 → permission denied 예외'
);

-- ============================================================
-- Test 8: get_event_checkin_stats — 존재하지 않는 event_id → event not found
-- ============================================================

SELECT tests.authenticate_as('checkin_staff');

SELECT throws_like(
  $$SELECT public.get_event_checkin_stats(gen_random_uuid())$$,
  '%event not found%',
  'get_event_checkin_stats: 존재하지 않는 event_id → event not found 예외'
);

-- ============================================================
-- Test 9: get_event_checkin_stats — 정상 케이스 → total/checked_in 집계
-- (Test 4 이후: checkin_staff=checked_in, checkin_no_perm=checked_in → total=2, checked_in=2)
-- ============================================================

SELECT is(
  public.get_event_checkin_stats(
    current_setting('tests.checkin_event_id')::uuid
  ),
  jsonb_build_object('total', 2, 'checked_in', 2),
  'get_event_checkin_stats: total=2, checked_in=2 집계 정확'
);

SELECT * FROM finish();
ROLLBACK;
