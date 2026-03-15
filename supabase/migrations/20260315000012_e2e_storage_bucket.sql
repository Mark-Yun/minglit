-- Create e2e-test-logs storage bucket for E2E test log uploads
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'e2e-test-logs',
  'e2e-test-logs',
  true,
  NULL,  -- No file size limit
  NULL   -- No mime type restrictions
)
ON CONFLICT (id) DO NOTHING;

-- RLS: public read
CREATE POLICY "Public read for e2e test logs"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'e2e-test-logs');
