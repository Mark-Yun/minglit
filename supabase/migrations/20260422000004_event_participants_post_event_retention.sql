-- Migration: #1705 event_participants 이벤트 종료 후 30일 PII 익명화 (PIPA §21)
--
-- 개인정보처리방침: "파트너에게 제공한 참여자 정보는 이벤트 종료 후 30일 후 파기"
--
-- 구현 방식: DELETE 대신 PII 컬럼 NULL화 (익명화)
--   DELETE를 사용하면 on_participant_change 트리거가 events.current_participants 와
--   tickets.sold_count를 감소시켜 운영/정산 집계를 오염시킨다.
--   PII 컬럼(display_name, birth_year, application_id, ticket_code)과
--   직접 식별자(user_id)를 NULL로 치환하여 개인정보 파기 목적을 달성하면서
--   집계 무결성과 참가 이력(event_id, ticket_id, status)을 보존한다.
--
-- event_participants는 events.end_time 기준 JOIN이 필요하므로 db_custom_fn 방식 사용.
--
-- user_id NOT NULL 제약: UNIQUE(event_id, user_id) 는 PostgreSQL에서 NULL 여러 개를
-- 허용하므로(NULL ≠ NULL), NOT NULL을 DROP해도 제약 위반 없이 NULL화 가능.

-- ── 1. retention_kind 열거형 확장 ─────────────────────────────────────────────
ALTER TYPE admin.retention_kind ADD VALUE IF NOT EXISTS 'db_custom_fn';

-- ── 2. user_id NOT NULL 제약 해제 ─────────────────────────────────────────────
-- 이벤트 종료 30일 후 user_id 를 NULL화하기 위해 NOT NULL 제약을 제거한다.
-- FK(user_profiles)는 NULL 값에는 적용되지 않으므로 참조 무결성에 영향 없음.
ALTER TABLE public.event_participants ALTER COLUMN user_id DROP NOT NULL;

-- ── 3. 커스텀 익명화 함수 ─────────────────────────────────────────────────────
-- events.end_time + cutoff_days 기준으로 event_participants의 직접 식별자 및 PII
-- 컬럼을 모두 NULL화한다: user_id, application_id, ticket_code, display_name, birth_year.
CREATE OR REPLACE FUNCTION admin.anonymize_old_event_participants(p_cutoff_days int)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, admin, public
AS $$
DECLARE
  v_updated bigint;
BEGIN
  UPDATE public.event_participants ep
  SET user_id        = NULL,
      application_id = NULL,
      ticket_code    = NULL,
      display_name   = NULL,
      birth_year     = NULL
  FROM public.events e
  WHERE ep.event_id = e.id
    AND e.end_time < now() - p_cutoff_days * INTERVAL '1 day'
    AND (
      ep.user_id IS NOT NULL OR ep.application_id IS NOT NULL OR
      ep.ticket_code IS NOT NULL OR ep.display_name IS NOT NULL OR
      ep.birth_year IS NOT NULL
    );

  GET DIAGNOSTICS v_updated = ROW_COUNT;
  RETURN v_updated;
END;
$$;

REVOKE ALL ON FUNCTION admin.anonymize_old_event_participants(int) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION admin.anonymize_old_event_participants(int) TO service_role;

-- ── 4. retention_policies 등록 ────────────────────────────────────────────────
INSERT INTO admin.retention_policies (
  id,
  kind,
  retention_days,
  legal_min_days,
  target,
  enabled,
  description,
  metadata
) VALUES (
  'event_participants_post_event',
  'db_custom_fn',
  30,
  NULL,
  jsonb_build_object('fn', 'admin.anonymize_old_event_participants'),
  true,
  'PIPA §21: 이벤트 종료 후 30일 후 참가자 PII 및 직접 식별자 익명화 '
  '(user_id/application_id/ticket_code/display_name/birth_year → NULL)',
  jsonb_build_object(
    'approach', 'anonymize',
    'reason', 'DELETE는 on_participant_change 트리거로 집계 카운터를 오염시킴'
  )
);
