-- Fix #1660: INV-01 (approved/paid apps without participant) + INV-05 (paid apps with null payment_id)
--
-- Root cause 1 (INV-05): apply_event RPC sets status='paid' for ALL apps without verification data,
--   including free events where p_payment_id IS NULL. INV-05 requires status='paid' → payment_id IS NOT NULL.
--   Fix: Use status='approved' when p_payment_id IS NULL (free events are auto-approved, not paid).
--
-- Root cause 2 (INV-01): issue_ticket_on_approval trigger fires on INSERT/UPDATE but the condition
--   `old.status NOT IN ('approved', 'paid')` evaluates to NULL (falsy) for INSERTs because OLD IS NULL.
--   So direct INSERTs with status='paid'/'approved' never create participant records.
--   Fix: Add `OLD IS NULL` guard so INSERT with terminal status also triggers participant creation.

-- ─────────────────────────────────────────────────────────
-- 1. Data cleanup: paid apps with null payment_id → 'approved'
--    These are free-event applications incorrectly marked as 'paid'.
-- ─────────────────────────────────────────────────────────
UPDATE public.event_applications
SET status = 'approved'
WHERE status = 'paid' AND payment_id IS NULL;

-- ─────────────────────────────────────────────────────────
-- 2. Data cleanup: create missing participant records for INV-01 violators
--    Backfills participant rows for approved/paid apps that have none.
-- ─────────────────────────────────────────────────────────
INSERT INTO public.event_participants (
  event_id, ticket_id, user_id, application_id, status, ticket_code,
  display_name, birth_year
)
SELECT
  a.event_id,
  a.ticket_id,
  a.user_id,
  a.id,
  'ticket_issued',
  upper(substring(md5(gen_random_uuid()::text) FROM 1 FOR 8)),
  up.name,
  extract(year FROM up.birth_date)::int
FROM public.event_applications a
JOIN public.user_profiles up ON up.id = a.user_id
LEFT JOIN public.event_participants p
  ON p.event_id = a.event_id AND p.user_id = a.user_id
WHERE a.status IN ('approved', 'paid')
  AND p.id IS NULL;

-- ─────────────────────────────────────────────────────────
-- 3. Fix issue_ticket_on_approval trigger: handle INSERT (OLD IS NULL)
--    Original condition: `old.status NOT IN ('approved', 'paid')`
--    For INSERT triggers OLD IS NULL, so `NULL NOT IN (...)` = NULL (falsy) → trigger never fires.
--    Fix: `(OLD IS NULL OR old.status NOT IN ('approved', 'paid'))` covers INSERT case.
-- ─────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.issue_ticket_on_approval()
RETURNS trigger
SET search_path = public
AS $$
DECLARE
  v_display_name text;
  v_birth_year int;
BEGIN
  -- Fix #1660: OLD IS NULL for INSERT triggers; the original condition missed direct-insert applications.
  IF (new.status IN ('approved', 'paid')
      AND (OLD IS NULL OR old.status NOT IN ('approved', 'paid'))) THEN
    SELECT name, extract(year FROM birth_date)::int
    INTO v_display_name, v_birth_year
    FROM public.user_profiles WHERE id = new.user_id;

    INSERT INTO public.event_participants (
      event_id, ticket_id, user_id, application_id, status, ticket_code,
      display_name, birth_year
    )
    VALUES (
      new.event_id, new.ticket_id, new.user_id, new.id, 'ticket_issued',
      upper(substring(md5(gen_random_uuid()::text) FROM 1 FOR 8)),
      v_display_name, v_birth_year
    )
    ON CONFLICT (event_id, user_id) DO NOTHING;
  END IF;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─────────────────────────────────────────────────────────
-- 4. Fix apply_event RPC: free events use 'approved' status (not 'paid')
--    Old logic: p_verification_data IS NULL → v_status = 'paid' (incorrect for free events)
--    New logic: only 'paid' when payment_id is provided; free events (payment_id IS NULL) get 'approved'
-- ─────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.apply_event(
  p_event_id uuid,
  p_ticket_id uuid,
  p_user_id uuid,
  p_payment_id text,
  p_payment_amount int,
  p_verification_data jsonb DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_app_id uuid;
  v_status text := 'pending_review';
  v_balance_result jsonb;
  v_event_status text;
BEGIN
  -- Fix #998: Validate event status — only 'scheduled' and 'active' allow applications
  SELECT status INTO v_event_status
  FROM public.events
  WHERE id = p_event_id;

  IF v_event_status IS NULL THEN
    RAISE EXCEPTION '존재하지 않는 이벤트입니다.'
      USING ERRCODE = 'P0002';
  END IF;

  IF v_event_status NOT IN ('scheduled', 'active') THEN
    RAISE EXCEPTION '신청 불가 상태의 이벤트입니다: %', v_event_status
      USING ERRCODE = 'P0001';
  END IF;

  v_balance_result := public.check_party_balance(p_event_id, p_ticket_id);
  IF (v_balance_result->>'allowed')::boolean IS NOT TRUE THEN
    RAISE EXCEPTION '성비 균형 제한: %', v_balance_result->>'reason'
      USING ERRCODE = 'P0001';
  END IF;

  -- Fix #1660: paid apps must have payment_id (INV-05).
  --   Free events (payment_id IS NULL) → 'approved' (auto-approved, no payment).
  --   Paid events (payment_id IS NOT NULL, no verification) → 'paid'.
  IF p_verification_data IS NULL THEN
    IF p_payment_id IS NOT NULL THEN
      v_status := 'paid';
    ELSE
      v_status := 'approved';
    END IF;
  END IF;

  INSERT INTO public.event_applications (
    event_id, ticket_id, user_id,
    payment_id, payment_amount, status
  )
  VALUES (
    p_event_id, p_ticket_id, p_user_id,
    p_payment_id, p_payment_amount, v_status
  )
  RETURNING id INTO v_app_id;

  IF (p_verification_data IS NOT NULL) THEN
    INSERT INTO public.user_verifications (user_id, verification_id, data)
    VALUES (
      p_user_id,
      (p_verification_data->>'verification_id')::uuid,
      p_verification_data->'data'
    )
    ON CONFLICT (user_id, verification_id)
    DO UPDATE SET data = EXCLUDED.data, updated_at = now();

    INSERT INTO public.verification_submissions (
      partner_id, user_id, verification_id, application_id,
      status, snapshot_data
    )
    VALUES (
      (p_verification_data->>'partner_id')::uuid,
      p_user_id,
      (p_verification_data->>'verification_id')::uuid,
      v_app_id,
      'pending',
      p_verification_data->'data'
    );
  END IF;

  RETURN v_app_id;
END;
$$;
