-- pgTAP tests for #1705: event_participants 이벤트 종료 후 30일 PII 익명화 (PIPA §21)
--
-- 검증 항목:
--   1. retention_policies 등록 확인 (kind, retention_days, enabled)
--   2. anonymize_old_event_participants 함수 시그니처
--   3. 익명화 로직: events.end_time 기준 30일 이후 행의 PII(display_name/birth_year)만 NULL
--   4. 아직 30일 미경과 행은 PII 보존
--   5. 참가 레코드 자체는 삭제되지 않음 (집계 무결성 보호)
BEGIN;

SELECT plan(11);

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
  '#1705: policy enabled = true'
);

-- 5. target.fn 존재
SELECT ok(
  (SELECT target->>'fn' FROM admin.retention_policies WHERE id = 'event_participants_post_event') IS NOT NULL,
  '#1705: target.fn set'
);

-- ── 2. 함수 시그니처 확인 ─────────────────────────────────────────────────────

-- 6. anonymize_old_event_participants(int) 함수 존재
SELECT ok(
  EXISTS(
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'admin'
      AND p.proname = 'anonymize_old_event_participants'
  ),
  '#1705: admin.anonymize_old_event_participants function exists'
);

-- ── 3. 익명화 로직 검증 ───────────────────────────────────────────────────────

-- fixtures
DO $$
DECLARE
  v_user_id    uuid;
  v_partner_id uuid;
  v_party_id   uuid;
  v_event_old  uuid;  -- 종료 후 31일 이상 (익명화 대상)
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

  -- old event: ended 31 days ago → PII 익명화 대상
  INSERT INTO public.events (party_id, start_time, end_time, status)
  VALUES (v_party_id, now() - INTERVAL '32 days', now() - INTERVAL '31 days', 'completed')
  RETURNING id INTO v_event_old;

  -- new event: ended 20 days ago → PII 보존 대상
  INSERT INTO public.events (party_id, start_time, end_time, status)
  VALUES (v_party_id, now() - INTERVAL '21 days', now() - INTERVAL '20 days', 'completed')
  RETURNING id INTO v_event_new;

  INSERT INTO public.tickets (event_id, name, price, quantity)
  VALUES (v_event_old, 'Old Event Ticket', 0, 10) RETURNING id INTO v_ticket_old;
  INSERT INTO public.tickets (event_id, name, price, quantity)
  VALUES (v_event_new, 'New Event Ticket', 0, 10) RETURNING id INTO v_ticket_new;

  -- participants with PII
  INSERT INTO public.event_participants (event_id, ticket_id, user_id, display_name, birth_year)
  VALUES (v_event_old, v_ticket_old, v_user_id, 'OldParticipant', 1990);
  INSERT INTO public.event_participants (event_id, ticket_id, user_id, display_name, birth_year)
  VALUES (v_event_new, v_ticket_new, v_user_id, 'NewParticipant', 1991);

  PERFORM set_config('ep_test.event_old', v_event_old::text, true);
  PERFORM set_config('ep_test.event_new', v_event_new::text, true);
END $$;

-- 7. fixture: old event participant has PII before anonymization
SELECT ok(
  (SELECT display_name FROM public.event_participants
    WHERE event_id = current_setting('ep_test.event_old')::uuid) = 'OldParticipant',
  'fixture: old event participant has display_name before anonymization'
);

-- run the anonymization function (30-day cutoff)
SELECT admin.anonymize_old_event_participants(30);

-- 8. old event participant PII is anonymized (display_name = NULL)
SELECT ok(
  (SELECT display_name FROM public.event_participants
    WHERE event_id = current_setting('ep_test.event_old')::uuid) IS NULL,
  '#1705 PIPA §21: display_name anonymized for event ended 31 days ago'
);

-- 9. old event participant birth_year is anonymized (NULL)
SELECT ok(
  (SELECT birth_year FROM public.event_participants
    WHERE event_id = current_setting('ep_test.event_old')::uuid) IS NULL,
  '#1705 PIPA §21: birth_year anonymized for event ended 31 days ago'
);

-- 10. participation record still exists (no row deletion — preserves aggregate counts)
SELECT ok(
  EXISTS(
    SELECT 1 FROM public.event_participants
    WHERE event_id = current_setting('ep_test.event_old')::uuid
  ),
  '#1705: participation row preserved (only PII columns NULLed, aggregate counts intact)'
);

-- 11. new event participant PII is preserved (ended 20 days ago)
SELECT ok(
  (SELECT display_name FROM public.event_participants
    WHERE event_id = current_setting('ep_test.event_new')::uuid) = 'NewParticipant',
  '#1705 PIPA §21: display_name preserved for event ended 20 days ago (within 30-day window)'
);

SELECT * FROM finish();
ROLLBACK;
