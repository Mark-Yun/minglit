-- Fix #2110: event_change_log table — records schedule/metadata changes made
-- by partners with reason and before/after snapshot. Required by spec
-- apps/mds/docs/public/specs/event_edit_page.html §알림 발송 정책.
-- push notification is triggered by existing trigger_produce_event_events().
-- Constraint: reason-enriched notification body + SMS fan-out deferred to
-- follow-up issue (partner-manage-event EF + notification-worker extension).

CREATE TABLE IF NOT EXISTS public.event_change_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  -- changed_by is the authenticated user (partner) who triggered the change
  changed_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  previous_start_time TIMESTAMPTZ,
  new_start_time TIMESTAMPTZ,
  previous_end_time TIMESTAMPTZ,
  new_end_time TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Partners can only read their own event's change logs (via party ownership).
-- No direct insert RLS — inserts are service_role only (via EF).
ALTER TABLE public.event_change_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "partner_read_own_event_change_logs"
  ON public.event_change_logs
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.events e
      JOIN public.parties p ON p.id = e.party_id
      WHERE e.id = event_change_logs.event_id
        AND p.partner_id = auth.uid()
    )
  );

-- Index for common query: all logs for an event, newest first.
CREATE INDEX idx_event_change_logs_event_id_created_at
  ON public.event_change_logs(event_id, created_at DESC);
