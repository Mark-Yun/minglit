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
