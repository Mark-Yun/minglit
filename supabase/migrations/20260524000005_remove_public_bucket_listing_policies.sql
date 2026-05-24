-- Fix #2753: public buckets can serve known object URLs without exposing
-- storage.objects listing through broad SELECT policies.

DROP POLICY IF EXISTS "Public read for bug report attachments"
  ON storage.objects;

DROP POLICY IF EXISTS "Public can view party assets"
  ON storage.objects;

UPDATE storage.buckets
SET public = true
WHERE id IN ('bug-report-attachments', 'party-assets');
