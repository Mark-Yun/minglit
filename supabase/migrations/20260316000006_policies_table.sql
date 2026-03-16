-- ============================================================
-- policies — Admin-managed policy store
-- Stores versioned, time-effective policies in JSONB format.
-- Clients read via get_current_policy() RPC.
-- ============================================================

-- ============================================================
-- 1. policies table
-- ============================================================
CREATE TABLE public.policies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  key text NOT NULL,
  value jsonb NOT NULL DEFAULT '{}',
  version integer NOT NULL DEFAULT 1,
  effective_date timestamptz NOT NULL DEFAULT now(),
  description text,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT policies_key_effective_date_unique UNIQUE(key, effective_date)
);


-- ============================================================
-- 2. RLS
-- ============================================================
ALTER TABLE public.policies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "authenticated_read_policies" ON public.policies
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "service_role_all_policies" ON public.policies
  FOR ALL USING (auth.role() = 'service_role');

-- ============================================================
-- 3. GRANT
-- ============================================================
GRANT SELECT ON public.policies TO authenticated;
GRANT ALL ON public.policies TO service_role;

-- ============================================================
-- 4. get_current_policy() RPC
-- Returns the currently effective policy JSONB for a given key.
-- Uses p_at parameter for testability (default: now()).
-- Returns NULL if no policy found for given key/time.
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_current_policy(
  p_key text,
  p_at timestamptz DEFAULT now()
)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT value FROM public.policies
  WHERE key = p_key
    AND effective_date <= p_at
  ORDER BY effective_date DESC, version DESC
  LIMIT 1;
$$;

REVOKE EXECUTE ON FUNCTION public.get_current_policy(text, timestamptz) FROM public;
GRANT EXECUTE ON FUNCTION public.get_current_policy(text, timestamptz) TO authenticated, service_role;

-- ============================================================
-- 5. Seed — Default refund policy (source of truth: RefundCalculator)
-- tiers sorted by min_days_before DESC (most days first)
-- ============================================================
INSERT INTO public.policies (key, value, version, effective_date, description)
VALUES (
  'refund',
  '{
    "tiers": [
      {"min_days_before": 7, "refund_percentage": 100},
      {"min_days_before": 3, "refund_percentage": 80},
      {"min_days_before": 1, "refund_percentage": 50},
      {"min_days_before": 0, "refund_percentage": 0}
    ]
  }'::jsonb,
  1,
  '2026-01-01T00:00:00Z'::timestamptz,
  'Default refund policy — 4 tier: 7+ days=100%, 3-7 days=80%, 1-3 days=50%, <1 day=0%'
);
