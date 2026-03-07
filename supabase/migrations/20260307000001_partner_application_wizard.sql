-- Partner Application Wizard: draft support + approval trigger
-- NOTE: ALTER TYPE ADD VALUE cannot run inside a transaction block

-- 1. Add 'draft' status to enum (must be first, outside transaction)
ALTER TYPE public.partner_application_status ADD VALUE IF NOT EXISTS 'draft';
