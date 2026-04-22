-- Migration: #1705 event_participants 이벤트 종료 후 30일 파기 (PIPA §21)
--
-- 개인정보처리방침: "파트너에게 제공한 참여자 정보는 이벤트 종료 후 30일 후 파기"
-- event_participants는 events.end_time 기준 30일 후 파기 대상이므로
-- JOIN이 필요한 커스텀 함수 방식으로 구현.

-- ── 1. retention_kind 열거형 확장 ─────────────────────────────────────────────
-- db_custom_fn: 단순 timestamp 비교로 처리할 수 없는 JOIN 기반 파기에 사용
ALTER TYPE admin.retention_kind ADD VALUE IF NOT EXISTS 'db_custom_fn';

-- ── 2. 커스텀 파기 함수 ───────────────────────────────────────────────────────
-- events.end_time + cutoff_days 기준으로 event_participants를 삭제
CREATE OR REPLACE FUNCTION admin.delete_old_event_participants(p_cutoff_days int)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, admin, public
AS $$
DECLARE
  v_deleted bigint;
BEGIN
  DELETE FROM public.event_participants ep
  USING public.events e
  WHERE ep.event_id = e.id
    AND e.end_time < now() - p_cutoff_days * INTERVAL '1 day';

  GET DIAGNOSTICS v_deleted = ROW_COUNT;
  RETURN v_deleted;
END;
$$;

REVOKE ALL ON FUNCTION admin.delete_old_event_participants(int) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION admin.delete_old_event_participants(int) TO service_role;

-- ── 3. retention_policies 등록 ────────────────────────────────────────────────
INSERT INTO admin.retention_policies (
  id,
  kind,
  retention_days,
  legal_min_days,
  target,
  enabled,
  description
) VALUES (
  'event_participants_post_event',
  'db_custom_fn',
  30,
  NULL,
  jsonb_build_object('fn', 'admin.delete_old_event_participants'),
  true,
  'PIPA §21: 이벤트 종료 후 30일 후 참가자 정보 파기 (display_name, birth_year 포함)'
);
