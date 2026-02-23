-- Migration: Extend event_type_name enum with new event types for 2-tier queue architecture
-- Adds 7 new event types to support the full pipeline (9 total)

ALTER TYPE public.event_type_name ADD VALUE IF NOT EXISTS 'application_approved';
ALTER TYPE public.event_type_name ADD VALUE IF NOT EXISTS 'application_rejected';
ALTER TYPE public.event_type_name ADD VALUE IF NOT EXISTS 'event_updated';
ALTER TYPE public.event_type_name ADD VALUE IF NOT EXISTS 'event_cancelled';
ALTER TYPE public.event_type_name ADD VALUE IF NOT EXISTS 'new_application';
ALTER TYPE public.event_type_name ADD VALUE IF NOT EXISTS 'verification_result';
ALTER TYPE public.event_type_name ADD VALUE IF NOT EXISTS 'event_reminder';
