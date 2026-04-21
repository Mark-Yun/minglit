-- feat #1692: admin 스키마 + retention_policies — DB/Storage 자동 cleanup 파이프라인

-- 1. admin 스키마 생성 + 권한 설정
CREATE SCHEMA IF NOT EXISTS admin;

REVOKE ALL ON SCHEMA admin FROM anon, authenticated;
GRANT USAGE ON SCHEMA admin TO service_role, postgres;

ALTER DEFAULT PRIVILEGES IN SCHEMA admin
  REVOKE ALL ON TABLES FROM anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA admin
  GRANT ALL ON TABLES TO service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA admin
  REVOKE ALL ON SEQUENCES FROM anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA admin
  GRANT ALL ON SEQUENCES TO service_role;

-- 2. ENUM 타입
CREATE TYPE admin.retention_kind AS ENUM (
  'db_table',
  'storage_bucket',
  'pgmq_archive'
);

-- 3. 메인 정책 테이블
CREATE TABLE admin.retention_policies (
  id                    text           PRIMARY KEY,
  kind                  admin.retention_kind NOT NULL,
  retention_days        int            NOT NULL CHECK (retention_days > 0),
  legal_min_days        int            CHECK (legal_min_days IS NULL OR legal_min_days > 0),
  target                jsonb          NOT NULL,
  enabled               boolean        NOT NULL DEFAULT true,
  description           text,
  metadata              jsonb          NOT NULL DEFAULT '{}',
  updated_at            timestamptz    NOT NULL DEFAULT now(),
  updated_by            uuid           REFERENCES auth.users(id),
  last_run_at           timestamptz,
  last_run_duration_ms  int,
  last_run_rows_deleted bigint,
  last_run_status       text           CHECK (last_run_status IN ('success', 'error', 'skipped')),
  last_run_message      text,
  CONSTRAINT retention_above_legal_min CHECK (
    legal_min_days IS NULL OR retention_days >= legal_min_days
  )
);

CREATE INDEX retention_policies_enabled_idx
  ON admin.retention_policies(enabled) WHERE enabled;
CREATE INDEX retention_policies_kind_idx
  ON admin.retention_policies(kind);

-- 4. 감사 로그 테이블
CREATE TABLE admin.retention_policy_audit (
  id              bigserial      PRIMARY KEY,
  policy_id       text           NOT NULL,
  action          text           NOT NULL CHECK (action IN ('create', 'update', 'delete', 'run', 'enable', 'disable')),
  before_state    jsonb,
  after_state     jsonb,
  rows_deleted    bigint,
  duration_ms     int,
  error           text,
  actor           uuid,
  acted_at        timestamptz    NOT NULL DEFAULT now()
);

CREATE INDEX retention_audit_policy_idx
  ON admin.retention_policy_audit(policy_id, acted_at DESC);

-- 5. 감사 트리거 함수 + 트리거
CREATE OR REPLACE FUNCTION admin.log_retention_policy_change()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO admin.retention_policy_audit (
    policy_id, action, before_state, after_state, actor
  ) VALUES (
    COALESCE(NEW.id, OLD.id),
    CASE TG_OP
      WHEN 'INSERT' THEN 'create'
      WHEN 'UPDATE' THEN 'update'
      WHEN 'DELETE' THEN 'delete'
    END,
    CASE WHEN TG_OP != 'INSERT' THEN row_to_json(OLD)::jsonb END,
    CASE WHEN TG_OP != 'DELETE' THEN row_to_json(NEW)::jsonb END,
    auth.uid()
  );
  RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE TRIGGER retention_policies_audit_trig
  AFTER INSERT OR UPDATE OR DELETE ON admin.retention_policies
  FOR EACH ROW EXECUTE FUNCTION admin.log_retention_policy_change();

-- 6. 도우미 함수: db_table DELETE
CREATE OR REPLACE FUNCTION admin.delete_old_rows(
  p_schema      text,
  p_table       text,
  p_ts_col      text,
  p_cutoff_days int
) RETURNS bigint LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  deleted_count bigint;
BEGIN
  IF p_schema NOT IN ('cron', 'net', 'auth', 'public', 'pgmq') THEN
    RAISE EXCEPTION 'Disallowed schema: %', p_schema;
  END IF;
  EXECUTE format(
    'DELETE FROM %I.%I WHERE %I < now() - $1 * interval ''1 day''',
    p_schema, p_table, p_ts_col
  ) USING p_cutoff_days;
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$;

GRANT EXECUTE ON FUNCTION admin.delete_old_rows(text, text, text, int) TO service_role;

-- 7. 도우미 함수: pgmq archive
CREATE OR REPLACE FUNCTION admin.archive_old_pgmq_messages(
  p_queue_name  text,
  p_cutoff_days int
) RETURNS bigint LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  archived_count bigint := 0;
  msg_rec record;
BEGIN
  FOR msg_rec IN
    EXECUTE format(
      'SELECT msg_id FROM pgmq.q_%I WHERE enqueued_at < now() - $1 * interval ''1 day'' LIMIT 10000',
      p_queue_name
    ) USING p_cutoff_days
  LOOP
    PERFORM pgmq.archive(p_queue_name, msg_rec.msg_id);
    archived_count := archived_count + 1;
  END LOOP;
  RETURN archived_count;
END;
$$;

GRANT EXECUTE ON FUNCTION admin.archive_old_pgmq_messages(text, int) TO service_role;

-- 8. RLS 정책
ALTER TABLE admin.retention_policies ENABLE ROW LEVEL SECURITY;

CREATE POLICY retention_admin_all ON admin.retention_policies
  USING (EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid() AND role = 'admin'
  ));

ALTER TABLE admin.retention_policy_audit ENABLE ROW LEVEL SECURITY;

CREATE POLICY retention_audit_admin_read ON admin.retention_policy_audit
  FOR SELECT USING (EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid() AND role = 'admin'
  ));

-- 9. 초기 seed 데이터 (6개 기본 정책)
INSERT INTO admin.retention_policies (id, kind, retention_days, target, description)
VALUES
  (
    'cron_job_run_details',
    'db_table',
    30,
    '{"schema":"cron","table":"job_run_details","ts_col":"end_time"}',
    'pg_cron 실행 이력'
  ),
  (
    'net_http_response',
    'db_table',
    7,
    '{"schema":"net","table":"_http_response","ts_col":"created"}',
    'net.http_post 응답 로그'
  ),
  (
    'pgmq_global_events_archive',
    'pgmq_archive',
    14,
    '{"queue_name":"q_global_events"}',
    'global_events 큐 archive'
  ),
  (
    'pgmq_vectors_archive',
    'pgmq_archive',
    14,
    '{"queue_name":"q_vectors"}',
    'vectors 큐 archive (pgvector 비동기)'
  ),
  (
    'pgmq_notifications_archive',
    'pgmq_archive',
    7,
    '{"queue_name":"q_notifications"}',
    'notifications 큐 archive'
  ),
  (
    'storage_bug_reports',
    'storage_bucket',
    30,
    '{"bucket_id":"bug-report-attachments","path_prefix":""}',
    'QA 버그 리포트 첨부파일'
  )
ON CONFLICT (id) DO NOTHING;
