-- 08. Cron Jobs + Event Routes Data
-- Squashed from: 15_settlements.sql (cron), 25_notification_worker_cron.sql, 28_event_reminder_cron.sql (cron), 30_event_routes_migration.sql
-- NOTE: process-global-events cron is excluded (disabled)
set search_path to public, extensions;

-- ============================================================
-- 1. Event Routes (UNIQUE constraint + data)
-- ============================================================

ALTER TABLE public.event_routes
  ADD CONSTRAINT event_routes_type_queue_unique
  UNIQUE (event_type, target_queue);

INSERT INTO public.event_routes (event_type, target_queue, is_active) VALUES
  ('party_created',        'q_notifications', true),
  ('party_created',        'q_vectors',       true),
  ('user_interaction',     'q_notifications', true),
  ('user_interaction',     'q_vectors',       true),
  ('application_approved', 'q_notifications', true),
  ('application_rejected', 'q_notifications', true),
  ('event_updated',        'q_notifications', true),
  ('event_cancelled',      'q_notifications', true),
  ('new_application',      'q_notifications', true),
  ('verification_result',  'q_notifications', true),
  ('event_reminder',       'q_notifications', true)
ON CONFLICT (event_type, target_queue) DO UPDATE SET is_active = EXCLUDED.is_active;

-- ============================================================
-- 2. Cron: process-notifications (every minute)
-- ============================================================

select cron.schedule(
  'process-notifications',
  '* * * * *',
  $$
    select net.http_post(
      url:='https://cnuahgrfzcqkmdyhunuk.supabase.co/functions/v1/notification-worker',
      headers:=(
        jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'service_role_key' limit 1)
        )
      ),
      body:='{}'::jsonb
    ) as request_id;
  $$
);

-- ============================================================
-- 3. Cron: send-event-reminders (every minute)
-- ============================================================

select cron.schedule(
  'send-event-reminders',
  '* * * * *',
  $$select public.send_event_reminders();$$
);

-- ============================================================
-- 4. Cron: settlement-status-transition (daily at 3AM)
-- ============================================================

select cron.schedule(
  'settlement-status-transition',
  '0 3 * * *',
  $$
    select public.update_settlement_ready_status();
  $$
);
