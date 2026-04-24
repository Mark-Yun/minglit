-- [QR Checkin] Phase 3 — 엔트리 그룹별 체크인 현황 RPC
-- Issue #1811
--
-- get_event_checkin_stats_by_group: 이벤트의 각 엔트리 그룹별 체크인 현황 반환
-- 반환: [{ "id": uuid, "label": text, "total": N, "checked_in": M }, ...]
-- 엔트리 그룹이 없는 이벤트는 빈 배열 반환
-- PARTY_MANAGE 권한 없는 호출자는 permission denied 예외

CREATE OR REPLACE FUNCTION public.get_event_checkin_stats_by_group(
  p_event_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_partner_id uuid;
  v_result     jsonb;
BEGIN
  -- 1. 이벤트 → 파트너 조회
  SELECT pa.partner_id
    INTO v_partner_id
    FROM public.events e
    JOIN public.parties pa ON pa.id = e.party_id
   WHERE e.id = p_event_id;

  IF v_partner_id IS NULL THEN
    RAISE EXCEPTION 'event not found';
  END IF;

  -- 2. 호출자가 해당 파트너의 PARTY_MANAGE 권한 보유 여부 확인
  IF NOT public.has_partner_permission(v_partner_id, 'PARTY_MANAGE') THEN
    RAISE EXCEPTION 'permission denied: PARTY_MANAGE required';
  END IF;

  -- 3. 엔트리 그룹별 체크인 집계
  WITH group_stats AS (
    SELECT
      eg.id,
      eg.label,
      COUNT(DISTINCT ep.id) AS total,
      COUNT(DISTINCT ep.id) FILTER (WHERE ep.status = 'checked_in') AS checked_in
    FROM entry_groups eg
    LEFT JOIN tickets t
      ON eg.id = ANY(t.target_entry_group_ids)
      AND t.event_id = p_event_id
    LEFT JOIN event_participants ep
      ON ep.ticket_id = t.id
      AND ep.event_id = p_event_id
    WHERE eg.event_id = p_event_id
    GROUP BY eg.id, eg.label, eg.created_at
    ORDER BY eg.created_at
  )
  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'id',         id::text,
        'label',      label,
        'total',      total,
        'checked_in', checked_in
      )
    ),
    '[]'::jsonb
  )
    INTO v_result
    FROM group_stats;

  RETURN v_result;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.get_event_checkin_stats_by_group(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_event_checkin_stats_by_group(uuid) TO authenticated;
