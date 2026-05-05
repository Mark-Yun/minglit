BEGIN;
SELECT plan(8);

-- ============================================================
-- Setup: service role로 파트너/이벤트/엔트리그룹/티켓/참가자 데이터 구성
-- ============================================================

SELECT tests.authenticate_as_service_role();

SELECT tests.create_supabase_user('egpc_user_a');
SELECT tests.create_supabase_user('egpc_user_b');
SELECT tests.create_supabase_user('egpc_user_c');
SELECT tests.create_supabase_user('egpc_anon');
SELECT tests.create_supabase_user('egpc_no_perm');

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
  INSERT INTO public.partners (name) VALUES ('EGPC Test Partner')
  RETURNING id INTO v_partner_id;

  -- egpc_anon을 파트너 owner로 등록 (PARTY_MANAGE 권한 부여)
  INSERT INTO public.partner_member_permissions (partner_id, user_id, role)
  VALUES (v_partner_id, tests.get_supabase_uid('egpc_anon'), 'owner');

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
  VALUES (v_partner_id, 'EGPC Party', 0, 30)
  RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants)
  VALUES (v_party_id, now() + interval '1 day', now() + interval '1 day' + interval '2 hours', 0, 30)
  RETURNING id INTO v_event_id;

  -- 엔트리 그룹 2개
  INSERT INTO public.entry_groups (event_id, label) VALUES (v_event_id, 'Group A') RETURNING id INTO v_group_a_id;
  INSERT INTO public.entry_groups (event_id, label) VALUES (v_event_id, 'Group B') RETURNING id INTO v_group_b_id;

  -- Group A 티켓: quantity=10
  INSERT INTO public.tickets (event_id, name, quantity, price, target_entry_group_ids)
  VALUES (v_event_id, 'Ticket A', 10, 0, ARRAY[v_group_a_id]) RETURNING id INTO v_ticket_a_id;

  -- Group B 티켓: quantity=15
  INSERT INTO public.tickets (event_id, name, quantity, price, target_entry_group_ids)
  VALUES (v_event_id, 'Ticket B', 15, 0, ARRAY[v_group_b_id]) RETURNING id INTO v_ticket_b_id;

  -- Group A 참가자: 2명
  INSERT INTO public.event_participants (event_id, ticket_id, user_id, status, ticket_code, display_name)
  VALUES
    (v_event_id, v_ticket_a_id, tests.get_supabase_uid('egpc_user_a'), 'ticket_issued', 'A0001', 'User A'),
    (v_event_id, v_ticket_a_id, tests.get_supabase_uid('egpc_user_b'), 'ticket_issued', 'A0002', 'User B');

  -- Group B 참가자: 1명
  INSERT INTO public.event_participants (event_id, ticket_id, user_id, status, ticket_code, display_name)
  VALUES
    (v_event_id, v_ticket_b_id, tests.get_supabase_uid('egpc_user_c'), 'ticket_issued', 'B0001', 'User C');

  PERFORM set_config('tests.egpc_partner_id',  v_partner_id::text,  true);
  PERFORM set_config('tests.egpc_event_id',    v_event_id::text,    true);
  PERFORM set_config('tests.egpc_group_a_id',  v_group_a_id::text,  true);
  PERFORM set_config('tests.egpc_group_b_id',  v_group_b_id::text,  true);
END $$;

-- ============================================================
-- Test 1: PARTY_MANAGE 권한 파트너는 RPC 호출 가능
-- ============================================================

SELECT tests.authenticate_as('egpc_anon');

SELECT ok(
  (SELECT count(*) FROM public.get_entry_group_participant_counts(
    current_setting('tests.egpc_event_id')::uuid
  )) = 2,
  'get_entry_group_participant_counts: 2개 엔트리 그룹 반환'
);

-- ============================================================
-- Test 2: Group A target_capacity = 10 (Ticket A quantity)
-- ============================================================

SELECT is(
  (SELECT target_capacity FROM public.get_entry_group_participant_counts(
    current_setting('tests.egpc_event_id')::uuid
  ) WHERE entry_group_id = current_setting('tests.egpc_group_a_id')::uuid),
  10::bigint,
  'get_entry_group_participant_counts: Group A target_capacity = 10'
);

-- ============================================================
-- Test 3: Group B target_capacity = 15 (Ticket B quantity)
-- ============================================================

SELECT is(
  (SELECT target_capacity FROM public.get_entry_group_participant_counts(
    current_setting('tests.egpc_event_id')::uuid
  ) WHERE entry_group_id = current_setting('tests.egpc_group_b_id')::uuid),
  15::bigint,
  'get_entry_group_participant_counts: Group B target_capacity = 15'
);

-- ============================================================
-- Test 4: Group A participant_count = 2
-- ============================================================

SELECT is(
  (SELECT participant_count FROM public.get_entry_group_participant_counts(
    current_setting('tests.egpc_event_id')::uuid
  ) WHERE entry_group_id = current_setting('tests.egpc_group_a_id')::uuid),
  2::bigint,
  'get_entry_group_participant_counts: Group A participant_count = 2'
);

-- ============================================================
-- Test 5: Group B participant_count = 1
-- ============================================================

SELECT is(
  (SELECT participant_count FROM public.get_entry_group_participant_counts(
    current_setting('tests.egpc_event_id')::uuid
  ) WHERE entry_group_id = current_setting('tests.egpc_group_b_id')::uuid),
  1::bigint,
  'get_entry_group_participant_counts: Group B participant_count = 1'
);

-- ============================================================
-- Test 6: 엔트리 그룹 없는 이벤트 → 빈 결과
-- ============================================================

SELECT tests.authenticate_as_service_role();

DO $$
DECLARE
  v_partner_id uuid;
  v_party_id   uuid;
  v_empty_event_id uuid;
BEGIN
  v_partner_id := current_setting('tests.egpc_partner_id')::uuid;

  SELECT id INTO v_party_id FROM public.parties WHERE partner_id = v_partner_id LIMIT 1;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants)
  VALUES (v_party_id, now() + interval '2 days', now() + interval '2 days' + interval '2 hours', 0, 10)
  RETURNING id INTO v_empty_event_id;

  PERFORM set_config('tests.egpc_empty_event_id', v_empty_event_id::text, true);
END $$;

SELECT tests.authenticate_as('egpc_anon');

SELECT is(
  (SELECT count(*) FROM public.get_entry_group_participant_counts(
    current_setting('tests.egpc_empty_event_id')::uuid
  )),
  0::bigint,
  'get_entry_group_participant_counts: 엔트리 그룹 없는 이벤트 → 0건'
);

-- ============================================================
-- Test 7: soft-deleted 참가자는 participant_count에서 제외 (security definer + 명시 필터)
-- ============================================================

SELECT tests.authenticate_as_service_role();

SELECT tests.create_supabase_user('egpc_deleted_user');

DO $$
DECLARE
  v_event_id    uuid;
  v_group_a_id  uuid;
  v_ticket_a_id uuid;
BEGIN
  v_event_id   := current_setting('tests.egpc_event_id')::uuid;
  v_group_a_id := current_setting('tests.egpc_group_a_id')::uuid;

  SELECT id INTO v_ticket_a_id
  FROM public.tickets
  WHERE event_id = v_event_id AND name = 'Ticket A'
  LIMIT 1;

  -- soft-deleted 유저를 Group A 참가자로 추가 (before delete)
  INSERT INTO public.event_participants (event_id, ticket_id, user_id, status, ticket_code, display_name)
  VALUES (v_event_id, v_ticket_a_id, tests.get_supabase_uid('egpc_deleted_user'), 'ticket_issued', 'A9999', 'Deleted User');

  -- 유저 soft-delete
  UPDATE public.user_profiles
  SET deleted_at = now()
  WHERE id = tests.get_supabase_uid('egpc_deleted_user');
END $$;

SELECT tests.authenticate_as('egpc_anon');

-- soft-delete 전 Group A participant_count는 2였음 — soft-delete 후에도 2 유지 (삭제 유저 제외)
SELECT is(
  (SELECT participant_count FROM public.get_entry_group_participant_counts(
    current_setting('tests.egpc_event_id')::uuid
  ) WHERE entry_group_id = current_setting('tests.egpc_group_a_id')::uuid),
  2::bigint,
  'get_entry_group_participant_counts: soft-deleted 참가자는 participant_count에서 제외'
);

-- ============================================================
-- Test 8: PARTY_MANAGE 없는 일반 유저도 RPC 호출 가능 (Fix #2254)
-- 참가자 수는 공개 정보 — PARTY_MANAGE 체크 제거됨
-- ============================================================

SELECT tests.authenticate_as('egpc_no_perm');

SELECT ok(
  (SELECT count(*) FROM public.get_entry_group_participant_counts(
    current_setting('tests.egpc_event_id')::uuid
  )) = 2,
  'get_entry_group_participant_counts: PARTY_MANAGE 없는 일반 유저도 호출 가능 (Fix #2254)'
);

SELECT * FROM finish();
ROLLBACK;
