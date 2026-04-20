-- Fix #1675: bug-report-attachments 스토리지 RLS 정책 검증
BEGIN;
SELECT plan(5);

SET search_path TO storage, public, extensions;

-- 버킷 존재 확인
SELECT ok(
  EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'bug-report-attachments'),
  'bug-report-attachments 버킷이 존재해야 함'
);

-- INSERT 정책 존재 확인
SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'Authenticated users can upload bug report attachments'
      AND cmd = 'INSERT'
  ),
  'authenticated INSERT 정책이 storage.objects에 존재해야 함'
);

-- SELECT 정책 존재 확인
SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'Public read for bug report attachments'
      AND cmd = 'SELECT'
  ),
  'public SELECT 정책이 storage.objects에 존재해야 함'
);

-- anon 사용자는 bug-report-attachments에 INSERT 불가 (RLS 42501 exception 발생)
SELECT tests.clear_authentication();
SELECT throws_ok(
  $$INSERT INTO storage.objects (id, bucket_id, name, owner, owner_id)
    VALUES (gen_random_uuid(), 'bug-report-attachments', 'screenshots/anon-test.png', NULL, NULL)$$,
  '42501',
  'new row violates row-level security policy for table "objects"',
  'anon 사용자는 bug-report-attachments에 업로드할 수 없음'
);

-- authenticated 사용자는 bug-report-attachments에 INSERT 가능
-- owner: handle_storage_object_created trigger가 new.owner → minglit_files.owner_id에 씀
SELECT tests.create_supabase_user('qa_bug_report_tester');
SELECT tests.authenticate_as('qa_bug_report_tester');
SELECT lives_ok(
  $$INSERT INTO storage.objects (id, bucket_id, name, owner, owner_id)
    VALUES (
      gen_random_uuid(),
      'bug-report-attachments',
      'screenshots/auth-test.png',
      tests.get_supabase_uid('qa_bug_report_tester'),
      tests.get_supabase_uid('qa_bug_report_tester')
    )$$,
  'authenticated 사용자는 bug-report-attachments에 업로드 가능'
);

SELECT * FROM finish();
ROLLBACK;
