-- Create bug-report-attachments storage bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'bug-report-attachments',
  'bug-report-attachments',
  true,
  5242880,  -- 5MB
  ARRAY['image/png', 'image/jpeg', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- RLS: authenticated users can upload
CREATE POLICY "Authenticated users can upload bug report attachments"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'bug-report-attachments');

-- RLS: public read
CREATE POLICY "Public read for bug report attachments"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'bug-report-attachments');

-- Auto-delete after 30 days via cron
SELECT cron.schedule(
  'delete-old-bug-report-attachments',
  '0 3 * * *',
  $$
  DELETE FROM storage.objects
  WHERE bucket_id = 'bug-report-attachments'
    AND created_at < NOW() - INTERVAL '30 days';
  $$
);
