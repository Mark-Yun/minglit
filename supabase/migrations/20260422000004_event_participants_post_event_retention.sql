-- Migration: #1705 event_participants 이벤트 종료 후 30일 PII 익명화 (PIPA §21)
--
-- 개인정보처리방침: "파트너에게 제공한 참여자 정보는 이벤트 종료 후 30일 후 파기"
--
-- 구현 방식: DELETE 대신 PII 컬럼 NULL화 (익명화)
--   DELETE를 사용하면 on_participant_change 트리거가 events.current_participants 와
--   tickets.sold_count를 감소시켜 운영/정산 집계를 오염시킨다.
--   display_name / birth_year 를 NULL로 치환하면 개인정보 제거 목적을 달성하면서
--   집계 무결성과 참가 이력을 보존할 수 있다.
--
-- event_participants는 events.end_time 기준 JOIN이 필요하므로 db_custom_fn 방식 사용.

-- ── 1. retention_kind 열거형 확장 ─────────────────────────────────────────────
-- db_custom_fn: 단순 timestamp 비교로 처리할 수 없는 커스텀 로직에 사용
ALTER TYPE admin.retention_kind ADD VALUE IF NOT EXISTS 'db_custom_fn';

-- ── 2. 커스텀 익명화 함수 ─────────────────────────────────────────────────────
-- events.end_time + cutoff_days 기준으로 event_participants의 PII 컬럼을 NULL화
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
  SET display_name = NULL,
      birth_year   = NULL
  FROM public.events e
  WHERE ep.event_id = e.id
    AND e.end_time < now() - p_cutoff_days * INTERVAL '1 day'
    AND (ep.display_name IS NOT NULL OR ep.birth_year IS NOT NULL);

  GET DIAGNOSTICS v_updated = ROW_COUNT;
  RETURN v_updated;
END;
$$;

REVOKE ALL ON FUNCTION admin.anonymize_old_event_participants(int) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION admin.anonymize_old_event_participants(int) TO service_role;

-- ── 3. retention_policies 등록 ────────────────────────────────────────────────
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
  'PIPA §21: 이벤트 종료 후 30일 후 참가자 PII 익명화 (display_name, birth_year → NULL)',
  jsonb_build_object(
    'approach', 'anonymize',
    'reason', 'DELETE는 on_participant_change 트리거로 집계 카운터를 오염시킴'
  )
);
