-- Account deletion foundation: soft-delete column + service-role-only tables

ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

CREATE INDEX IF NOT EXISTS idx_user_profiles_deleted_at
  ON public.user_profiles (deleted_at);

CREATE TABLE public.withdrawal_reasons (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  reason_code text NOT NULL,
  reason_text text,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT withdrawal_reasons_reason_text_length_check
    CHECK (reason_text IS NULL OR char_length(reason_text) <= 200)
);

CREATE TABLE public.blocked_dis (
  di_hash text PRIMARY KEY,
  blocked_until timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.archived_records (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id_hash text NOT NULL,
  record_type text NOT NULL,
  record_data jsonb NOT NULL,
  retention_until timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT archived_records_record_type_check
    CHECK (record_type IN ('contract', 'payment', 'dispute', 'login'))
);

CREATE INDEX idx_blocked_dis_blocked_until
  ON public.blocked_dis (blocked_until);

CREATE INDEX idx_archived_records_retention_until
  ON public.archived_records (retention_until);

ALTER TABLE public.withdrawal_reasons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blocked_dis ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.archived_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "service_role_only" ON public.withdrawal_reasons
  FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "service_role_only" ON public.blocked_dis
  FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "service_role_only" ON public.archived_records
  FOR ALL USING (auth.role() = 'service_role');

REVOKE ALL ON public.withdrawal_reasons FROM PUBLIC, anon, authenticated;
REVOKE ALL ON public.blocked_dis FROM PUBLIC, anon, authenticated;
REVOKE ALL ON public.archived_records FROM PUBLIC, anon, authenticated;

GRANT ALL ON public.withdrawal_reasons TO service_role;
GRANT ALL ON public.blocked_dis TO service_role;
GRANT ALL ON public.archived_records TO service_role;

GRANT USAGE, SELECT ON SEQUENCE public.withdrawal_reasons_id_seq TO service_role;
GRANT USAGE, SELECT ON SEQUENCE public.archived_records_id_seq TO service_role;
