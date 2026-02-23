set search_path to public, extensions;

ALTER TABLE public.event_applications ADD COLUMN IF NOT EXISTS refund_amount integer DEFAULT 0;

ALTER TABLE public.partners ADD COLUMN IF NOT EXISTS portone_partner_id text;
CREATE INDEX IF NOT EXISTS partners_portone_partner_id_idx ON public.partners(portone_partner_id);
