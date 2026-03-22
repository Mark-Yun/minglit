-- Phase 1: create_order_validated DB function + sold_count CHECK constraint + audit trigger
-- Security: 9 vulnerabilities (V1~V8) validated server-side atomically with FOR UPDATE locking

-- ============================================================
-- 1. sold_count CHECK constraint (방어 계층 — V3)
-- ============================================================

ALTER TABLE public.tickets
  ADD CONSTRAINT chk_sold_count CHECK (sold_count <= quantity);

-- ============================================================
-- 2. create_order_validated function
-- ============================================================

CREATE OR REPLACE FUNCTION public.create_order_validated(
  p_event_id uuid,
  p_ticket_id uuid,
  p_user_id uuid
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_event record;
  v_ticket record;
  v_user record;
  v_entry_group record;
  v_balance_result jsonb;
  v_existing_app uuid;
  v_status text;
  v_app_id uuid;
  v_has_verification boolean;
BEGIN
  -- 1. Event 검증 (V4)
  SELECT * INTO v_event FROM public.events WHERE id = p_event_id;
  IF v_event IS NULL THEN
    RETURN jsonb_build_object('error', 'EVENT_NOT_FOUND');
  END IF;
  IF v_event.status != 'scheduled' OR v_event.start_time <= now() THEN
    RETURN jsonb_build_object('error', 'EVENT_NOT_ACTIVE');
  END IF;

  -- 2. Ticket 검증 (V2, V3) — FOR UPDATE로 행 잠금 (race condition 방지)
  SELECT * INTO v_ticket FROM public.tickets WHERE id = p_ticket_id FOR UPDATE;
  IF v_ticket IS NULL OR v_ticket.event_id != p_event_id THEN
    RETURN jsonb_build_object('error', 'TICKET_NOT_FOUND');
  END IF;
  IF v_ticket.sold_count >= v_ticket.quantity THEN
    RETURN jsonb_build_object('error', 'TICKET_SOLD_OUT');
  END IF;

  -- 3. 정원 확인 (V5)
  IF v_event.current_participants >= v_event.max_participants THEN
    RETURN jsonb_build_object('error', 'EVENT_FULL');
  END IF;

  -- 4. User 검증 (V6, V8) — is_verified 확인
  SELECT * INTO v_user FROM public.user_profiles WHERE id = p_user_id;
  IF v_user IS NULL OR NOT v_user.is_verified THEN
    RETURN jsonb_build_object('error', 'IDENTITY_REQUIRED');
  END IF;

  -- 5. Entry group 자격 (V6) — 성별/나이 검증
  SELECT eg.* INTO v_entry_group
  FROM public.entry_groups eg
  WHERE eg.id = ANY(v_ticket.target_entry_group_ids)
  LIMIT 1;

  IF v_entry_group IS NOT NULL THEN
    IF v_entry_group.gender IS NOT NULL AND v_user.gender != v_entry_group.gender THEN
      RETURN jsonb_build_object('error', 'ELIGIBILITY_FAILED', 'reason', 'gender_mismatch');
    END IF;
    IF v_entry_group.birth_year_min IS NOT NULL THEN
      IF EXTRACT(YEAR FROM v_user.birth_date) < v_entry_group.birth_year_min THEN
        RETURN jsonb_build_object('error', 'ELIGIBILITY_FAILED', 'reason', 'age_out_of_range');
      END IF;
    END IF;
    IF v_entry_group.birth_year_max IS NOT NULL THEN
      IF EXTRACT(YEAR FROM v_user.birth_date) > v_entry_group.birth_year_max THEN
        RETURN jsonb_build_object('error', 'ELIGIBILITY_FAILED', 'reason', 'age_out_of_range');
      END IF;
    END IF;
  END IF;

  -- 6. Verification 확인 (V8)
  IF v_ticket.required_verification_ids IS NOT NULL AND array_length(v_ticket.required_verification_ids, 1) > 0 THEN
    SELECT EXISTS(
      SELECT 1 FROM public.verification_submissions vs
      WHERE vs.user_id = p_user_id
        AND vs.verification_id = ANY(v_ticket.required_verification_ids)
        AND vs.status IN ('pending', 'approved')
    ) INTO v_has_verification;

    IF NOT v_has_verification THEN
      RETURN jsonb_build_object('error', 'VERIFICATION_REQUIRED');
    END IF;
  END IF;

  -- 7. 성비 균형 확인 (check_party_balance 재활용)
  v_balance_result := public.check_party_balance(p_event_id, p_ticket_id);
  IF (v_balance_result->>'allowed')::boolean IS NOT TRUE THEN
    RETURN jsonb_build_object('error', 'BALANCE_LIMIT', 'reason', v_balance_result->>'reason');
  END IF;

  -- 8. 중복 신청 확인 (ALREADY_APPLIED)
  SELECT id INTO v_existing_app FROM public.event_applications
  WHERE event_id = p_event_id AND user_id = p_user_id;
  IF v_existing_app IS NOT NULL THEN
    RETURN jsonb_build_object('error', 'ALREADY_APPLIED', 'application_id', v_existing_app);
  END IF;

  -- 9. Status 결정 (V7) — price=0 → 'paid', price>0 → 'pending'
  IF v_ticket.price = 0 THEN
    v_status := 'paid';
  ELSE
    v_status := 'pending';
  END IF;

  -- 10. INSERT (V1 — 금액은 서버에서 조회한 ticket.price 사용)
  INSERT INTO public.event_applications (event_id, ticket_id, user_id, payment_amount, status, payment_id)
  VALUES (
    p_event_id,
    p_ticket_id,
    p_user_id,
    v_ticket.price,
    v_status,
    CASE WHEN v_ticket.price = 0
      THEN 'FREE_' || gen_random_uuid()::text
      ELSE 'PENDING_' || extract(epoch from now())::bigint::text
    END
  )
  RETURNING id INTO v_app_id;

  RETURN jsonb_build_object(
    'success', true,
    'application_id', v_app_id,
    'amount', v_ticket.price,
    'requires_payment', v_ticket.price > 0,
    'ticket_name', v_ticket.name
  );
END;
$$;

-- ============================================================
-- 3. GRANT: service_role만 실행 가능
-- ============================================================

REVOKE EXECUTE ON FUNCTION public.create_order_validated(uuid, uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_order_validated(uuid, uuid, uuid) TO service_role;

-- ============================================================
-- 4. Phase 1 Audit 트리거 — EF 외 경로의 INSERT 감지
-- ============================================================

CREATE OR REPLACE FUNCTION public.audit_non_ef_application_insert()
RETURNS trigger LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF current_setting('request.header.x-source', true) IS DISTINCT FROM 'user-create-order' THEN
    INSERT INTO public.debug_logs (message, payload)
    VALUES (
      'Non-EF application insert detected',
      jsonb_build_object(
        'source', 'audit',
        'application_id', NEW.id,
        'user_id', NEW.user_id,
        'event_id', NEW.event_id
      )
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_audit_non_ef_insert ON public.event_applications;

CREATE TRIGGER trg_audit_non_ef_insert
  AFTER INSERT ON public.event_applications
  FOR EACH ROW EXECUTE FUNCTION public.audit_non_ef_application_insert();
