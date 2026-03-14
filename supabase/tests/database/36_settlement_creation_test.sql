BEGIN;
SELECT plan(14);

SELECT tests.authenticate_as_service_role();

-- ============================================================
-- 시나리오 1: total_sales=100000
-- pg_fee=3500, platform_fee=5000, vat=850, net_amount=90650
-- ============================================================

CREATE TEMP TABLE s1 (pg_fee int, platform_fee int, vat int, net_amount int, total_sales int, settlement_count int);

DO $$
DECLARE
  v_partner_id uuid;
  v_party_id uuid;
  v_event_id uuid;
  v_ticket_id uuid;
  v_user_id uuid;
BEGIN
  v_user_id := tests.create_supabase_user('settle_s1');

  INSERT INTO public.partners (name) VALUES ('P1') RETURNING id INTO v_partner_id;

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
    VALUES (v_partner_id, 'Party1', 0, 10) RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
    VALUES (v_party_id, now() - interval '1 day', now(), 0, 10, 'scheduled') RETURNING id INTO v_event_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
    VALUES (v_event_id, 'T1', 10, 100000) RETURNING id INTO v_ticket_id;

  INSERT INTO public.event_applications (event_id, ticket_id, user_id, status, payment_id, payment_amount)
    VALUES (v_event_id, v_ticket_id, v_user_id, 'paid', 'imp_s1_001', 100000);

  UPDATE public.events SET status = 'completed' WHERE id = v_event_id;

  INSERT INTO s1 SELECT pg_fee, platform_fee, vat, net_amount, total_sales, 1
    FROM public.settlements WHERE event_id = v_event_id;
END $$;

-- Test 1: pg_fee=3500
SELECT is((SELECT pg_fee FROM s1), 3500, 'S1: pg_fee=3500 (100000 * 0.035)');

-- Test 2: platform_fee=5000
SELECT is((SELECT platform_fee FROM s1), 5000, 'S1: platform_fee=5000 (100000 * 0.05)');

-- Test 3: vat=850
SELECT is((SELECT vat FROM s1), 850, 'S1: vat=850 ((3500+5000) * 0.1)');

-- Test 4: net_amount=90650
SELECT is((SELECT net_amount FROM s1), 90650, 'S1: net_amount=90650 (100000-3500-5000-850)');

-- ============================================================
-- 시나리오 2: total_sales=10000
-- pg_fee=350, platform_fee=500, vat=85, net_amount=9065
-- ============================================================

CREATE TEMP TABLE s2 (pg_fee int, platform_fee int, vat int, net_amount int);

DO $$
DECLARE
  v_partner_id uuid;
  v_party_id uuid;
  v_event_id uuid;
  v_ticket_id uuid;
  v_user_id uuid;
BEGIN
  v_user_id := tests.create_supabase_user('settle_s2');

  INSERT INTO public.partners (name) VALUES ('P2') RETURNING id INTO v_partner_id;

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
    VALUES (v_partner_id, 'Party2', 0, 10) RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
    VALUES (v_party_id, now() - interval '1 day', now(), 0, 10, 'scheduled') RETURNING id INTO v_event_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
    VALUES (v_event_id, 'T2', 10, 10000) RETURNING id INTO v_ticket_id;

  INSERT INTO public.event_applications (event_id, ticket_id, user_id, status, payment_id, payment_amount)
    VALUES (v_event_id, v_ticket_id, v_user_id, 'paid', 'imp_s2_001', 10000);

  UPDATE public.events SET status = 'completed' WHERE id = v_event_id;

  INSERT INTO s2 SELECT pg_fee, platform_fee, vat, net_amount
    FROM public.settlements WHERE event_id = v_event_id;
END $$;

-- Test 5: pg_fee=350
SELECT is((SELECT pg_fee FROM s2), 350, 'S2: pg_fee=350 (10000 * 0.035)');

-- Test 6: net_amount=9065
SELECT is((SELECT net_amount FROM s2), 9065, 'S2: net_amount=9065 (10000-350-500-85)');

-- ============================================================
-- 시나리오 3: total_sales=1 (최소값 — 모든 fee=0, net_amount=1)
-- ============================================================

CREATE TEMP TABLE s3 (pg_fee int, platform_fee int, vat int, net_amount int);

DO $$
DECLARE
  v_partner_id uuid;
  v_party_id uuid;
  v_event_id uuid;
  v_ticket_id uuid;
  v_user_id uuid;
BEGIN
  v_user_id := tests.create_supabase_user('settle_s3');

  INSERT INTO public.partners (name) VALUES ('P3') RETURNING id INTO v_partner_id;

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
    VALUES (v_partner_id, 'Party3', 0, 10) RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
    VALUES (v_party_id, now() - interval '1 day', now(), 0, 10, 'scheduled') RETURNING id INTO v_event_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
    VALUES (v_event_id, 'T3', 10, 1) RETURNING id INTO v_ticket_id;

  INSERT INTO public.event_applications (event_id, ticket_id, user_id, status, payment_id, payment_amount)
    VALUES (v_event_id, v_ticket_id, v_user_id, 'paid', 'imp_s3_001', 1);

  UPDATE public.events SET status = 'completed' WHERE id = v_event_id;

  INSERT INTO s3 SELECT pg_fee, platform_fee, vat, net_amount
    FROM public.settlements WHERE event_id = v_event_id;
END $$;

-- Test 7: total_sales=1 → net_amount=1 (모든 fee=0)
SELECT is((SELECT net_amount FROM s3), 1, 'S3: total_sales=1 → net_amount=1 (fees round to 0)');

-- ============================================================
-- 시나리오 4: total_sales=142857
-- pg_fee=5000, platform_fee=7143, vat=1214, net_amount=129500
-- ============================================================

CREATE TEMP TABLE s4 (pg_fee int, platform_fee int, vat int, net_amount int);

DO $$
DECLARE
  v_partner_id uuid;
  v_party_id uuid;
  v_event_id uuid;
  v_ticket_id uuid;
  v_user_id uuid;
BEGIN
  v_user_id := tests.create_supabase_user('settle_s4');

  INSERT INTO public.partners (name) VALUES ('P4') RETURNING id INTO v_partner_id;

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
    VALUES (v_partner_id, 'Party4', 0, 10) RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
    VALUES (v_party_id, now() - interval '1 day', now(), 0, 10, 'scheduled') RETURNING id INTO v_event_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
    VALUES (v_event_id, 'T4', 10, 142857) RETURNING id INTO v_ticket_id;

  INSERT INTO public.event_applications (event_id, ticket_id, user_id, status, payment_id, payment_amount)
    VALUES (v_event_id, v_ticket_id, v_user_id, 'paid', 'imp_s4_001', 142857);

  UPDATE public.events SET status = 'completed' WHERE id = v_event_id;

  INSERT INTO s4 SELECT pg_fee, platform_fee, vat, net_amount
    FROM public.settlements WHERE event_id = v_event_id;
END $$;

-- Test 8: pg_fee=5000 (round(142857*0.035)=round(4999.995)=5000)
SELECT is((SELECT pg_fee FROM s4), 5000, 'S4: pg_fee=5000 (round(142857*0.035))');

-- Test 9: net_amount=129500
SELECT is((SELECT net_amount FROM s4), 129500, 'S4: net_amount=129500 (142857-5000-7143-1214)');

-- ============================================================
-- 시나리오 5: total_refunds 존재 시 net_amount 차감 검증
-- total_sales=100000, total_refunds=20000
-- net_amount = 100000 - 20000 - 3500 - 5000 - 850 = 70650
-- ============================================================

CREATE TEMP TABLE s5 (net_amount int, total_refunds int);

DO $$
DECLARE
  v_partner_id uuid;
  v_party_id uuid;
  v_event_id uuid;
  v_ticket_id uuid;
  v_user_id_1 uuid;
  v_user_id_2 uuid;
BEGIN
  v_user_id_1 := tests.create_supabase_user('settle_s5_u1');
  v_user_id_2 := tests.create_supabase_user('settle_s5_u2');

  INSERT INTO public.partners (name) VALUES ('P5') RETURNING id INTO v_partner_id;

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
    VALUES (v_partner_id, 'Party5', 0, 10) RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
    VALUES (v_party_id, now() - interval '1 day', now(), 0, 10, 'scheduled') RETURNING id INTO v_event_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
    VALUES (v_event_id, 'T5', 10, 100000) RETURNING id INTO v_ticket_id;

  -- 결제 완료 신청 (total_sales에 포함)
  INSERT INTO public.event_applications (event_id, ticket_id, user_id, status, payment_id, payment_amount)
    VALUES (v_event_id, v_ticket_id, v_user_id_1, 'paid', 'imp_s5_001', 100000);

  -- 환불 완료 신청 (total_refunds에 포함)
  INSERT INTO public.event_applications (event_id, ticket_id, user_id, status, payment_id, payment_amount, refund_status)
    VALUES (v_event_id, v_ticket_id, v_user_id_2, 'paid', 'imp_s5_002', 20000, 'completed');

  UPDATE public.events SET status = 'completed' WHERE id = v_event_id;

  INSERT INTO s5 SELECT net_amount, total_refunds
    FROM public.settlements WHERE event_id = v_event_id;
END $$;

-- Test 10: total_refunds=20000 차감 후 net_amount=70650
SELECT is((SELECT net_amount FROM s5), 70650, 'S5: total_refunds=20000 차감 → net_amount=70650');

-- Test 11: total_refunds 값 자체 검증
SELECT is((SELECT total_refunds FROM s5), 20000, 'S5: total_refunds=20000 저장됨');

-- ============================================================
-- 시나리오 6: ON CONFLICT — 동일 이벤트 두 번 완료 → settlements 레코드 1개만
-- ============================================================

CREATE TEMP TABLE s6 (settlement_count int);

DO $$
DECLARE
  v_partner_id uuid;
  v_party_id uuid;
  v_event_id uuid;
  v_ticket_id uuid;
  v_user_id uuid;
BEGIN
  v_user_id := tests.create_supabase_user('settle_s6');

  INSERT INTO public.partners (name) VALUES ('P6') RETURNING id INTO v_partner_id;

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
    VALUES (v_partner_id, 'Party6', 0, 10) RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
    VALUES (v_party_id, now() - interval '1 day', now(), 0, 10, 'scheduled') RETURNING id INTO v_event_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
    VALUES (v_event_id, 'T6', 10, 50000) RETURNING id INTO v_ticket_id;

  INSERT INTO public.event_applications (event_id, ticket_id, user_id, status, payment_id, payment_amount)
    VALUES (v_event_id, v_ticket_id, v_user_id, 'paid', 'imp_s6_001', 50000);

  -- 첫 번째 완료
  UPDATE public.events SET status = 'completed' WHERE id = v_event_id;

  -- 두 번째 완료 시도 (scheduled → completed 다시 시도)
  UPDATE public.events SET status = 'scheduled' WHERE id = v_event_id;
  UPDATE public.events SET status = 'completed' WHERE id = v_event_id;

  INSERT INTO s6 SELECT count(*)::int
    FROM public.settlements WHERE event_id = v_event_id;
END $$;

-- Test 12: ON CONFLICT → settlements 레코드 1개만
SELECT is((SELECT settlement_count FROM s6), 1, 'S6: 동일 이벤트 두 번 완료 → settlements 레코드 1개만');

-- ============================================================
-- 시나리오 7: zero sales — settlements 레코드 생성됨 (status='pending')
-- ============================================================

CREATE TEMP TABLE s7 (settlement_count int, settlement_status text);

DO $$
DECLARE
  v_partner_id uuid;
  v_party_id uuid;
  v_event_id uuid;
  v_ticket_id uuid;
BEGIN
  INSERT INTO public.partners (name) VALUES ('P7') RETURNING id INTO v_partner_id;

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
    VALUES (v_partner_id, 'Party7', 0, 10) RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
    VALUES (v_party_id, now() - interval '1 day', now(), 0, 10, 'scheduled') RETURNING id INTO v_event_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
    VALUES (v_event_id, 'T7', 10, 0) RETURNING id INTO v_ticket_id;

  -- 신청자 없이 이벤트 완료
  UPDATE public.events SET status = 'completed' WHERE id = v_event_id;

  INSERT INTO s7 SELECT count(*)::int, status
    FROM public.settlements WHERE event_id = v_event_id
    GROUP BY status;
END $$;

-- Test 13: zero sales → settlements 레코드 생성됨
SELECT is((SELECT settlement_count FROM s7), 1, 'S7: zero sales → settlements 레코드 생성됨');

-- Test 14: zero sales → status='pending'
SELECT is((SELECT settlement_status FROM s7), 'pending', 'S7: zero sales → status=pending');

SELECT * FROM finish();
ROLLBACK;
