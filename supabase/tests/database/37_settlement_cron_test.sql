BEGIN;
SELECT plan(7);

SELECT tests.authenticate_as_service_role();

-- 기준 시간 설정: 2026-01-15 12:00:00 KST
SELECT tests.freeze_time('2026-01-15 12:00:00+09');

-- ============================================================
-- 데이터 준비: 다양한 event_date를 가진 settlements 생성
-- ============================================================

CREATE TEMP TABLE cron_results (
  label text,
  event_id uuid,
  status text
);

DO $$
DECLARE
  v_partner_id   uuid;
  v_party_id     uuid;
  v_event_8d     uuid;  -- 8일 전 → 전환 대상
  v_event_6d     uuid;  -- 6일 전 → 전환 안 됨
  v_event_7d     uuid;  -- 정확히 7일 전 → 경계 조건 (전환됨)
  v_event_ready  uuid;  -- 이미 ready → 변경 없음
  v_event_a      uuid;  -- 다중 중 조건 충족 (10일 전)
  v_event_b      uuid;  -- 다중 중 조건 미충족 (3일 전)
  v_event_c      uuid;  -- 다중 중 조건 충족 (9일 전)
BEGIN
  INSERT INTO public.partners (name) VALUES ('Cron Partner') RETURNING id INTO v_partner_id;

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
    VALUES (v_partner_id, 'Cron Party', 0, 10) RETURNING id INTO v_party_id;

  -- 이벤트 생성 (start_time/end_time은 event_date와 동일하게 설정)
  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
    VALUES (v_party_id, '2026-01-07 10:00:00+09', '2026-01-07 12:00:00+09', 0, 10, 'completed')
    RETURNING id INTO v_event_8d;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
    VALUES (v_party_id, '2026-01-09 10:00:00+09', '2026-01-09 12:00:00+09', 0, 10, 'completed')
    RETURNING id INTO v_event_6d;

  -- 정확히 7일 전: 2026-01-15 12:00:00+09 - 7 days = 2026-01-08 12:00:00+09
  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
    VALUES (v_party_id, '2026-01-08 12:00:00+09', '2026-01-08 14:00:00+09', 0, 10, 'completed')
    RETURNING id INTO v_event_7d;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
    VALUES (v_party_id, '2026-01-05 10:00:00+09', '2026-01-05 12:00:00+09', 0, 10, 'completed')
    RETURNING id INTO v_event_ready;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
    VALUES (v_party_id, '2026-01-05 10:00:00+09', '2026-01-05 12:00:00+09', 0, 10, 'completed')
    RETURNING id INTO v_event_a;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
    VALUES (v_party_id, '2026-01-12 10:00:00+09', '2026-01-12 12:00:00+09', 0, 10, 'completed')
    RETURNING id INTO v_event_b;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
    VALUES (v_party_id, '2026-01-06 10:00:00+09', '2026-01-06 12:00:00+09', 0, 10, 'completed')
    RETURNING id INTO v_event_c;

  -- settlements 직접 INSERT (트리거 우회)
  -- 케이스 1: 8일 전 → pending → ready 전환 대상
  INSERT INTO public.settlements (partner_id, event_id, event_title, event_date, total_sales, total_refunds, pg_fee, platform_fee, vat, net_amount, status)
    VALUES (v_partner_id, v_event_8d, '8일전 이벤트', '2026-01-07 12:00:00+09', 0, 0, 0, 0, 0, 0, 'pending');

  -- 케이스 2: 6일 전 → pending 유지
  INSERT INTO public.settlements (partner_id, event_id, event_title, event_date, total_sales, total_refunds, pg_fee, platform_fee, vat, net_amount, status)
    VALUES (v_partner_id, v_event_6d, '6일전 이벤트', '2026-01-09 12:00:00+09', 0, 0, 0, 0, 0, 0, 'pending');

  -- 케이스 3: 정확히 7일 전 → ready 전환 (경계 조건, <= 이므로 전환됨)
  INSERT INTO public.settlements (partner_id, event_id, event_title, event_date, total_sales, total_refunds, pg_fee, platform_fee, vat, net_amount, status)
    VALUES (v_partner_id, v_event_7d, '7일전 이벤트', '2026-01-08 12:00:00+09', 0, 0, 0, 0, 0, 0, 'pending');

  -- 케이스 4: 이미 ready → 변경 없음 (WHERE status='pending' 조건으로 제외)
  INSERT INTO public.settlements (partner_id, event_id, event_title, event_date, total_sales, total_refunds, pg_fee, platform_fee, vat, net_amount, status)
    VALUES (v_partner_id, v_event_ready, '이미ready 이벤트', '2026-01-05 12:00:00+09', 0, 0, 0, 0, 0, 0, 'ready');

  -- 케이스 5: 다중 settlements — 조건 충족 (10일 전)
  INSERT INTO public.settlements (partner_id, event_id, event_title, event_date, total_sales, total_refunds, pg_fee, platform_fee, vat, net_amount, status)
    VALUES (v_partner_id, v_event_a, '다중A 이벤트', '2026-01-05 12:00:00+09', 0, 0, 0, 0, 0, 0, 'pending');

  -- 케이스 5: 다중 settlements — 조건 미충족 (3일 전)
  INSERT INTO public.settlements (partner_id, event_id, event_title, event_date, total_sales, total_refunds, pg_fee, platform_fee, vat, net_amount, status)
    VALUES (v_partner_id, v_event_b, '다중B 이벤트', '2026-01-12 12:00:00+09', 0, 0, 0, 0, 0, 0, 'pending');

  -- 케이스 5: 다중 settlements — 조건 충족 (9일 전)
  INSERT INTO public.settlements (partner_id, event_id, event_title, event_date, total_sales, total_refunds, pg_fee, platform_fee, vat, net_amount, status)
    VALUES (v_partner_id, v_event_c, '다중C 이벤트', '2026-01-06 12:00:00+09', 0, 0, 0, 0, 0, 0, 'pending');

  -- 크론 함수 실행
  PERFORM public.update_settlement_ready_status();

  -- 결과 저장
  INSERT INTO cron_results (label, event_id, status)
    SELECT event_title, event_id, status
    FROM public.settlements
    WHERE partner_id = v_partner_id;
END $$;

-- ============================================================
-- 테스트 1: event_date가 8일 전 → pending → ready 전환
-- ============================================================
SELECT is(
  (SELECT status FROM cron_results WHERE label = '8일전 이벤트'),
  'ready',
  '케이스1: event_date 8일 전 → ready 전환'
);

-- ============================================================
-- 테스트 2: event_date가 6일 전 → 전환 안 됨 (7일 미경과)
-- ============================================================
SELECT is(
  (SELECT status FROM cron_results WHERE label = '6일전 이벤트'),
  'pending',
  '케이스2: event_date 6일 전 → pending 유지 (7일 미경과)'
);

-- ============================================================
-- 테스트 3: event_date가 정확히 7일 전 → ready 전환 (경계 조건, <=)
-- ============================================================
SELECT is(
  (SELECT status FROM cron_results WHERE label = '7일전 이벤트'),
  'ready',
  '케이스3: event_date 정확히 7일 전 → ready 전환 (경계 조건 <=)'
);

-- ============================================================
-- 테스트 4: 이미 ready인 settlement → 변경 없음 (WHERE status=''pending'' 조건)
-- ============================================================
SELECT is(
  (SELECT status FROM cron_results WHERE label = '이미ready 이벤트'),
  'ready',
  '케이스4: 이미 ready → 변경 없음 (status=pending 조건으로 제외)'
);

-- ============================================================
-- 테스트 5: 다중 settlements 중 조건 충족하는 것만 전환 — 충족 케이스 A (10일 전)
-- ============================================================
SELECT is(
  (SELECT status FROM cron_results WHERE label = '다중A 이벤트'),
  'ready',
  '케이스5-A: 다중 중 10일 전 → ready 전환'
);

-- ============================================================
-- 테스트 6: 다중 settlements 중 조건 미충족 케이스 B (3일 전) → pending 유지
-- ============================================================
SELECT is(
  (SELECT status FROM cron_results WHERE label = '다중B 이벤트'),
  'pending',
  '케이스5-B: 다중 중 3일 전 → pending 유지'
);

-- ============================================================
-- 테스트 7: 다중 settlements 중 조건 충족 케이스 C (9일 전) → ready 전환
-- ============================================================
SELECT is(
  (SELECT status FROM cron_results WHERE label = '다중C 이벤트'),
  'ready',
  '케이스5-C: 다중 중 9일 전 → ready 전환'
);

SELECT tests.unfreeze_time();

SELECT * FROM finish();
ROLLBACK;
