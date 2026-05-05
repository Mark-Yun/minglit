-- pgTAP tests for PostgREST exposed schemas (authenticator role pgrst.db_schemas GUC).
-- migration: 20260505000002_postgrest_expose_admin_schema.sql
--
-- 의도: GUC 가 누락되거나 다른 migration 에서 덮어써질 때 즉시 fail 시키는 regression 가드.
--      migration 적용 후 PostgREST 가 노출하는 스키마 목록을 실측 검증.

BEGIN;

SELECT plan(4);

-- 헬퍼 view: authenticator role 의 pgrst.db_schemas 값 추출
CREATE TEMP VIEW _exposed_schemas AS
  SELECT trim(replace(s.setting, 'pgrst.db_schemas=', '')) AS value
  FROM pg_db_role_setting drs
  JOIN pg_roles r ON r.oid = drs.setrole
  CROSS JOIN unnest(drs.setconfig) AS s(setting)
  WHERE r.rolname = 'authenticator'
    AND s.setting LIKE 'pgrst.db_schemas=%';

-- 1. GUC 자체가 설정되어 있어야 함
SELECT ok(
  EXISTS (SELECT 1 FROM _exposed_schemas),
  'authenticator role must have pgrst.db_schemas GUC set'
);

-- 2~4. 필수 스키마 각각 포함 확인
-- Note: GUC value 형식은 "public, graphql_public, admin" — 공백 무관 contains 매칭
SELECT ok(
  EXISTS (
    SELECT 1 FROM _exposed_schemas
    WHERE position('public' IN value) > 0
  ),
  'pgrst.db_schemas must include ''public'' (Supabase default — RLS/RPC entry point)'
);

SELECT ok(
  EXISTS (
    SELECT 1 FROM _exposed_schemas
    WHERE position('graphql_public' IN value) > 0
  ),
  'pgrst.db_schemas must include ''graphql_public'' (pg_graphql endpoint)'
);

SELECT ok(
  EXISTS (
    SELECT 1 FROM _exposed_schemas
    WHERE position('admin' IN value) > 0
  ),
  'pgrst.db_schemas must include ''admin'' (cleanup-retention / process-pending-deletions EF supabase-js .schema(''admin'') 의존)'
);

SELECT * FROM finish();
ROLLBACK;
