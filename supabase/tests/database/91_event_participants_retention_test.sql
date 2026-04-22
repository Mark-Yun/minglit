-- pgTAP tests for #1705: event_participants 이벤트 종료 후 30일 파기 (PIPA §21)
--
-- 검증 항목:
--   1. retention_policies 등록 확인 (kind, retention_days, enabled)
--   2. delete_old_event_participants 함수 시그니처
--   3. 실제 파기 로직: events.end_time 기준 30일 이후 행만 삭제
--   4. 아직 30일 미경과 행은 보존
BEGIN;

SELECT plan(10);

SELECT tests.authenticate_as_service_role();

-- ── 1. retention_policies 등록 확인 ──────────────────────────────────────────

-- 1. policy 존재
SELECT ok(
  EXISTS (SELECT 1 FROM admin.retention_policies WHERE id = 'event_participants_post_event'),
  '#1705: event_participants_post_event policy registered'
);

-- 2. kind = db_custom_fn
SELECT is(
  (SELECT kind::text FROM admin.retention_policies WHERE id = 'event_participants_post_event'),
  'db_custom_fn',
  '#1705: policy kind is db_custom_fn'
);

-- 3. retention_days = 30
SELECT is(
  (SELECT retention_days FROM admin.retention_policies WHERE id = 'event_participants_post_event'),
  30,
  '#1705: retention_days = 30 (이벤트 종료 후 30일)'
);

-- 4. enabled = true
SELECT ok(
  (SELECT enabled FROM admin.retention_policies WHERE id = 'event_participants_post_event'),
  '#1705: policy enabled = true (자동 파기 활성)'
);

-- 5. target.fn 존재
SELECT ok(
  (SELECT target->>'fn' FROM admin.retention_policies WHERE id = 'event_participants_post_event') IS NOT NULL,
  '#1705: target.fn set (custom function name)'
);

-- ── 2. 함수 시그니처 확인 ─────────────────────────────────────────────────────

-- 6. delete_old_event_participants(int) 함수 존재
SELECT ok(
  EXISTS(
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'admin'
      AND p.proname = 'delete_old_event_participants'
  ),
  '#1705: admin.delete_old_event_participants function exists'
);

-- ── 3. 파기 로직 검증 ─────────────────────────────────────────────────────────

-- fixtures
DO $$
DECLARE
  v_user_id    uuid;
  v_partner_id uuid;
  v_party_id   uuid;
  v_event_old  uuid;  -- 종료 후 31일 이상 (파기 대상)
  v_event_new  uuid;  -- 종료 후 20일 (보존 대상)
  v_ticket_old uuid;
  v_ticket_new uuid;
BEGIN
  v_user_id := tests.create_supabase_user(
    'ep_retention_test_1705',
    'ep_retention_test_1705@pgtap.local'
  );

  INSERT INTO public.partners (name) VALUES ('Test Partner 1705') RETURNING id INTO v_partner_id;
  INSERT INTO public.parties (partner_id, title) VALUES (v_partner_id, 'Test Party 1705') RETURNING id INTO v_party_id;

  -- old event: ended 31 days ago → 파기 대상
  INSERT INTO public.events (party_id, start_time, end_time, status)
  VALUES (v_party_id, now() - INTERVAL '32 days', now() - INTERVAL '31 days', 'completed')
  RETURNING id INTO v_event_old;

  -- new event: ended 20 days ago → 보존 대상
  INSERT INTO public.events (party_id, start_time, end_time, status)
  VALUES (v_party_id, now() - INTERVAL '21 days', now() - INTERVAL '20 days', 'completed')
  RETURNING id INTO v_event_new;

  INSERT INTO public.tickets (event_id, name, price, quantity)
  VALUES (v_event_old, 'Old Event Ticket', 0, 10) RETURNING id INTO v_ticket_old;
  INSERT INTO public.tickets (event_id, name, price, quantity)
  VALUES (v_event_new, 'New Event Ticket', 0, 10) RETURNING id INTO v_ticket_new;

  INSERT INTO public.event_participants (event_id, ticket_id, user_id, display_name, birth_year)
  VALUES (v_event_old, v_ticket_old, v_user_id, 'OldParticipant', 1990);
  INSERT INTO public.event_participants (event_id, ticket_id, user_id, display_name, birth_year)
  VALUES (v_event_new, v_ticket_new, v_user_id, 'NewParticipant', 1990);

  PERFORM set_config('ep_test.event_old', v_event_old::text, true);
  PERFORM set_config('ep_test.event_new', v_event_new::text, true);
END $$;

-- 7. fixture: old event participant exists before purge
SELECT ok(
  EXISTS(
    SELECT 1 FROM public.event_participants
    WHERE event_id = current_setting('ep_test.event_old')::uuid
  ),
  'fixture: old event participant exists before purge'
);

-- 8. fixture: new event participant exists before purge
SELECT ok(
  EXISTS(
    SELECT 1 FROM public.event_participants
    WHERE event_id = current_setting('ep_test.event_new')::uuid
  ),
  'fixture: new event participant exists before purge'
);

-- run the purge function (30-day cutoff)
SELECT admin.delete_old_event_participants(30);

-- 9. old event participant is purged (ended 31 days ago)
SELECT ok(
  NOT EXISTS(
    SELECT 1 FROM public.event_participants
    WHERE event_id = current_setting('ep_test.event_old')::uuid
  ),
  '#1705 PIPA §21: event_participants purged for event ended 31 days ago'
);

-- 10. new event participant is preserved (ended 20 days ago)
SELECT ok(
  EXISTS(
    SELECT 1 FROM public.event_participants
    WHERE event_id = current_setting('ep_test.event_new')::uuid
  ),
  '#1705 PIPA §21: event_participants preserved for event ended 20 days ago (within 30-day window)'
);

SELECT * FROM finish();
ROLLBACK;
