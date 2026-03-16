-- Make e2e-test-logs bucket private with access restrictions
-- Fixes: bucket was public=true exposing internal simulation logs externally

UPDATE storage.buckets
SET
  public = false,
  allowed_mime_types = ARRAY['text/plain', 'application/json'],
  file_size_limit = 10485760
WHERE id = 'e2e-test-logs';

DROP POLICY IF EXISTS "Public read for e2e test logs" ON storage.objects;

CREATE POLICY "Service role write for e2e test logs"
  ON storage.objects
  FOR INSERT
  TO service_role
  WITH CHECK (bucket_id = 'e2e-test-logs');
