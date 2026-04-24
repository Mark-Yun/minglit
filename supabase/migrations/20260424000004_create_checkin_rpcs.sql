-- [QR Checkin] Phase 2 — 체크인 RPC 생성
-- Issue #1810
--
-- 1. process_qr_checkin  — 티켓 QR 체크인 원자적 처리
-- 2. get_event_checkin_stats — 이벤트 체크인 현황 조회

-- ============================================================
-- 1. process_qr_checkin
--    클라이언트에서 서명 검증 완료 후 호출한다.
--    event_participants.status = 'checked_in', checked_in_at = now() 원자적 업데이트.
--    반환값: 'success' | 'already_checked_in' | 'not_found'
-- ============================================================
CREATE OR REPLACE FUNCTION public.process_qr_checkin(
  p_ticket_id uuid,
  p_event_id  uuid,
  p_user_id   uuid
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_partner_id uuid;
  v_current_status text;
BEGIN
  -- 1. 이벤트의 파트너 ID 조회 (권한 확인용)
  SELECT pa.partner_id
    INTO v_partner_id
    FROM public.events e
    JOIN public.parties pa ON pa.id = e.party_id
   WHERE e.id = p_event_id;

  IF v_partner_id IS NULL THEN
    RETURN 'not_found';
  END IF;

  -- 2. 호출자가 해당 파트너의 PARTY_MANAGE 권한 보유 여부 확인
  IF NOT public.has_partner_permission(v_partner_id, 'PARTY_MANAGE') THEN
    RAISE EXCEPTION 'permission denied: PARTY_MANAGE required';
  END IF;

  -- 3. 티켓 레코드 조회 (비관적 잠금)
  SELECT status
    INTO v_current_status
    FROM public.event_participants
   WHERE ticket_id = p_ticket_id
     AND event_id  = p_event_id
     AND user_id   = p_user_id
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
     SET status       = 'checked_in',
         checked_in_at = now()
   WHERE ticket_id = p_ticket_id
     AND event_id  = p_event_id
     AND user_id   = p_user_id;

  RETURN 'success';
END;
$$;

-- authenticated 유저가 호출 가능 (실제 권한은 함수 내부에서 has_partner_permission으로 검사)
GRANT EXECUTE ON FUNCTION public.process_qr_checkin(uuid, uuid, uuid) TO authenticated;

-- ============================================================
-- 2. get_event_checkin_stats
--    이벤트의 전체 체크인 현황을 반환한다.
--    반환: { "total": N, "checked_in": M }
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_event_checkin_stats(
  p_event_id uuid
)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT jsonb_build_object(
    'total',      COUNT(*),
    'checked_in', COUNT(*) FILTER (WHERE status = 'checked_in')
  )
  FROM public.event_participants
  WHERE event_id = p_event_id;
$$;

GRANT EXECUTE ON FUNCTION public.get_event_checkin_stats(uuid) TO authenticated;
