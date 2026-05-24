-- Fix #2753: public buckets keep known-object URL access without broad listing.
BEGIN;
SELECT plan(5);

SET search_path TO storage, public, extensions;

SELECT is(
  (SELECT public FROM storage.buckets WHERE id = 'bug-report-attachments'),
  true,
  '#2753: bug-report-attachments remains a public bucket for known object URLs'
);

SELECT is(
  (SELECT public FROM storage.buckets WHERE id = 'party-assets'),
  true,
  '#2753: party-assets remains a public bucket for known object URLs'
);

SELECT results_eq(
  $$SELECT count(*)::int
      FROM pg_policies
     WHERE schemaname = 'storage'
       AND tablename = 'objects'
       AND cmd = 'SELECT'
       AND policyname IN (
         'Public read for bug report attachments',
         'Public can view party assets'
       )$$,
  ARRAY[0],
  '#2753: named broad public SELECT policies are removed'
);

SELECT results_eq(
  $$SELECT count(*)::int
      FROM pg_policies
     WHERE schemaname = 'storage'
       AND tablename = 'objects'
       AND cmd = 'SELECT'
       AND EXISTS (
         SELECT 1
         FROM unnest(roles) AS role_name
         WHERE role_name::text IN ('public', 'anon', 'authenticated')
       )
       AND qual LIKE '%bug-report-attachments%'$$,
  ARRAY[0],
  '#2753: clients cannot list bug-report-attachments through storage.objects SELECT'
);

SELECT results_eq(
  $$SELECT count(*)::int
      FROM pg_policies
     WHERE schemaname = 'storage'
       AND tablename = 'objects'
       AND cmd = 'SELECT'
       AND EXISTS (
         SELECT 1
         FROM unnest(roles) AS role_name
         WHERE role_name::text IN ('public', 'anon', 'authenticated')
       )
       AND qual LIKE '%party-assets%'$$,
  ARRAY[0],
  '#2753: clients cannot list party-assets through storage.objects SELECT'
);

SELECT * FROM finish();
ROLLBACK;
