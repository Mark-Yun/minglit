-- Fix #1675: bug-report-attachments 버킷 RLS 정책 재설정
-- 증상: 인증된 사용자가 스토리지 업로드 시 403 (new row violates row-level security policy)
-- 원인: dev 인스턴스에서 INSERT 정책이 누락됐거나 비활성화됐을 가능성

-- 버킷이 없으면 생성 (dev 인스턴스 리셋 후에도 안전하도록)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'bug-report-attachments',
  'bug-report-attachments',
  true,
  5242880,
  ARRAY['image/png', 'image/jpeg', 'image/webp', 'text/plain']
)
ON CONFLICT (id) DO UPDATE
  SET allowed_mime_types = ARRAY['image/png', 'image/jpeg', 'image/webp', 'text/plain'];

-- 기존 정책 제거 후 재생성 (멱등성 보장)
DROP POLICY IF EXISTS "Authenticated users can upload bug report attachments"
  ON storage.objects;

DROP POLICY IF EXISTS "Public read for bug report attachments"
  ON storage.objects;

-- Fix #1675: authenticated 사용자 업로드 허용
CREATE POLICY "Authenticated users can upload bug report attachments"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'bug-report-attachments');

-- 공개 읽기 허용 (버그 리포트 이미지/덤프 링크 접근용)
CREATE POLICY "Public read for bug report attachments"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'bug-report-attachments');
