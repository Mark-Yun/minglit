-- Fix #2204: storage_bucket retention cleanup 가 sub-directory 안 들여다 봐서 0 deleted.
--
-- 원인: cleanup-retention/index.ts 의 runStorageBucketCleanup 가 supabase.storage.from(b).list("")
--      만 호출 → bucket 루트만 listing. 실제 파일은 sub-directory (screenshots/, layout-dumps/) 안.
--      결과: bug-report-attachments bucket 에 57일 된 파일 있는데 0 deleted.
--
-- 수정: admin.find_stale_storage_objects() 함수 추가. storage.objects 테이블 직접 query (재귀 무관 — 모든
--      파일이 한 row 로 평면화돼있음). created_at 기준 stale 파일 list 반환.
--      EF 가 이 list 를 받아 supabase.storage.from(b).remove(names) 로 일괄 삭제.
--
-- Security: SECURITY DEFINER + REVOKE FROM PUBLIC + GRANT TO service_role — service_role 만 호출 가능.

CREATE OR REPLACE FUNCTION admin.find_stale_storage_objects(
  p_bucket_id    text,
  p_path_prefix  text,
  p_cutoff_days  int,
  p_limit        int DEFAULT 10000
)
RETURNS TABLE (name text)
LANGUAGE sql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
  SELECT o.name
  FROM storage.objects o
  WHERE o.bucket_id = p_bucket_id
    AND o.created_at < now() - p_cutoff_days * interval '1 day'
    AND (p_path_prefix = '' OR o.name LIKE p_path_prefix || '/%')
  ORDER BY o.created_at ASC
  LIMIT p_limit;
$$;

REVOKE ALL ON FUNCTION admin.find_stale_storage_objects(text, text, int, int) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION admin.find_stale_storage_objects(text, text, int, int) TO service_role;

COMMENT ON FUNCTION admin.find_stale_storage_objects(text, text, int, int) IS
  'Fix #2204: cleanup-retention storage_bucket 정책에서 사용. storage.objects 직접 query 로 sub-directory 포함 모든 stale 파일 반환. SECURITY DEFINER 라 RLS 우회 (service_role 전용).';
