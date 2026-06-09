-- Issue #3445: move remaining write-capable SECURITY DEFINER RPCs behind
-- authenticated Edge Functions. Client roles lose direct EXECUTE; service_role
-- EF callers use explicit actor-aware internals for the DB atomic boundary.

CREATE OR REPLACE FUNCTION public.process_qr_checkin_for_actor(
  p_actor_user_id uuid,
  p_ticket_id uuid,
  p_event_id uuid,
  p_user_id uuid
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
  IF p_actor_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT pa.partner_id
    INTO v_partner_id
    FROM public.events e
    JOIN public.parties pa ON pa.id = e.party_id
   WHERE e.id = p_event_id;

  IF v_partner_id IS NULL THEN
    RETURN 'not_found';
  END IF;

  IF NOT (
    EXISTS (
      SELECT 1
        FROM public.partner_member_permissions pmp
       WHERE pmp.partner_id = v_partner_id
         AND pmp.user_id = p_actor_user_id
         AND 'PARTY_MANAGE' = ANY(pmp.permissions)
    )
    OR EXISTS (
      SELECT 1
        FROM public.app_roles ar
       WHERE ar.user_id = p_actor_user_id
         AND ar.role = 'super_admin'
    )
  ) THEN
    RAISE EXCEPTION 'permission denied: PARTY_MANAGE required';
  END IF;

  SELECT status
    INTO v_current_status
    FROM public.event_participants
   WHERE ticket_id = p_ticket_id
     AND event_id = p_event_id
     AND user_id = p_user_id
   FOR UPDATE;

  IF NOT FOUND THEN
    RETURN 'not_found';
  END IF;

  IF v_current_status = 'checked_in' THEN
    RETURN 'already_checked_in';
  END IF;

  UPDATE public.event_participants
     SET status = 'checked_in',
         checked_in_at = now()
   WHERE ticket_id = p_ticket_id
     AND event_id = p_event_id
     AND user_id = p_user_id;

  RETURN 'success';
END;
$$;

CREATE OR REPLACE FUNCTION public.process_qr_checkin(
  p_ticket_id uuid,
  p_event_id uuid,
  p_user_id uuid
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN public.process_qr_checkin_for_actor(
    auth.uid(),
    p_ticket_id,
    p_event_id,
    p_user_id
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.process_manual_checkin_for_actor(
  p_actor_user_id uuid,
  p_ticket_id uuid,
  p_event_id uuid
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_partner_id uuid;
  v_event_status text;
  v_current_status text;
BEGIN
  IF p_actor_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT pa.partner_id, e.status
    INTO v_partner_id, v_event_status
    FROM public.events e
    JOIN public.parties pa ON pa.id = e.party_id
   WHERE e.id = p_event_id;

  IF v_partner_id IS NULL THEN
    RETURN 'not_found';
  END IF;

  IF v_event_status IN ('cancelled', 'completed') THEN
    RETURN 'not_found';
  END IF;

  IF NOT (
    EXISTS (
      SELECT 1
        FROM public.partner_member_permissions pmp
       WHERE pmp.partner_id = v_partner_id
         AND pmp.user_id = p_actor_user_id
         AND 'PARTY_MANAGE' = ANY(pmp.permissions)
    )
    OR EXISTS (
      SELECT 1
        FROM public.app_roles ar
       WHERE ar.user_id = p_actor_user_id
         AND ar.role = 'super_admin'
    )
  ) THEN
    RAISE EXCEPTION 'permission denied: PARTY_MANAGE required';
  END IF;

  SELECT status
    INTO v_current_status
    FROM public.event_participants
   WHERE ticket_id = p_ticket_id
     AND event_id = p_event_id
   FOR UPDATE;

  IF NOT FOUND THEN
    RETURN 'not_found';
  END IF;

  IF v_current_status = 'checked_in' THEN
    RETURN 'already_checked_in';
  END IF;

  IF v_current_status != 'ticket_issued' THEN
    RETURN 'not_found';
  END IF;

  UPDATE public.event_participants
     SET status = 'checked_in',
         checked_in_at = now()
   WHERE ticket_id = p_ticket_id
     AND event_id = p_event_id;

  RETURN 'success';
END;
$$;

CREATE OR REPLACE FUNCTION public.process_manual_checkin(
  p_ticket_id uuid,
  p_event_id uuid
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN public.process_manual_checkin_for_actor(
    auth.uid(),
    p_ticket_id,
    p_event_id
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.request_retry_payout_for_actor(
  p_actor_user_id uuid,
  p_payout_id uuid,
  p_partner_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_payout record;
  v_item record;
  v_new_idem_key text;
BEGIN
  IF p_actor_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF NOT EXISTS (
    SELECT 1
      FROM public.partner_member_permissions pmp
     WHERE pmp.user_id = p_actor_user_id
       AND pmp.partner_id = p_partner_id
  ) THEN
    RAISE EXCEPTION 'unauthorized: caller is not a member of partner %', p_partner_id;
  END IF;

  SELECT * INTO v_payout
    FROM public.payouts
   WHERE id = p_payout_id
     AND partner_id = p_partner_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'payout not found or unauthorized: %', p_payout_id;
  END IF;

  IF v_payout.status != 'FAILED' THEN
    RAISE EXCEPTION 'only FAILED payouts can be retried, current status: %', v_payout.status;
  END IF;

  v_new_idem_key := 'retry:' || p_payout_id::text || ':' || extract(epoch from now())::bigint::text;

  UPDATE public.payouts
     SET status = 'CREATED',
         payout_request_idempotency_key = v_new_idem_key,
         updated_at = now()
   WHERE id = p_payout_id;

  FOR v_item IN
    SELECT si.id, si.version
      FROM public.settlement_items si
     WHERE si.payout_id = p_payout_id
       AND si.status = 'FAILED'
       AND si.retryable = true
  LOOP
    BEGIN
      PERFORM public.transition_settlement_status(
        v_item.id,
        v_item.version,
        'READY',
        'PARTNER',
        p_partner_id::text,
        'retry_requested',
        null::text, null::text, null::text, null::text,
        jsonb_build_object('retry_payout_id', p_payout_id),
        v_new_idem_key || ':' || v_item.id::text
      );
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'transition failed for item %: %', v_item.id, sqlerrm;
    END;
  END LOOP;

  RETURN jsonb_build_object(
    'success', true,
    'payout_id', p_payout_id,
    'new_idempotency_key', v_new_idem_key
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.request_retry_payout(
  p_payout_id uuid,
  p_partner_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN public.request_retry_payout_for_actor(
    auth.uid(),
    p_payout_id,
    p_partner_id
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.save_user_consents_for_user(
  p_user_id uuid,
  p_consents jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_now timestamptz := now();
BEGIN
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF COALESCE(jsonb_typeof(p_consents), 'null') <> 'array' THEN
    RAISE EXCEPTION 'p_consents must be a JSON array';
  END IF;

  INSERT INTO public.user_consents (
    user_id,
    consent_key,
    consented,
    policy_version,
    consented_at,
    withdrawn_at
  )
  SELECT
    p_user_id,
    entry.consent_key,
    entry.consented,
    entry.policy_version,
    v_now,
    CASE WHEN entry.consented THEN NULL ELSE v_now END
  FROM jsonb_to_recordset(p_consents) AS entry(
    consent_key text,
    consented boolean,
    policy_version integer
  )
  ON CONFLICT (user_id, consent_key) DO UPDATE
  SET
    consented = EXCLUDED.consented,
    policy_version = GREATEST(
      COALESCE(EXCLUDED.policy_version, public.user_consents.policy_version),
      COALESCE(public.user_consents.policy_version, EXCLUDED.policy_version)
    ),
    consented_at = CASE
      WHEN EXCLUDED.consented THEN v_now
      ELSE public.user_consents.consented_at
    END,
    withdrawn_at = CASE
      WHEN EXCLUDED.consented THEN NULL
      ELSE v_now
    END;
END;
$$;

CREATE OR REPLACE FUNCTION public.save_user_consents(
  p_user_id uuid,
  p_consents jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_auth_user_id uuid := auth.uid();
BEGIN
  IF v_auth_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF v_auth_user_id IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Cannot write consents for another user';
  END IF;

  PERFORM public.save_user_consents_for_user(p_user_id, p_consents);
END;
$$;

CREATE OR REPLACE FUNCTION public.set_social_interaction_for_user(
  p_user_id uuid,
  p_target_id text,
  p_target_type text,
  p_interaction_type text,
  p_active boolean
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_opposite public.social_interaction_type;
BEGIN
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'User not authenticated';
  END IF;

  PERFORM pg_advisory_xact_lock(
    ('x' || left(md5(p_user_id::text || ':' || p_target_id), 16))::bit(64)::bigint
  );

  IF p_active THEN
    IF p_interaction_type IN ('like', 'dislike') THEN
      v_opposite := CASE p_interaction_type
        WHEN 'like' THEN 'dislike'::public.social_interaction_type
        ELSE 'like'::public.social_interaction_type
      END;

      DELETE FROM public.social_interactions
       WHERE user_id = p_user_id
         AND target_id = p_target_id::uuid
         AND interaction_type = v_opposite;
    END IF;

    INSERT INTO public.social_interactions (
      user_id,
      target_id,
      target_type,
      interaction_type
    )
    VALUES (
      p_user_id,
      p_target_id::uuid,
      p_target_type::public.social_target_type,
      p_interaction_type::public.social_interaction_type
    )
    ON CONFLICT (user_id, target_id, interaction_type) DO NOTHING;
  ELSE
    DELETE FROM public.social_interactions
     WHERE user_id = p_user_id
       AND target_id = p_target_id::uuid
       AND interaction_type = p_interaction_type::public.social_interaction_type;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.set_social_interaction(
  p_target_id text,
  p_target_type text,
  p_interaction_type text,
  p_active boolean
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.set_social_interaction_for_user(
    auth.uid(),
    p_target_id,
    p_target_type,
    p_interaction_type,
    p_active
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.process_qr_checkin_for_actor(uuid, uuid, uuid, uuid)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.process_qr_checkin_for_actor(uuid, uuid, uuid, uuid)
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.process_manual_checkin_for_actor(uuid, uuid, uuid)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.process_manual_checkin_for_actor(uuid, uuid, uuid)
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.request_retry_payout_for_actor(uuid, uuid, uuid)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.request_retry_payout_for_actor(uuid, uuid, uuid)
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.save_user_consents_for_user(uuid, jsonb)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.save_user_consents_for_user(uuid, jsonb)
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.set_social_interaction_for_user(uuid, text, text, text, boolean)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.set_social_interaction_for_user(uuid, text, text, text, boolean)
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.process_qr_checkin(uuid, uuid, uuid)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.process_qr_checkin(uuid, uuid, uuid)
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.process_manual_checkin(uuid, uuid)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.process_manual_checkin(uuid, uuid)
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.request_retry_payout(uuid, uuid)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.request_retry_payout(uuid, uuid)
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.save_user_consents(uuid, jsonb)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.save_user_consents(uuid, jsonb)
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.set_social_interaction(text, text, text, boolean)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.set_social_interaction(text, text, text, boolean)
  TO service_role;
