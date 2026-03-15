-- Add text/plain to allowed_mime_types for bug-report-attachments bucket
UPDATE storage.buckets
SET allowed_mime_types = array_append(allowed_mime_types, 'text/plain')
WHERE id = 'bug-report-attachments'
  AND NOT ('text/plain' = ANY(allowed_mime_types));
