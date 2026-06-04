-- Fix #2993: signed Storage upload guardrails.
BEGIN;
SELECT plan(33);

SET search_path TO public, storage, extensions;
SELECT tests.authenticate_as_service_role();

SELECT set_config('tests.storage_user_id', tests.create_supabase_user('storage_upload_user')::text, true);
SELECT set_config('tests.storage_other_user_id', tests.create_supabase_user('storage_upload_other')::text, true);
SELECT set_config('tests.storage_byte_user_id', tests.create_supabase_user('storage_upload_byte')::text, true);
SELECT set_config('tests.storage_quota_user_id', tests.create_supabase_user('storage_upload_quota')::text, true);
WITH p AS (
  INSERT INTO public.partners (name)
  VALUES ('Storage Upload Test Partner')
  RETURNING id
)
SELECT set_config('tests.storage_partner_id', (SELECT id FROM p)::text, true);

INSERT INTO public.partner_member_permissions (partner_id, user_id, role)
VALUES (
  current_setting('tests.storage_partner_id')::uuid,
  current_setting('tests.storage_user_id')::uuid,
  'owner'
);

SELECT is(
  (SELECT file_size_limit FROM storage.buckets WHERE id = 'party-assets'),
  52428800::bigint,
  '#2993: party-assets has a 50MiB hard bucket limit'
);

SELECT is(
  (SELECT public FROM storage.buckets WHERE id = 'party-assets-pending'),
  false,
  '#2993: party-assets pending uploads use a private staging bucket'
);

SELECT is(
  (
    SELECT upload_bucket_id
    FROM public.storage_upload_bucket_policies
    WHERE bucket_id = 'party-assets'
  ),
  'party-assets-pending',
  '#2993: party-assets policy presigns the private staging bucket'
);

SELECT ok(
  (
    SELECT allowed_mime_types @> ARRAY['application/pdf']::text[]
    FROM storage.buckets
    WHERE id = 'partner-proofs'
  ),
  '#2993: partner-proofs allows PDF documents'
);

SELECT results_eq(
  $$SELECT count(*)::int
      FROM pg_policies
     WHERE schemaname = 'storage'
       AND tablename = 'objects'
       AND cmd = 'INSERT'
       AND policyname IN (
         'Users can upload own verification proofs',
         'Partners can upload party assets',
         'Partners can upload own proofs'
       )$$,
  ARRAY[0],
  '#2993: covered buckets no longer expose direct authenticated INSERT policies'
);

SELECT set_config(
  'tests.storage_advisory_lock_count_before',
  (
    SELECT count(*)::int
    FROM pg_locks
    WHERE locktype = 'advisory'
      AND pid = pg_backend_pid()
      AND granted
  )::text,
  true
);

CREATE TEMP TABLE t_upload AS
SELECT *
FROM public.reserve_storage_upload(
  current_setting('tests.storage_user_id')::uuid,
  'partner-proofs',
  current_setting('tests.storage_user_id') || '/biz_reg.jpg',
  1024,
  'image/jpeg'
);

SELECT ok(
  (SELECT upload_id IS NOT NULL FROM t_upload),
  '#2993: reserve_storage_upload creates an active upload'
);

SELECT is(
  (
    SELECT count(*)::int
    FROM pg_locks
    WHERE locktype = 'advisory'
      AND pid = pg_backend_pid()
      AND granted
  ),
  current_setting('tests.storage_advisory_lock_count_before')::int + 1,
  '#2993: reserve serializes user-scoped quota checks with a transaction advisory lock'
);

SELECT is(
  (
    SELECT count(*)::int
    FROM public.active_storage_uploads
    WHERE id = (SELECT upload_id FROM t_upload)
      AND status = 'pending'
  ),
  1,
  '#2993: reserved upload starts pending'
);

INSERT INTO storage.objects (id, bucket_id, name, owner, owner_id, metadata)
VALUES (
  gen_random_uuid(),
  'partner-proofs',
  (SELECT object_path FROM t_upload),
  NULL,
  NULL,
  '{"size": 1024}'::jsonb
);

SELECT is(
  (
    SELECT owner_id
    FROM public.minglit_files
    WHERE bucket_id = 'partner-proofs'
      AND file_path = (SELECT object_path FROM t_upload)
  ),
  current_setting('tests.storage_user_id')::uuid,
  '#2993: storage object trigger recovers owner from active upload'
);

CREATE TEMP TABLE t_complete AS
SELECT *
FROM public.complete_storage_upload(
  (SELECT upload_id FROM t_upload),
  current_setting('tests.storage_user_id')::uuid
);

SELECT is(
  (SELECT status FROM t_complete),
  'completed',
  '#2993: complete_storage_upload closes a matching upload'
);

SELECT is(
  (SELECT actual_size FROM t_complete),
  1024::bigint,
  '#2993: complete_storage_upload records actual size'
);

CREATE TEMP TABLE t_mismatch_upload AS
SELECT *
FROM public.reserve_storage_upload(
  current_setting('tests.storage_user_id')::uuid,
  'partner-proofs',
  current_setting('tests.storage_user_id') || '/mismatch.jpg',
  1000,
  'image/jpeg'
);

INSERT INTO storage.objects (id, bucket_id, name, owner, owner_id, metadata)
VALUES (
  gen_random_uuid(),
  'partner-proofs',
  (SELECT object_path FROM t_mismatch_upload),
  NULL,
  NULL,
  '{"size": 2000}'::jsonb
);

CREATE TEMP TABLE t_mismatch_complete AS
SELECT *
FROM public.complete_storage_upload(
  (SELECT upload_id FROM t_mismatch_upload),
  current_setting('tests.storage_user_id')::uuid
);

SELECT is(
  (SELECT status FROM t_mismatch_complete),
  'rejected',
  '#2993: complete_storage_upload rejects actual size mismatch'
);

SELECT is(
  (SELECT rejection_reason FROM t_mismatch_complete),
  'actual_size_exceeds_declared_size',
  '#2993: rejected reconcile records reason'
);

SELECT throws_ok(
  format(
    $$SELECT * FROM public.reserve_storage_upload(%L::uuid, 'partner-proofs', %L, 10485761, 'image/jpeg')$$,
    current_setting('tests.storage_user_id'),
    current_setting('tests.storage_user_id') || '/too-large.jpg'
  ),
  'P0001',
  'upload_size_exceeds_bucket_limit',
  '#2993: reserve rejects files above bucket max'
);

SELECT throws_ok(
  format(
    $$SELECT * FROM public.reserve_storage_upload(%L::uuid, 'partner-proofs', %L, 1024, 'application/x-msdownload')$$,
    current_setting('tests.storage_user_id'),
    current_setting('tests.storage_user_id') || '/bad.exe'
  ),
  'P0001',
  'unsupported_upload_mime_type',
  '#2993: reserve rejects unsupported MIME types'
);

SELECT throws_ok(
  format(
    $$SELECT * FROM public.reserve_storage_upload(%L::uuid, 'partner-proofs', %L, 1024, 'image/jpeg')$$,
    current_setting('tests.storage_user_id'),
    current_setting('tests.storage_other_user_id') || '/forged.jpg'
  ),
  'P0001',
  'storage_path_user_prefix_required',
  '#2993: user-owned buckets require the user id path prefix'
);

CREATE TEMP TABLE t_party_upload AS
SELECT *
FROM public.reserve_storage_upload(
  current_setting('tests.storage_user_id')::uuid,
  'party-assets',
  current_setting('tests.storage_partner_id') || '/hero.jpg',
  1024,
  'image/jpeg'
);

SELECT ok(
  (SELECT upload_id IS NOT NULL FROM t_party_upload),
  '#2993: party-assets reserve allows partner members with PARTY_MANAGE'
);

SELECT is(
  (SELECT upload_bucket_id FROM t_party_upload),
  'party-assets-pending',
  '#2993: party-assets reserve returns the private staging bucket'
);

INSERT INTO storage.objects (id, bucket_id, name, owner, owner_id, metadata)
VALUES (
  gen_random_uuid(),
  'party-assets-pending',
  (SELECT upload_object_path FROM t_party_upload),
  NULL,
  NULL,
  '{"size": 1024}'::jsonb
);

CREATE TEMP TABLE t_party_complete AS
SELECT *
FROM public.complete_storage_upload(
  (SELECT upload_id FROM t_party_upload),
  current_setting('tests.storage_user_id')::uuid
);

SELECT is(
  (SELECT status FROM t_party_complete),
  'publishing',
  '#2993: public bucket reconcile validates staging object before publish'
);

SELECT is(
  (
    SELECT count(*)::int
    FROM public.minglit_files
    WHERE bucket_id = 'party-assets-pending'
      AND file_path = (SELECT upload_object_path FROM t_party_upload)
  ),
  0,
  '#2993: private staging objects are not exposed as product files'
);

INSERT INTO storage.objects (id, bucket_id, name, owner, owner_id, metadata)
VALUES (
  gen_random_uuid(),
  'party-assets',
  (SELECT object_path FROM t_party_upload),
  NULL,
  NULL,
  '{"size": 1024}'::jsonb
);

CREATE TEMP TABLE t_party_publish AS
SELECT *
FROM public.publish_storage_upload(
  (SELECT upload_id FROM t_party_upload),
  current_setting('tests.storage_user_id')::uuid
);

SELECT is(
  (SELECT status FROM t_party_publish),
  'completed',
  '#2993: publish_storage_upload completes public assets after final object exists'
);

SELECT is(
  (
    SELECT owner_id
    FROM public.minglit_files
    WHERE bucket_id = 'party-assets'
      AND file_path = (SELECT object_path FROM t_party_upload)
  ),
  current_setting('tests.storage_user_id')::uuid,
  '#2993: published public asset is registered only after publish'
);

SELECT throws_ok(
  format(
    $$SELECT * FROM public.reserve_storage_upload(%L::uuid, 'party-assets', %L, 1024, 'image/jpeg')$$,
    current_setting('tests.storage_other_user_id'),
    current_setting('tests.storage_partner_id') || '/forbidden.jpg'
  ),
  'P0001',
  'storage_upload_partner_permission_required',
  '#2993: party-assets reserve rejects users without partner permission'
);

UPDATE public.active_storage_uploads
SET status = 'aborted'
WHERE user_id = current_setting('tests.storage_other_user_id')::uuid;

SELECT lives_ok(
  format(
    $$SELECT * FROM public.reserve_storage_upload(%L::uuid, 'partner-proofs', %L, 100, 'image/jpeg')$$,
    current_setting('tests.storage_other_user_id'),
    current_setting('tests.storage_other_user_id') || '/concurrency-1.jpg'
  ),
  '#2993: concurrency setup 1'
);
SELECT lives_ok(
  format(
    $$SELECT * FROM public.reserve_storage_upload(%L::uuid, 'partner-proofs', %L, 100, 'image/jpeg')$$,
    current_setting('tests.storage_other_user_id'),
    current_setting('tests.storage_other_user_id') || '/concurrency-2.jpg'
  ),
  '#2993: concurrency setup 2'
);
SELECT lives_ok(
  format(
    $$SELECT * FROM public.reserve_storage_upload(%L::uuid, 'partner-proofs', %L, 100, 'image/jpeg')$$,
    current_setting('tests.storage_other_user_id'),
    current_setting('tests.storage_other_user_id') || '/concurrency-3.jpg'
  ),
  '#2993: concurrency setup 3'
);
SELECT lives_ok(
  format(
    $$SELECT * FROM public.reserve_storage_upload(%L::uuid, 'partner-proofs', %L, 100, 'image/jpeg')$$,
    current_setting('tests.storage_other_user_id'),
    current_setting('tests.storage_other_user_id') || '/concurrency-4.jpg'
  ),
  '#2993: concurrency setup 4'
);
SELECT lives_ok(
  format(
    $$SELECT * FROM public.reserve_storage_upload(%L::uuid, 'partner-proofs', %L, 100, 'image/jpeg')$$,
    current_setting('tests.storage_other_user_id'),
    current_setting('tests.storage_other_user_id') || '/concurrency-5.jpg'
  ),
  '#2993: concurrency setup 5'
);

SELECT throws_ok(
  format(
    $$SELECT * FROM public.reserve_storage_upload(%L::uuid, 'partner-proofs', %L, 100, 'image/jpeg')$$,
    current_setting('tests.storage_other_user_id'),
    current_setting('tests.storage_other_user_id') || '/concurrency-6.jpg'
  ),
  'P0001',
  'storage_upload_concurrency_exceeded',
  '#2993: reserve enforces max concurrent active uploads'
);

UPDATE public.storage_upload_bucket_policies
SET hourly_byte_limit = 150,
    quota_bytes = 10000
WHERE bucket_id = 'verification-proofs';

SELECT lives_ok(
  format(
    $$SELECT * FROM public.reserve_storage_upload(%L::uuid, 'verification-proofs', %L, 100, 'image/jpeg')$$,
    current_setting('tests.storage_byte_user_id'),
    current_setting('tests.storage_byte_user_id') || '/byte-1.jpg'
  ),
  '#2993: byte-rate setup reserve succeeds'
);

SELECT throws_ok(
  format(
    $$SELECT * FROM public.reserve_storage_upload(%L::uuid, 'verification-proofs', %L, 100, 'image/jpeg')$$,
    current_setting('tests.storage_byte_user_id'),
    current_setting('tests.storage_byte_user_id') || '/byte-2.jpg'
  ),
  'P0001',
  'storage_upload_byte_rate_exceeded',
  '#2993: reserve enforces hourly byte-rate'
);

UPDATE public.storage_upload_bucket_policies
SET hourly_byte_limit = 10000,
    quota_bytes = 150
WHERE bucket_id = 'verification-proofs';

SELECT lives_ok(
  format(
    $$SELECT * FROM public.reserve_storage_upload(%L::uuid, 'verification-proofs', %L, 100, 'image/jpeg')$$,
    current_setting('tests.storage_quota_user_id'),
    current_setting('tests.storage_quota_user_id') || '/quota-1.jpg'
  ),
  '#2993: quota setup reserve succeeds'
);

SELECT throws_ok(
  format(
    $$SELECT * FROM public.reserve_storage_upload(%L::uuid, 'verification-proofs', %L, 100, 'image/jpeg')$$,
    current_setting('tests.storage_quota_user_id'),
    current_setting('tests.storage_quota_user_id') || '/quota-2.jpg'
  ),
  'P0001',
  'storage_upload_quota_exceeded',
  '#2993: reserve enforces per-user quota'
);

SELECT * FROM finish();
ROLLBACK;
