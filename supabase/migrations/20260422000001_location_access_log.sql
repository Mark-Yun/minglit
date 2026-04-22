-- 위치정보법 §16: 위치정보 이용·제공 확인자료 6개월 보관
-- GPS 좌표 원문은 저장 금지 (방침: "서버에 영구 저장하지 않음")

CREATE TABLE public.location_access_log (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id     uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  accessed_at timestamptz NOT NULL DEFAULT now(),
  purpose     text NOT NULL CHECK (purpose IN ('nearby_search')),
  country_code text
);

CREATE INDEX idx_location_access_log_accessed_at
  ON public.location_access_log(accessed_at);

ALTER TABLE public.location_access_log ENABLE ROW LEVEL SECURITY;

-- 서비스 역할만 INSERT/DELETE (EF에서 service client로 기록)
CREATE POLICY "service_role full access"
  ON public.location_access_log
  FOR ALL TO service_role USING (true) WITH CHECK (true);

-- 본인 기록 조회 허용
CREATE POLICY "users read own logs"
  ON public.location_access_log
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

-- 위치정보법 §16 retention 정책 등록 (PR #1693 인프라 의존)
INSERT INTO admin.retention_policies
  (id, kind, retention_days, legal_min_days, target, description)
VALUES
  ('location_access_log', 'db_table', 180, 180,
   '{"schema":"public","table":"location_access_log","ts_col":"accessed_at"}',
   '위치정보법 §16 — 위치정보 이용·제공 확인자료 6개월');

GRANT INSERT ON public.location_access_log TO service_role;
GRANT SELECT ON public.location_access_log TO authenticated;
