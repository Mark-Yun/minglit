-- Fix #189: get_event_ticket_balance_status의 allowed 필드가 boolean으로 반환되는지 회귀 테스트
BEGIN;
SELECT plan(2);

SELECT tests.authenticate_as_service_role();

-- ============================================================
-- Test 1: allowed 필드가 boolean 타입인지 확인 (string이 아닌)
-- ============================================================

CREATE TEMP TABLE balance_status_type_results (
  allowed_is_boolean boolean,
  allowed_value boolean
);

DO $$
DECLARE
  v_partner_id uuid;
  v_party_id uuid;
  v_event_id uuid;
  v_ticket_id uuid;
  v_result jsonb;
  v_first_item jsonb;
BEGIN
  INSERT INTO public.partners (name)
  VALUES ('Balance Type Test Partner')
  RETURNING id INTO v_partner_id;

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants, balance_config)
  VALUES (v_partner_id, 'Party Type Test', 0, 10, null)
  RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants)
  VALUES (v_party_id, now() + interval '1 day', now() + interval '1 day 2 hours', 0, 10)
  RETURNING id INTO v_event_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event_id, 'Ticket Type Test', 10, 1000)
  RETURNING id INTO v_ticket_id;

  v_result := public.get_event_ticket_balance_status(v_event_id);
  v_first_item := v_result->0;

  -- jsonb_typeof returns 'boolean' for true/false, 'string' for "true"/"false"
  INSERT INTO balance_status_type_results (allowed_is_boolean, allowed_value)
  VALUES (
    jsonb_typeof(v_first_item->'allowed') = 'boolean',
    (v_first_item->>'allowed')::boolean
  );
END $$;

SELECT is(
  (SELECT allowed_is_boolean FROM balance_status_type_results),
  true,
  'get_event_ticket_balance_status: allowed 필드는 boolean 타입이어야 함 (string 아님)'
);

SELECT is(
  (SELECT allowed_value FROM balance_status_type_results),
  true,
  'get_event_ticket_balance_status: balance_config null → allowed: true'
);

SELECT * FROM finish();
ROLLBACK;
