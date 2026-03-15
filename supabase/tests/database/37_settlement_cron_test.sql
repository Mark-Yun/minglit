BEGIN;
SELECT plan(7);

SELECT tests.authenticate_as_service_role();

-- NOTE: freeze_time은 SECURITY DEFINER + SET search_path 함수에서 작동하지 않으므로
-- event_date를 실제 now() 기준 상대값으로 설정

CREATE TEMP TABLE cron_results (
  label text,
  event_id uuid,
  status text
);

DO $$
DECLARE
  v_partner_id   uuid;
  v_party_id     uuid;
  v_event_8d     uuid;
  v_event_6d     uuid;
  v_event_7d     uuid;
  v_event_ready  uuid;
  v_event_a      uuid;
  v_event_b      uuid;
  v_event_c      uuid;
BEGIN
  INSERT INTO public.partners (name) VALUES ('Cron Partner') RETURNING id INTO v_partner_id;

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
    VALUES (v_partner_id, 'Cron Party', 0, 10) RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
    VALUES (v_party_id, now() - interval '9 days', now() - interval '8 days', 0, 10, 'completed')
    RETURNING id INTO v_event_8d;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
    VALUES (v_party_id, now() - interval '7 days', now() - interval '6 days', 0, 10, 'completed')
    RETURNING id INTO v_event_6d;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
    VALUES (v_party_id, now() - interval '8 days', now() - interval '7 days', 0, 10, 'completed')
    RETURNING id INTO v_event_7d;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
    VALUES (v_party_id, now() - interval '15 days', now() - interval '14 days', 0, 10, 'completed')
    RETURNING id INTO v_event_ready;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
    VALUES (v_party_id, now() - interval '11 days', now() - interval '10 days', 0, 10, 'completed')
    RETURNING id INTO v_event_a;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
    VALUES (v_party_id, now() - interval '4 days', now() - interval '3 days', 0, 10, 'completed')
    RETURNING id INTO v_event_b;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
    VALUES (v_party_id, now() - interval '10 days', now() - interval '9 days', 0, 10, 'completed')
    RETURNING id INTO v_event_c;

  INSERT INTO public.settlements (partner_id, event_id, event_title, event_date, total_sales, total_refunds, pg_fee, platform_fee, vat, net_amount, status)
    VALUES (v_partner_id, v_event_8d, '8일전 이벤트', now() - interval '8 days', 0, 0, 0, 0, 0, 0, 'pending');

  INSERT INTO public.settlements (partner_id, event_id, event_title, event_date, total_sales, total_refunds, pg_fee, platform_fee, vat, net_amount, status)
    VALUES (v_partner_id, v_event_6d, '6일전 이벤트', now() - interval '6 days', 0, 0, 0, 0, 0, 0, 'pending');

  INSERT INTO public.settlements (partner_id, event_id, event_title, event_date, total_sales, total_refunds, pg_fee, platform_fee, vat, net_amount, status)
    VALUES (v_partner_id, v_event_7d, '7일전 이벤트', now() - interval '7 days', 0, 0, 0, 0, 0, 0, 'pending');

  INSERT INTO public.settlements (partner_id, event_id, event_title, event_date, total_sales, total_refunds, pg_fee, platform_fee, vat, net_amount, status)
    VALUES (v_partner_id, v_event_ready, '이미ready 이벤트', now() - interval '14 days', 0, 0, 0, 0, 0, 0, 'ready');

  INSERT INTO public.settlements (partner_id, event_id, event_title, event_date, total_sales, total_refunds, pg_fee, platform_fee, vat, net_amount, status)
    VALUES (v_partner_id, v_event_a, '다중A 이벤트', now() - interval '10 days', 0, 0, 0, 0, 0, 0, 'pending');

  INSERT INTO public.settlements (partner_id, event_id, event_title, event_date, total_sales, total_refunds, pg_fee, platform_fee, vat, net_amount, status)
    VALUES (v_partner_id, v_event_b, '다중B 이벤트', now() - interval '3 days', 0, 0, 0, 0, 0, 0, 'pending');

  INSERT INTO public.settlements (partner_id, event_id, event_title, event_date, total_sales, total_refunds, pg_fee, platform_fee, vat, net_amount, status)
    VALUES (v_partner_id, v_event_c, '다중C 이벤트', now() - interval '9 days', 0, 0, 0, 0, 0, 0, 'pending');

  PERFORM public.update_settlement_ready_status();

  INSERT INTO cron_results (label, event_id, status)
    SELECT event_title, event_id, status
    FROM public.settlements
    WHERE partner_id = v_partner_id;
END $$;

SELECT is(
  (SELECT status FROM cron_results WHERE label = '8일전 이벤트'),
  'ready',
  '케이스1: event_date 8일 전 → ready 전환'
);

SELECT is(
  (SELECT status FROM cron_results WHERE label = '6일전 이벤트'),
  'pending',
  '케이스2: event_date 6일 전 → pending 유지 (7일 미경과)'
);

SELECT is(
  (SELECT status FROM cron_results WHERE label = '7일전 이벤트'),
  'ready',
  '케이스3: event_date 정확히 7일 전 → ready 전환 (경계 조건 <=)'
);

SELECT is(
  (SELECT status FROM cron_results WHERE label = '이미ready 이벤트'),
  'ready',
  '케이스4: 이미 ready → 변경 없음 (status=pending 조건으로 제외)'
);

SELECT is(
  (SELECT status FROM cron_results WHERE label = '다중A 이벤트'),
  'ready',
  '케이스5-A: 다중 중 10일 전 → ready 전환'
);

SELECT is(
  (SELECT status FROM cron_results WHERE label = '다중B 이벤트'),
  'pending',
  '케이스5-B: 다중 중 3일 전 → pending 유지'
);

SELECT is(
  (SELECT status FROM cron_results WHERE label = '다중C 이벤트'),
  'ready',
  '케이스5-C: 다중 중 9일 전 → ready 전환'
);

SELECT * FROM finish();
ROLLBACK;
