-- Migration: #1705 Part 2 — event_participants 이벤트 종료 후 30일 PII 익명화 정책 (PIPA §21)
--
-- 스키마·enum 변경은 000004에서 별도 트랜잭션으로 커밋됨.
-- 이 마이그레이션에서 db_custom_fn 을 안전하게 사용 가능.
--
-- 익명화 범위: user_id, application_id, ticket_code (직접 식별자) +
--              display_name, birth_year (PII) → 모두 NULL
-- 집계 보존: event_id, ticket_id, status 는 유지 (on_participant_change 트리거 오염 방지)

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
