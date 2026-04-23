-- Fix #1760: pg_cron ↔ ef_auth_manifest 일관성 검증
-- 목적: cron.job의 Authorization vault key가 manifest의 required_auth와 일치하는지 검증.
--       service_role EF는 service_role_key, 그 외 EF는 pg_cron에서 호출하면 안 됨.
--
-- 재발 방지: PR #1494에서 requireServiceRole() 추가 후 pg_cron Authorization이 누락되어
--            6일간 401 무음 실패. 이 테스트가 PR 차단으로 즉시 감지한다.

BEGIN;
SELECT plan(3);

-- ── 헬퍼: cron.job에서 EF 이름과 Authorization vault key 추출
CREATE TEMP TABLE _cron_ef_calls AS
SELECT
  jobname,
  (regexp_matches(command, E'/functions/v1/([a-z][a-z0-9-]+)'))[1]      AS ef_name,
  (regexp_matches(command, E'WHERE name\\s*=\\s*''([a-z_]+)''\\s+LIMIT', 'g'))[1] AS vault_key
FROM cron.job
WHERE command LIKE '%net.http_post%'
  AND command LIKE '%/functions/v1/%';

-- ── 1. service_role EF는 반드시 service_role_key vault secret 사용
--    (publishable_key 또는 다른 key → 401 발생)
SELECT is(
  (
    SELECT count(*)::int
    FROM _cron_ef_calls c
    JOIN public.ef_auth_manifest m ON m.ef_name = c.ef_name
    WHERE m.required_auth = 'service_role'
      AND (c.vault_key IS NULL OR c.vault_key != 'service_role_key')
  ),
  0,
  'All service_role EFs in pg_cron must use service_role_key vault secret'
);

-- ── 2. authenticated/public EF는 pg_cron에서 호출하면 안 됨
--    (pg_cron은 사용자 세션이 없으므로 JWT에 user 정보가 없음)
SELECT is(
  (
    SELECT count(*)::int
    FROM _cron_ef_calls c
    JOIN public.ef_auth_manifest m ON m.ef_name = c.ef_name
    WHERE m.required_auth IN ('authenticated', 'public')
  ),
  0,
  'authenticated/public EFs must not be called from pg_cron'
);

-- ── 3. pg_cron에서 호출하는 EF는 manifest에 등록되어 있어야 함
--    (신규 EF 추가 시 manifest 업데이트 강제)
SELECT is(
  (
    SELECT count(*)::int
    FROM _cron_ef_calls c
    LEFT JOIN public.ef_auth_manifest m ON m.ef_name = c.ef_name
    WHERE m.ef_name IS NULL
  ),
  0,
  'All EFs called by pg_cron must be declared in ef_auth_manifest'
);

SELECT * FROM finish();
ROLLBACK;
