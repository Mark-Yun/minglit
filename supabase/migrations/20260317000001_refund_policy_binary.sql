ALTER TABLE public.event_applications
  ADD COLUMN IF NOT EXISTS paid_at timestamptz;

INSERT INTO public.policies (key, value, version, effective_date, description)
VALUES (
  'refund',
  '{"grace_period_hours": 2, "cutoff_days": 7}'::jsonb,
  2,
  '2026-03-01T00:00:00Z'::timestamptz,
  'Binary refund: full refund within 2h of payment OR 7+ days before event'
);
