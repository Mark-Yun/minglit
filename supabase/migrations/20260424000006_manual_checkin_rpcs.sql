-- [QR Checkin] Phase 4 — 수동 체크인 RPC
-- Issue #1812
--
-- 1. get_event_participants_for_checkin: 이벤트 참가자 목록 + 체크인 현황 반환
-- 2. process_manual_checkin: 수동 체크인 원자적 처리 (QR 서명 검증 없음)
--    PARTY_MANAGE 권한 있는 파트너 스태프만 호출 가능

-- ============================================================
-- 1. get_event_participants_for_checkin
--    반환: [{ "id": uuid, "ticket_id": uuid, "name": text,
--             "phone_last4": text, "status": text, "checked_in_at": timestamp? }]
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_event_participants_for_checkin(
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

  -- 2. PARTY_MANAGE 권한 확인
  IF NOT public.has_partner_permission(v_partner_id, 'PARTY_MANAGE') THEN
    RAISE EXCEPTION 'permission denied: PARTY_MANAGE required';
  END IF;

  -- 3. 참가자 목록 조회 (미체크인 → 완료 순, 이름 오름차순)
  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'id',           ep.id::text,
        'ticket_id',    ep.ticket_id::text,
        'name',         COALESCE(ep.display_name, up.name, '이름 없음'),
        'phone_last4',  RIGHT(up.phone_number, 4),
        'status',       ep.status,
        'checked_in_at', ep.checked_in_at
      )
      ORDER BY
        (ep.status = 'checked_in') ASC,   -- 미체크인 먼저
        COALESCE(ep.display_name, up.name)
    ),
    '[]'::jsonb
  )
    INTO v_result
    FROM public.event_participants ep
    JOIN public.user_profiles up ON up.id = ep.user_id
   WHERE ep.event_id = p_event_id;

  RETURN v_result;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.get_event_participants_for_checkin(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_event_participants_for_checkin(uuid) TO authenticated;

-- ============================================================
-- 2. process_manual_checkin
--    반환값: 'success' | 'already_checked_in' | 'not_found'
--    QR 서명 검증 없이 티켓 ID만으로 체크인 처리.
--    PARTY_MANAGE 권한 게이트로 무단 체크인 방지.
-- ============================================================
CREATE OR REPLACE FUNCTION public.process_manual_checkin(
  p_ticket_id uuid,
  p_event_id  uuid
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_partner_id    uuid;
  v_current_status text;
BEGIN
  -- 1. 이벤트 → 파트너 조회
  SELECT pa.partner_id
    INTO v_partner_id
    FROM public.events e
    JOIN public.parties pa ON pa.id = e.party_id
   WHERE e.id = p_event_id;

  IF v_partner_id IS NULL THEN
    RETURN 'not_found';
  END IF;

  -- 2. PARTY_MANAGE 권한 확인
  IF NOT public.has_partner_permission(v_partner_id, 'PARTY_MANAGE') THEN
    RAISE EXCEPTION 'permission denied: PARTY_MANAGE required';
  END IF;

  -- 3. 티켓 레코드 조회 (비관적 잠금)
  SELECT status
    INTO v_current_status
    FROM public.event_participants
   WHERE ticket_id = p_ticket_id
     AND event_id  = p_event_id
   FOR UPDATE;

  IF NOT FOUND THEN
    RETURN 'not_found';
  END IF;

  -- 4. 이미 체크인된 경우
  IF v_current_status = 'checked_in' THEN
    RETURN 'already_checked_in';
  END IF;

  -- 5. 체크인 처리
  UPDATE public.event_participants
     SET status = 'checked_in',
         checked_in_at = now()
   WHERE ticket_id = p_ticket_id
     AND event_id  = p_event_id;

  RETURN 'success';
END;
$$;

REVOKE EXECUTE ON FUNCTION public.process_manual_checkin(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.process_manual_checkin(uuid, uuid) TO authenticated;
