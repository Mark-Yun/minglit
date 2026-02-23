-- Migration: Add event_routes as migration data (moved from seed.sql)
-- Activates q_vectors routes for party_created and user_interaction
-- All 9 event types route to q_notifications
-- Only party_created and user_interaction route to q_vectors (vector-worker handles these)

-- Add UNIQUE constraint to prevent duplicate routes
DO $$ BEGIN
  ALTER TABLE public.event_routes
    ADD CONSTRAINT event_routes_type_queue_unique
    UNIQUE (event_type, target_queue);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Insert routes with proper conflict handling
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
