-- Fix #1760: pg_cron ↔ EF auth drift 방지 — ef_auth_manifest 선언 테이블
--
-- 범위: pg_cron에서 net.http_post로 호출하는 EF만 등록한다.
--   (사용자 요청 EF는 포함하지 않음 — auth 계층이 달라 일관성 보장 범위 밖)
--
-- 목적: PR #1494의 requireServiceRole() 추가 후 pg_cron Authorization이
--       업데이트되지 않아 6일간 무음 401 발생. 이를 재발 방지하기 위해
--       cron 대상 EF의 필요 인증 레벨을 선언하고 pgTAP으로 일관성을 검증한다.
--
-- 유지보수 규칙: pg_cron에서 새 EF를 HTTP 호출할 때
--   같은 PR에서 이 테이블에 항목을 추가할 것.

CREATE TABLE IF NOT EXISTS public.ef_auth_manifest (
  ef_name     text PRIMARY KEY,
  required_auth text NOT NULL CHECK (required_auth IN (
    'service_role'
  )),
  description text,
  updated_at  timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.ef_auth_manifest IS
  'pg_cron에서 net.http_post로 호출하는 EF의 인증 레벨 선언 (cron-targeted EF 전용). '
  'pg_cron에서 새 EF를 HTTP 호출할 때 required_auth도 같은 PR에서 추가 필수. '
  'pgTAP 95_ef_auth_manifest_cron_consistency_test.sql이 cron.job과의 일관성을 검증한다.';

ALTER TABLE public.ef_auth_manifest ENABLE ROW LEVEL SECURITY;
CREATE POLICY ef_auth_manifest_select ON public.ef_auth_manifest
  FOR SELECT USING (true);

-- ──────────────────────────────────────────────────────────
-- 초기 seed: pg_cron에서 HTTP 호출하는 EF 목록
-- (20260423000001_cron_use_service_role_key.sql 기준 + 기존 cron EF 포함)
-- ──────────────────────────────────────────────────────────

INSERT INTO public.ef_auth_manifest (ef_name, required_auth, description) VALUES
  ('ai-extract-tags',               'service_role', 'AI 태그 추출 — pg_cron 매분 호출'),
  ('backend-simulator',             'service_role', '백엔드 시뮬레이션 — pg_cron 매시간 호출'),
  ('cleanup-blocked-dis',           'service_role', '차단/신고 삭제 정리 — pg_cron 호출'),
  ('cleanup-retention',             'service_role', 'retention 정책 실행 — pg_cron 호출'),
  ('github-stats-sync',             'service_role', 'GitHub 통계 동기화 — pg_cron 매일 호출'),
  ('metrics-alert',                 'service_role', '메트릭 알람 — pg_cron 매 30분 호출'),
  ('notification-worker',           'service_role', '알림 워커 — pg_cron 매분 호출'),
  ('payout-sync',                   'service_role', '정산 지급 동기화 — pg_cron 호출'),
  ('process-pending-deletions',     'service_role', '지연 삭제 처리 — pg_cron 호출'),
  ('reconciliation-daily',          'service_role', '정산 대사 — pg_cron 매일 호출'),
  ('recurrence-cron',               'service_role', '반복 이벤트 생성 — pg_cron 호출'),
  ('settlement-register-transfers', 'service_role', '정산 이전 등록 — pg_cron 호출')

ON CONFLICT (ef_name) DO UPDATE SET
  required_auth = EXCLUDED.required_auth,
  description   = EXCLUDED.description,
  updated_at    = now();
