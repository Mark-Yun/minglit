-- Fix #1760: pg_cron ↔ ef_auth_manifest 일관성 검증
--
-- 범위: pg_cron에서 net.http_post로 호출하는 EF만 검증 (cron-targeted EF 전용).
--   ef_auth_manifest는 cron 대상 EF만 포함하므로 사용자 요청 EF는 검증 범위 밖.
--
-- 재발 방지: PR #1494에서 requireServiceRole() 추가 후 pg_cron Authorization이 누락되어
--            6일간 401 무음 실패. 이 테스트가 PR 차단으로 즉시 감지한다.

BEGIN;
SELECT plan(4);

CREATE OR REPLACE FUNCTION _extract_cron_authorization_vault_key(p_command text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $fn$
  SELECT (
    regexp_match(
      p_command,
      $re$'Authorization'\s*,\s*'Bearer '\s*\|\|\s*\(\s*SELECT\s+decrypted_secret\s+FROM\s+vault\.decrypted_secrets\s+WHERE\s+name\s*=\s*'([a-z_]+)'\s+LIMIT$re$,
      'is'
    )
  )[1];
$fn$;

CREATE OR REPLACE FUNCTION _extract_cron_apikey_vault_key(p_command text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $fn$
  SELECT (
    regexp_match(
      p_command,
      $re$'apikey'\s*,\s*\(\s*SELECT\s+decrypted_secret\s+FROM\s+vault\.decrypted_secrets\s+WHERE\s+name\s*=\s*'([a-z_]+)'\s+LIMIT$re$,
      'is'
    )
  )[1];
$fn$;

-- ── 헬퍼: cron.job에서 EF 이름과 Authorization vault key 추출
-- regexp_match (scalar, Pg10+) 사용 — regexp_matches with 'g' is set-returning and
-- produces extra NULL-ef_name rows when combined with another SRF in SELECT.
-- vault_key는 Authorization 헤더에 사용되는 두 번째 vault lookup을 특정.
CREATE TEMP TABLE _cron_ef_calls AS
SELECT
  jobname,
  (regexp_match(command, '/functions/v1/([a-z][a-z0-9-]+)'))[1]      AS ef_name,
  _extract_cron_authorization_vault_key(command) AS auth_vault_key,
  _extract_cron_apikey_vault_key(command) AS apikey_vault_key
FROM cron.job
WHERE command LIKE '%net.http_post%'
  AND command LIKE '%/functions/v1/%';

-- ── 1. apikey extractor는 Authorization lookup으로 넘어가지 않아야 함
SELECT is(
  _extract_cron_apikey_vault_key($fixture$
    SELECT net.http_post(
      url := 'https://example.supabase.co/functions/v1/notification-worker',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'apikey', (
          SELECT decrypted_secret FROM vault.decrypted_secrets
          WHERE name = 'publishable_key' LIMIT 1
        ),
        'Authorization', 'Bearer ' || (
          SELECT decrypted_secret FROM vault.decrypted_secrets
          WHERE name = 'service_role_key' LIMIT 1
        )
      ),
      body := '{}'::jsonb
    ) AS request_id;
  $fixture$),
  'publishable_key',
  'apikey vault-key extractor must not fall through to Authorization lookup'
);

-- ── 2. manifest에 등록된 EF는 반드시 service_role_key vault secret 사용
--    (publishable_key 또는 다른 key → 401 발생)
SELECT is(
  (
    SELECT count(*)::int
    FROM _cron_ef_calls c
    JOIN public.ef_auth_manifest m ON m.ef_name = c.ef_name
    WHERE (c.auth_vault_key IS NULL OR c.auth_vault_key != 'service_role_key')
  ),
  0,
  'All pg_cron EFs in manifest must use service_role_key vault secret for Authorization'
);

-- ── 3. manifest에 등록된 EF는 sb_secret_ 호환을 위해 apikey 헤더도 service_role_key 사용
SELECT is(
  (
    SELECT count(*)::int
    FROM _cron_ef_calls c
    JOIN public.ef_auth_manifest m ON m.ef_name = c.ef_name
    WHERE (c.apikey_vault_key IS NULL OR c.apikey_vault_key != 'service_role_key')
  ),
  0,
  'All pg_cron EFs in manifest must use service_role_key vault secret for apikey'
);

-- ── 4. pg_cron에서 HTTP 호출하는 EF는 반드시 manifest에 등록되어 있어야 함
--    (신규 EF를 pg_cron에 추가할 때 manifest 업데이트를 강제)
SELECT is(
  (
    SELECT count(*)::int
    FROM _cron_ef_calls c
    LEFT JOIN public.ef_auth_manifest m ON m.ef_name = c.ef_name
    WHERE m.ef_name IS NULL
  ),
  0,
  'All EFs called by pg_cron via HTTP must be declared in ef_auth_manifest'
);

SELECT * FROM finish();
ROLLBACK;
