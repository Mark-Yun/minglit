-- Fix: PostgREST 가 admin 스키마를 expose 하지 않아 supabase-js 의 .schema("admin") 호출이
--      "Invalid schema: admin" 으로 거부됨. cleanup-retention EF (및 admin 스키마 사용하는 모든
--      EF) 가 동작 못 함.
--
-- 원인: admin 스키마 생성 PR (20260421000002_add_admin_schema_retention_policies.sql) 에서
--      service_role 에 GRANT 만 하고 PostgREST 의 db_schemas 설정 누락. supabase/config.toml
--      에는 schemas = ["public", "graphql_public", "admin"] 적혀있으나 이는 로컬 전용. 원격
--      Supabase 프로젝트는 authenticator role 의 pgrst.db_schemas GUC 를 봄.
--
-- 영향: cleanup-retention 호출 시 500 "Invalid schema: admin" — cron 401 (vault 누락) 해결 후
--      표면화. 그 외 admin 스키마 직접 사용하는 EF 도 동일.
--
-- 적용 후 NOTIFY pgrst, 'reload config' 로 PostgREST 가 즉시 새 설정 반영.

-- 현재 값 확인용 주석 (실행 시 NOTICE):
-- 기본 Supabase 프로젝트는 'public, graphql_public, storage' 가 노출됨.
-- 본 변경은 'admin' 추가.
DO $$
DECLARE
  current_schemas text;
BEGIN
  SELECT setting INTO current_schemas
  FROM pg_db_role_setting drs
  JOIN pg_roles r ON r.oid = drs.setrole
  CROSS JOIN unnest(drs.setconfig) AS s(setting)
  WHERE r.rolname = 'authenticator' AND s.setting LIKE 'pgrst.db_schemas=%'
  LIMIT 1;

  IF current_schemas IS NULL THEN
    RAISE NOTICE 'pgrst.db_schemas not currently set on authenticator (Supabase platform default in use)';
  ELSE
    RAISE NOTICE 'pgrst.db_schemas was: %', current_schemas;
  END IF;
END $$;

ALTER ROLE authenticator SET pgrst.db_schemas TO 'public, graphql_public, admin';

-- PostgREST 즉시 리로드 (NOTIFY 채널은 PostgREST 가 listen 중)
NOTIFY pgrst, 'reload config';
