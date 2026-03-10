-- Add missing wizard columns to partner_applications
-- These should have been added in 20260307000002 but were not applied

ALTER TABLE public.partner_applications ADD COLUMN IF NOT EXISTS profile_image_path text;
ALTER TABLE public.partner_applications ADD COLUMN IF NOT EXISTS current_step integer DEFAULT 0;
