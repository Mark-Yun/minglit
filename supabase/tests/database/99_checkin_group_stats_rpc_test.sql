BEGIN;
SELECT plan(5);

-- ============================================================
-- Setup: service role로 파트너/이벤트/엔트리그룹/티켓/참가자 데이터 구성
-- ============================================================

SELECT tests.authenticate_as_service_role();

SELECT tests.create_supabase_user('grp_staff');
SELECT tests.create_supabase_user('grp_no_perm');
SELECT tests.create_supabase_user('grp_user_a');
SELECT tests.create_supabase_user('grp_user_b');
SELECT tests.create_supabase_user('grp_user_c');

DO $$
DECLARE
  v_partner_id  uuid;
  v_party_id    uuid;
  v_event_id    uuid;
  v_group_a_id  uuid;
  v_group_b_id  uuid;
  v_ticket_a_id uuid;
  v_ticket_b_id uuid;
BEGIN
  INSERT INTO public.partners (name) VALUES ('Group Stats Test Partner')
  RETURNING id INTO v_partner_id;

  INSERT INTO public.partner_member_permissions (partner_id, user_id, role, permissions)
  VALUES (v_partner_id, tests.get_supabase_uid('grp_staff'), 'staff', ARRAY['PARTY_MANAGE']::text[]);

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
  VALUES (v_partner_id, 'Group Stats Party', 0, 20)
  RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants)
  VALUES (v_party_id, now() - interval '1 hour', now() + interval '2 hours', 0, 20)
  RETURNING id INTO v_event_id;

  -- 엔트리 그룹 2개
  INSERT INTO public.entry_groups (event_id, label) VALUES (v_event_id, 'Group A') RETURNING id INTO v_group_a_id;
  INSERT INTO public.entry_groups (event_id, label) VALUES (v_event_id, 'Group B') RETURNING id INTO v_group_b_id;

  -- 그룹별 티켓 (target_entry_group_ids로 연결)
  INSERT INTO public.tickets (event_id, name, quantity, price, target_entry_group_ids)
  VALUES (v_event_id, 'Ticket A', 10, 0, ARRAY[v_group_a_id]) RETURNING id INTO v_ticket_a_id;

  INSERT INTO public.tickets (event_id, name, quantity, price, target_entry_group_ids)
  VALUES (v_event_id, 'Ticket B', 10, 0, ARRAY[v_group_b_id]) RETURNING id INTO v_ticket_b_id;

  -- Group A: 1명 ticket_issued, 1명 checked_in → total=2, checked_in=1
  INSERT INTO public.event_participants (event_id, ticket_id, user_id, status, ticket_code, display_name)
  VALUES
    (v_event_id, v_ticket_a_id, tests.get_supabase_uid('grp_user_a'), 'ticket_issued', 'GA0001', 'User A'),
    (v_event_id, v_ticket_a_id, tests.get_supabase_uid('grp_user_b'), 'checked_in',    'GA0002', 'User B');

  -- Group B: 1명 ticket_issued → total=1, checked_in=0
  INSERT INTO public.event_participants (event_id, ticket_id, user_id, status, ticket_code, display_name)
  VALUES
    (v_event_id, v_ticket_b_id, tests.get_supabase_uid('grp_user_c'), 'ticket_issued', 'GB0001', 'User C');

  PERFORM set_config('tests.grp_event_id',  v_event_id::text,  true);
  PERFORM set_config('tests.grp_group_a_id', v_group_a_id::text, true);
  PERFORM set_config('tests.grp_group_b_id', v_group_b_id::text, true);
END $$;

-- ============================================================
-- Test 1: PARTY_MANAGE 없는 유저 → permission denied
-- ============================================================

SELECT tests.authenticate_as('grp_no_perm');

SELECT throws_like(
  format(
    $$SELECT public.get_event_checkin_stats_by_group('%s'::uuid)$$,
    current_setting('tests.grp_event_id')
  ),
  '%permission denied%',
  'get_event_checkin_stats_by_group: PARTY_MANAGE 없는 유저 → permission denied 예외'
);

-- ============================================================
-- Test 2: 존재하지 않는 event_id → event not found
-- ============================================================

SELECT tests.authenticate_as('grp_staff');

SELECT throws_like(
  $$SELECT public.get_event_checkin_stats_by_group(gen_random_uuid())$$,
  '%event not found%',
  'get_event_checkin_stats_by_group: 존재하지 않는 event_id → event not found 예외'
);

-- ============================================================
-- Test 3: 엔트리 그룹 없는 이벤트 → 빈 배열 반환
-- ============================================================

DO $$
DECLARE
  v_partner_id uuid;
  v_party_id   uuid;
  v_empty_event_id uuid;
BEGIN
  SELECT partner_id INTO v_partner_id
  FROM public.partner_member_permissions
  WHERE user_id = tests.get_supabase_uid('grp_staff');

  SELECT id INTO v_party_id FROM public.parties
  WHERE partner_id = v_partner_id LIMIT 1;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants)
  VALUES (v_party_id, now() - interval '2 hours', now() + interval '1 hour', 0, 5)
  RETURNING id INTO v_empty_event_id;

  PERFORM set_config('tests.grp_empty_event_id', v_empty_event_id::text, true);
END $$;

SELECT tests.authenticate_as('grp_staff');

SELECT is(
  public.get_event_checkin_stats_by_group(
    current_setting('tests.grp_empty_event_id')::uuid
  ),
  '[]'::jsonb,
  'get_event_checkin_stats_by_group: 엔트리 그룹 없는 이벤트 → 빈 배열 반환'
);

-- ============================================================
-- Test 4+5: 정상 케이스 — 그룹별 집계 검증
-- (Group A: total=2, checked_in=1 / Group B: total=1, checked_in=0)
-- ============================================================

SELECT is(
  (SELECT (elem ->> 'total')::int
   FROM jsonb_array_elements(
     public.get_event_checkin_stats_by_group(
       current_setting('tests.grp_event_id')::uuid
     )
   ) AS elem
   WHERE elem ->> 'id' = current_setting('tests.grp_group_a_id')),
  2,
  'get_event_checkin_stats_by_group: Group A total=2'
);

SELECT is(
  (SELECT (elem ->> 'checked_in')::int
   FROM jsonb_array_elements(
     public.get_event_checkin_stats_by_group(
       current_setting('tests.grp_event_id')::uuid
     )
   ) AS elem
   WHERE elem ->> 'id' = current_setting('tests.grp_group_a_id')),
  1,
  'get_event_checkin_stats_by_group: Group A checked_in=1'
);

SELECT * FROM finish();
ROLLBACK;
