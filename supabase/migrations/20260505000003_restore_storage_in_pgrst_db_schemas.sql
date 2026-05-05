-- Fix: 20260505000002_postgrest_expose_admin_schema.sql 에서 storage 스키마가 누락됐음.
--
-- 원인: 000002 migration이 pgrst.db_schemas를 'public, graphql_public, admin'으로 하드코딩.
--      Supabase 플랫폼 기본값인 storage 스키마가 제외됨.
--
-- 영향: PostgREST를 통해 storage 스키마를 직접 접근하는 경로 (supabase.schema('storage')
--      방식의 RPC, service_role PostgREST 직접 쿼리 등) 가 500을 반환할 수 있음.
--
-- 수정: storage 추가하여 4개 스키마 모두 포함.

ALTER ROLE authenticator SET pgrst.db_schemas TO 'public, graphql_public, storage, admin';

-- PostgREST 즉시 리로드 (NOTIFY 채널은 PostgREST 가 listen 중)
NOTIFY pgrst, 'reload config';
