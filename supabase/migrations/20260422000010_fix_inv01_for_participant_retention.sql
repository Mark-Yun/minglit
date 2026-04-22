-- Migration: #1705 INV-01 guard — event_participants retention 후 false positive 방지
--
-- event_participants PII(user_id 등)는 이벤트 종료 30일 후 NULL로 익명화된다 (#1705).
-- 기존 INV-01은 event_applications.user_id = event_participants.user_id 로 JOIN하므로
-- 익명화 후 user_id=NULL인 participant가 있으면 JOIN 실패 → false positive 발생.
-- 수정: events 테이블을 JOIN해 end_time이 30일 이상 지난 이벤트는 INV-01 체크에서 제외.

CREATE OR REPLACE FUNCTION public.check_db_invariants()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_violations JSONB := '[]'::JSONB;
  v_count      BIGINT;
BEGIN
  -- ────────────────────────────────────────────────────────
  -- INV-01: Approved/paid applications without participant
  -- Trigger issue_ticket_on_approval creates a participant when status → approved/paid.
  -- Severity: P0
  -- event_participants PII는 이벤트 종료 30일 후 익명화됨 (#1705).
  -- user_id가 NULL화되면 JOIN이 실패하므로 30일 지난 이벤트는 체크 제외.
  -- ────────────────────────────────────────────────────────
  SELECT count(*)
  INTO v_count
  FROM event_applications a
  LEFT JOIN event_participants p
    ON a.event_id = p.event_id AND a.user_id = p.user_id
  JOIN events e ON a.event_id = e.id
  WHERE a.status IN ('approved', 'paid')
    AND p.id IS NULL
    AND (e.end_time IS NULL OR e.end_time >= NOW() - INTERVAL '30 days');

  IF v_count > 0 THEN
    v_violations := v_violations || jsonb_build_object(
      'id', 'INV-01',
      'severity', 'P0',
      'message', 'Approved/paid applications without participant record',
      'count', v_count
    );
  END IF;

  -- ────────────────────────────────────────────────────────
  -- INV-02: Events with more participants than max_participants
  -- Severity: P0
  -- ────────────────────────────────────────────────────────
  SELECT count(*)
  INTO v_count
  FROM (
    SELECT e.id
    FROM events e
    JOIN event_participants p ON e.id = p.event_id
    GROUP BY e.id, e.max_participants
    HAVING count(p.id) > e.max_participants
  ) sub;

  IF v_count > 0 THEN
    v_violations := v_violations || jsonb_build_object(
      'id', 'INV-02',
      'severity', 'P0',
      'message', 'Events exceeding max_participants capacity',
      'count', v_count
    );
  END IF;

  -- ────────────────────────────────────────────────────────
  -- INV-03: Cancelled applications with remaining participant
  -- When an application is cancelled, the participant record should be removed.
  -- Severity: P0
  -- event_participants PII는 이벤트 종료 30일 후 익명화됨 (#1705).
  -- user_id가 NULL화되면 JOIN이 실패 → 30일 지난 이벤트는 체크 불가하므로 제외.
  -- ────────────────────────────────────────────────────────
  SELECT count(*)
  INTO v_count
  FROM event_applications a
  JOIN event_participants p
    ON a.event_id = p.event_id AND a.user_id = p.user_id
  JOIN events e ON a.event_id = e.id
  WHERE a.status = 'cancelled'
    AND (e.end_time IS NULL OR e.end_time >= NOW() - INTERVAL '30 days');

  IF v_count > 0 THEN
    v_violations := v_violations || jsonb_build_object(
      'id', 'INV-03',
      'severity', 'P0',
      'message', 'Cancelled applications with orphaned participant records',
      'count', v_count
    );
  END IF;

  -- ────────────────────────────────────────────────────────
  -- INV-04: Completed events without settlement item
  -- Every completed event must have a settlement_items entry (source_type='EVENT').
  -- Severity: P0
  -- ────────────────────────────────────────────────────────
  SELECT count(*)
  INTO v_count
  FROM events e
  WHERE e.status = 'completed'
    AND NOT EXISTS (
      SELECT 1 FROM settlement_items s
      WHERE s.source_type = 'EVENT' AND s.source_id = e.id::text
    );

  IF v_count > 0 THEN
    v_violations := v_violations || jsonb_build_object(
      'id', 'INV-04',
      'severity', 'P0',
      'message', 'Completed events without settlement_items record',
      'count', v_count
    );
  END IF;

  -- ────────────────────────────────────────────────────────
  -- INV-05: Paid application without payment_id
  -- Any application with status='paid' must have a non-null payment_id.
  -- Severity: P0
  -- ────────────────────────────────────────────────────────
  SELECT count(*)
  INTO v_count
  FROM event_applications
  WHERE status = 'paid' AND payment_id IS NULL;

  IF v_count > 0 THEN
    v_violations := v_violations || jsonb_build_object(
      'id', 'INV-05',
      'severity', 'P0',
      'message', 'Paid applications with NULL payment_id',
      'count', v_count
    );
  END IF;

  -- ────────────────────────────────────────────────────────
  -- INV-06: current_participants counter drift
  -- events.current_participants must equal count(event_participants) per event.
  -- Severity: P1
  -- ────────────────────────────────────────────────────────
  SELECT count(*)
  INTO v_count
  FROM (
    SELECT e.id
    FROM events e
    LEFT JOIN event_participants p ON e.id = p.event_id
    GROUP BY e.id, e.current_participants
    HAVING e.current_participants != count(p.id)
  ) sub;

  IF v_count > 0 THEN
    v_violations := v_violations || jsonb_build_object(
      'id', 'INV-06',
      'severity', 'P1',
      'message', 'Events with current_participants counter out of sync',
      'count', v_count
    );
  END IF;

  -- ────────────────────────────────────────────────────────
  -- INV-07: Self-vote in match_votes (should be blocked by CHECK constraint)
  -- Severity: P0
  -- ────────────────────────────────────────────────────────
  SELECT count(*)
  INTO v_count
  FROM match_votes
  WHERE voter_id = candidate_id;

  IF v_count > 0 THEN
    v_violations := v_violations || jsonb_build_object(
      'id', 'INV-07',
      'severity', 'P0',
      'message', 'Self-vote detected in match_votes',
      'count', v_count
    );
  END IF;

  -- ────────────────────────────────────────────────────────
  -- Return result
  -- ────────────────────────────────────────────────────────
  RETURN json_build_object(
    'passed',       jsonb_array_length(v_violations) = 0,
    'checked_at',   now(),
    'violations',   v_violations
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.check_db_invariants() TO service_role;
