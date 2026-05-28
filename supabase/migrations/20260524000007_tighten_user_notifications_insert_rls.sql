-- Fix #2755: remove always-true INSERT RLS for user_notifications.
-- Notification writes are service-role only through notification-worker/EF paths.

DROP POLICY IF EXISTS "Service role can insert notifications" ON public.user_notifications;

CREATE POLICY "Service role can insert notifications"
  ON public.user_notifications
  FOR INSERT
  WITH CHECK (auth.role() = 'service_role');

REVOKE INSERT ON public.user_notifications FROM PUBLIC, anon, authenticated;
GRANT INSERT ON public.user_notifications TO service_role;
