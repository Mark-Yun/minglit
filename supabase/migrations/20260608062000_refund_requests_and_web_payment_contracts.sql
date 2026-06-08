-- Issue #3422: web checkout PortOne V2 handoff + partner refund request Track 2.

ALTER TABLE public.event_applications
  DROP CONSTRAINT IF EXISTS event_applications_refund_status_check;

ALTER TABLE public.event_applications
  ADD CONSTRAINT event_applications_refund_status_check
  CHECK (refund_status IN ('none', 'requested', 'completed', 'failed', 'rejected', 'expired'));

CREATE TABLE IF NOT EXISTS public.refund_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id uuid NOT NULL UNIQUE REFERENCES public.event_applications(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  event_id uuid NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  partner_id uuid NOT NULL REFERENCES public.partners(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'rejected', 'expired')),
  reason_code text NOT NULL
    CHECK (reason_code IN ('schedule_change', 'health', 'other')),
  reason_text text,
  requested_at timestamptz NOT NULL DEFAULT now(),
  response_deadline_at timestamptz NOT NULL,
  responded_at timestamptz,
  rejection_reason text,
  refund_amount bigint,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS refund_requests_user_id_idx
  ON public.refund_requests(user_id);
CREATE INDEX IF NOT EXISTS refund_requests_event_id_idx
  ON public.refund_requests(event_id);
CREATE INDEX IF NOT EXISTS refund_requests_partner_id_status_idx
  ON public.refund_requests(partner_id, status);

DROP TRIGGER IF EXISTS handle_updated_at ON public.refund_requests;
CREATE TRIGGER handle_updated_at
  BEFORE UPDATE ON public.refund_requests
  FOR EACH ROW EXECUTE PROCEDURE moddatetime(updated_at);

ALTER TABLE public.refund_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own refund requests" ON public.refund_requests;
CREATE POLICY "Users can read own refund requests" ON public.refund_requests
  FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Partner staff can read refund requests" ON public.refund_requests;
CREATE POLICY "Partner staff can read refund requests" ON public.refund_requests
  FOR SELECT TO authenticated
  USING (public.has_partner_permission(partner_id, 'PARTY_MANAGE'));

REVOKE ALL ON public.refund_requests FROM anon, authenticated;
GRANT SELECT ON public.refund_requests TO authenticated;

CREATE OR REPLACE FUNCTION public.create_partner_refund_request(
  p_application_id uuid,
  p_user_id uuid,
  p_event_id uuid,
  p_partner_id uuid,
  p_reason_code text,
  p_reason_text text,
  p_requested_at timestamptz,
  p_response_deadline_at timestamptz
)
RETURNS TABLE (
  id uuid,
  application_id uuid,
  status text,
  requested_at timestamptz,
  response_deadline_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  WITH inserted AS (
    INSERT INTO public.refund_requests (
      application_id,
      user_id,
      event_id,
      partner_id,
      status,
      reason_code,
      reason_text,
      requested_at,
      response_deadline_at
    )
    VALUES (
      p_application_id,
      p_user_id,
      p_event_id,
      p_partner_id,
      'pending',
      p_reason_code,
      p_reason_text,
      p_requested_at,
      p_response_deadline_at
    )
    RETURNING
      refund_requests.id,
      refund_requests.application_id,
      refund_requests.status,
      refund_requests.requested_at,
      refund_requests.response_deadline_at
  ),
  updated AS (
    UPDATE public.event_applications
    SET refund_status = 'requested',
        updated_at = p_requested_at
    WHERE event_applications.id = p_application_id
      AND event_applications.refund_status = 'none'
    RETURNING event_applications.id
  )
  SELECT
    inserted.id,
    inserted.application_id,
    inserted.status,
    inserted.requested_at,
    inserted.response_deadline_at
  FROM inserted
  WHERE EXISTS (SELECT 1 FROM updated);

  IF NOT FOUND THEN
    RAISE EXCEPTION 'failed_to_mark_refund_requested'
      USING ERRCODE = 'P0001';
  END IF;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.create_partner_refund_request(
  uuid, uuid, uuid, uuid, text, text, timestamptz, timestamptz
) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.create_partner_refund_request(
  uuid, uuid, uuid, uuid, text, text, timestamptz, timestamptz
) TO service_role;
