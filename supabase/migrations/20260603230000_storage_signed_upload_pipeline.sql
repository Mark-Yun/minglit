-- Fix #2993: signed Storage upload pipeline with quota/rate/concurrency guardrails.

-- Covered product buckets get hard Storage-level size/MIME limits. The global
-- local limit remains 50MiB; per-bucket limits below are the product contract.
UPDATE storage.buckets
SET
  public = false,
  file_size_limit = 10485760,
  allowed_mime_types = ARRAY[
    'image/jpeg',
    'image/png',
    'image/webp',
    'application/pdf'
  ]
WHERE id IN ('verification-proofs', 'partner-proofs');

UPDATE storage.buckets
SET
  public = true,
  file_size_limit = 52428800,
  allowed_mime_types = ARRAY[
    'image/jpeg',
    'image/png',
    'image/webp'
  ]
WHERE id = 'party-assets';

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'party-assets-pending',
  'party-assets-pending',
  false,
  52428800,
  ARRAY[
    'image/jpeg',
    'image/png',
    'image/webp'
  ]
)
ON CONFLICT (id) DO UPDATE
SET
  public = false,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

CREATE TABLE IF NOT EXISTS public.storage_upload_bucket_policies (
  bucket_id text PRIMARY KEY REFERENCES storage.buckets(id) ON DELETE CASCADE,
  upload_bucket_id text NOT NULL REFERENCES storage.buckets(id) ON DELETE CASCADE,
  public_bucket boolean NOT NULL DEFAULT false,
  max_file_size_bytes bigint NOT NULL CHECK (max_file_size_bytes > 0),
  allowed_mime_types text[] NOT NULL CHECK (array_length(allowed_mime_types, 1) > 0),
  path_owner_mode text NOT NULL CHECK (path_owner_mode IN ('user', 'partner')),
  hourly_byte_limit bigint NOT NULL CHECK (hourly_byte_limit > 0),
  quota_bytes bigint NOT NULL CHECK (quota_bytes > 0),
  max_concurrent_uploads integer NOT NULL CHECK (max_concurrent_uploads > 0),
  upload_ttl interval NOT NULL DEFAULT interval '2 hours',
  is_enabled boolean NOT NULL DEFAULT true,
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (public_bucket = false OR upload_bucket_id <> bucket_id)
);

ALTER TABLE public.storage_upload_bucket_policies ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.storage_upload_bucket_policies FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.storage_upload_bucket_policies TO service_role;

INSERT INTO public.storage_upload_bucket_policies (
  bucket_id,
  upload_bucket_id,
  public_bucket,
  max_file_size_bytes,
  allowed_mime_types,
  path_owner_mode,
  hourly_byte_limit,
  quota_bytes,
  max_concurrent_uploads
)
VALUES
  (
    'verification-proofs',
    'verification-proofs',
    false,
    10485760,
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf'],
    'user',
    524288000,
    5368709120,
    5
  ),
  (
    'partner-proofs',
    'partner-proofs',
    false,
    10485760,
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf'],
    'user',
    524288000,
    5368709120,
    5
  ),
  (
    'party-assets',
    'party-assets-pending',
    true,
    52428800,
    ARRAY['image/jpeg', 'image/png', 'image/webp'],
    'partner',
    524288000,
    5368709120,
    5
  )
ON CONFLICT (bucket_id) DO UPDATE
SET
  upload_bucket_id = EXCLUDED.upload_bucket_id,
  public_bucket = EXCLUDED.public_bucket,
  max_file_size_bytes = EXCLUDED.max_file_size_bytes,
  allowed_mime_types = EXCLUDED.allowed_mime_types,
  path_owner_mode = EXCLUDED.path_owner_mode,
  hourly_byte_limit = EXCLUDED.hourly_byte_limit,
  quota_bytes = EXCLUDED.quota_bytes,
  max_concurrent_uploads = EXCLUDED.max_concurrent_uploads,
  is_enabled = true,
  updated_at = now();

CREATE TABLE IF NOT EXISTS public.active_storage_uploads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  bucket_id text NOT NULL REFERENCES storage.buckets(id) ON DELETE CASCADE,
  object_path text NOT NULL,
  upload_bucket_id text NOT NULL REFERENCES storage.buckets(id) ON DELETE CASCADE,
  upload_object_path text NOT NULL,
  declared_size bigint NOT NULL CHECK (declared_size > 0),
  mime_type text NOT NULL,
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'publishing', 'completed', 'aborted', 'rejected', 'expired')),
  actual_size bigint CHECK (actual_size IS NULL OR actual_size >= 0),
  rejection_reason text,
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL DEFAULT (now() + interval '2 hours'),
  completed_at timestamptz,
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (bucket_id, object_path),
  UNIQUE (upload_bucket_id, upload_object_path)
);

ALTER TABLE public.active_storage_uploads ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.active_storage_uploads FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.active_storage_uploads TO service_role;

CREATE INDEX IF NOT EXISTS idx_active_storage_uploads_user_status
  ON public.active_storage_uploads(user_id, status, created_at);

CREATE INDEX IF NOT EXISTS idx_active_storage_uploads_pending_expiry
  ON public.active_storage_uploads(expires_at)
  WHERE status IN ('pending', 'publishing');

CREATE OR REPLACE FUNCTION public.storage_object_metadata_size(p_metadata jsonb)
RETURNS bigint
LANGUAGE sql
IMMUTABLE
SET search_path = public, storage, extensions
AS $$
  SELECT CASE
    WHEN p_metadata ? 'size' AND (p_metadata->>'size') ~ '^[0-9]+$'
      THEN (p_metadata->>'size')::bigint
    WHEN p_metadata ? 'contentLength' AND (p_metadata->>'contentLength') ~ '^[0-9]+$'
      THEN (p_metadata->>'contentLength')::bigint
    WHEN p_metadata ? 'content-length' AND (p_metadata->>'content-length') ~ '^[0-9]+$'
      THEN (p_metadata->>'content-length')::bigint
    ELSE 0
  END;
$$;

CREATE OR REPLACE FUNCTION public.cleanup_stale_storage_uploads(p_now timestamptz DEFAULT now())
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, storage, auth, extensions
AS $$
DECLARE
  v_count integer;
BEGIN
  WITH expired AS (
    UPDATE public.active_storage_uploads
    SET
      status = 'expired',
      updated_at = p_now,
      rejection_reason = 'upload_token_expired'
    WHERE status IN ('pending', 'publishing')
      AND expires_at < p_now
    RETURNING 1
  )
  SELECT count(*)::integer INTO v_count FROM expired;

  RETURN v_count;
END;
$$;

CREATE OR REPLACE FUNCTION public.reserve_storage_upload(
  p_user_id uuid,
  p_bucket_id text,
  p_object_path text,
  p_declared_size bigint,
  p_mime_type text
)
RETURNS TABLE (
  upload_id uuid,
  bucket_id text,
  object_path text,
  upload_bucket_id text,
  upload_object_path text,
  max_file_size_bytes bigint,
  public_bucket boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, storage, auth, extensions
AS $$
DECLARE
  v_policy public.storage_upload_bucket_policies%ROWTYPE;
  v_first_segment text;
  v_partner_id uuid;
  v_pending_count integer;
  v_recent_bytes bigint;
  v_current_bytes bigint;
  v_pending_bytes bigint;
  v_upload_id uuid;
BEGIN
  PERFORM public.cleanup_stale_storage_uploads();

  SELECT *
  INTO v_policy
  FROM public.storage_upload_bucket_policies
  WHERE storage_upload_bucket_policies.bucket_id = p_bucket_id
    AND is_enabled = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'unsupported_storage_bucket';
  END IF;

  IF p_declared_size <= 0 THEN
    RAISE EXCEPTION 'invalid_declared_size';
  END IF;

  IF p_declared_size > v_policy.max_file_size_bytes THEN
    RAISE EXCEPTION 'upload_size_exceeds_bucket_limit';
  END IF;

  IF NOT (p_mime_type = ANY(v_policy.allowed_mime_types)) THEN
    RAISE EXCEPTION 'unsupported_upload_mime_type';
  END IF;

  IF p_object_path IS NULL
    OR length(p_object_path) < 3
    OR length(p_object_path) > 512
    OR p_object_path LIKE '/%'
    OR p_object_path LIKE '%//%'
    OR p_object_path LIKE '%..%'
  THEN
    RAISE EXCEPTION 'invalid_storage_path';
  END IF;

  v_first_segment := split_part(p_object_path, '/', 1);

  IF v_policy.path_owner_mode = 'user' THEN
    IF v_first_segment <> p_user_id::text THEN
      RAISE EXCEPTION 'storage_path_user_prefix_required';
    END IF;
  ELSIF v_policy.path_owner_mode = 'partner' THEN
    BEGIN
      v_partner_id := v_first_segment::uuid;
    EXCEPTION WHEN invalid_text_representation THEN
      RAISE EXCEPTION 'storage_path_partner_prefix_required';
    END;

    IF NOT EXISTS (
      SELECT 1
      FROM public.partner_member_permissions pmp
      WHERE pmp.partner_id = v_partner_id
        AND pmp.user_id = p_user_id
        AND 'PARTY_MANAGE' = ANY(pmp.permissions)
    ) THEN
      RAISE EXCEPTION 'storage_upload_partner_permission_required';
    END IF;
  END IF;

  SELECT count(*)::integer
  INTO v_pending_count
  FROM public.active_storage_uploads
  WHERE user_id = p_user_id
    AND status IN ('pending', 'publishing')
    AND expires_at > now();

  IF v_pending_count >= v_policy.max_concurrent_uploads THEN
    RAISE EXCEPTION 'storage_upload_concurrency_exceeded';
  END IF;

  SELECT COALESCE(sum(declared_size), 0)
  INTO v_recent_bytes
  FROM public.active_storage_uploads
  WHERE user_id = p_user_id
    AND status <> 'rejected'
    AND created_at >= now() - interval '1 hour';

  IF v_recent_bytes + p_declared_size > v_policy.hourly_byte_limit THEN
    RAISE EXCEPTION 'storage_upload_byte_rate_exceeded';
  END IF;

  SELECT COALESCE(sum(public.storage_object_metadata_size(o.metadata)), 0)
  INTO v_current_bytes
  FROM public.minglit_files f
  JOIN storage.objects o ON o.id = f.storage_object_id
  JOIN public.storage_upload_bucket_policies p ON p.bucket_id = o.bucket_id
  WHERE f.owner_id = p_user_id
    AND p.is_enabled = true;

  SELECT COALESCE(sum(declared_size), 0)
  INTO v_pending_bytes
  FROM public.active_storage_uploads
  WHERE user_id = p_user_id
    AND status IN ('pending', 'publishing')
    AND expires_at > now();

  IF v_current_bytes + v_pending_bytes + p_declared_size > v_policy.quota_bytes THEN
    RAISE EXCEPTION 'storage_upload_quota_exceeded';
  END IF;

  INSERT INTO public.active_storage_uploads (
    user_id,
    bucket_id,
    object_path,
    upload_bucket_id,
    upload_object_path,
    declared_size,
    mime_type,
    expires_at
  )
  VALUES (
    p_user_id,
    p_bucket_id,
    p_object_path,
    v_policy.upload_bucket_id,
    p_object_path,
    p_declared_size,
    p_mime_type,
    now() + v_policy.upload_ttl
  )
  RETURNING id INTO v_upload_id;

  RETURN QUERY SELECT
    v_upload_id,
    p_bucket_id,
    p_object_path,
    v_policy.upload_bucket_id,
    p_object_path,
    v_policy.max_file_size_bytes,
    v_policy.public_bucket;
END;
$$;

CREATE OR REPLACE FUNCTION public.complete_storage_upload(
  p_upload_id uuid,
  p_user_id uuid
)
RETURNS TABLE (
  upload_id uuid,
  bucket_id text,
  object_path text,
  upload_bucket_id text,
  upload_object_path text,
  status text,
  actual_size bigint,
  rejection_reason text,
  mime_type text,
  public_bucket boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, storage, auth, extensions
AS $$
DECLARE
  v_upload public.active_storage_uploads%ROWTYPE;
  v_policy public.storage_upload_bucket_policies%ROWTYPE;
  v_object record;
  v_actual_size bigint;
  v_allowed_size bigint;
BEGIN
  SELECT *
  INTO v_upload
  FROM public.active_storage_uploads
  WHERE id = p_upload_id
    AND user_id = p_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'active_upload_not_found';
  END IF;

  SELECT *
  INTO v_policy
  FROM public.storage_upload_bucket_policies
  WHERE storage_upload_bucket_policies.bucket_id = v_upload.bucket_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'storage_upload_policy_missing';
  END IF;

  IF v_upload.status <> 'pending' THEN
    RETURN QUERY SELECT
      v_upload.id,
      v_upload.bucket_id,
      v_upload.object_path,
      v_upload.upload_bucket_id,
      v_upload.upload_object_path,
      v_upload.status,
      v_upload.actual_size,
      v_upload.rejection_reason,
      v_upload.mime_type,
      v_policy.public_bucket;
    RETURN;
  END IF;

  SELECT *
  INTO v_object
  FROM storage.objects
  WHERE storage.objects.bucket_id = v_upload.upload_bucket_id
    AND storage.objects.name = v_upload.upload_object_path;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'storage_object_not_found';
  END IF;

  v_actual_size := public.storage_object_metadata_size(v_object.metadata);
  IF v_actual_size = 0 THEN
    v_actual_size := v_upload.declared_size;
  END IF;

  v_allowed_size := LEAST(
    v_policy.max_file_size_bytes,
    ((v_upload.declared_size * 105) + 99) / 100
  );

  IF v_actual_size > v_allowed_size THEN
    UPDATE public.active_storage_uploads
    SET
      status = 'rejected',
      actual_size = v_actual_size,
      rejection_reason = 'actual_size_exceeds_declared_size',
      completed_at = now(),
      updated_at = now()
    WHERE id = v_upload.id
    RETURNING * INTO v_upload;

    RETURN QUERY SELECT
      v_upload.id,
      v_upload.bucket_id,
      v_upload.object_path,
      v_upload.upload_bucket_id,
      v_upload.upload_object_path,
      v_upload.status,
      v_upload.actual_size,
      v_upload.rejection_reason,
      v_upload.mime_type,
      v_policy.public_bucket;
    RETURN;
  END IF;

  IF v_policy.public_bucket THEN
    UPDATE public.active_storage_uploads
    SET
      status = 'publishing',
      actual_size = v_actual_size,
      updated_at = now()
    WHERE id = v_upload.id
    RETURNING * INTO v_upload;

    RETURN QUERY SELECT
      v_upload.id,
      v_upload.bucket_id,
      v_upload.object_path,
      v_upload.upload_bucket_id,
      v_upload.upload_object_path,
      v_upload.status,
      v_upload.actual_size,
      v_upload.rejection_reason,
      v_upload.mime_type,
      v_policy.public_bucket;
    RETURN;
  END IF;

  UPDATE public.active_storage_uploads
  SET
    status = 'completed',
    actual_size = v_actual_size,
    completed_at = now(),
    updated_at = now()
  WHERE id = v_upload.id
  RETURNING * INTO v_upload;

  UPDATE public.minglit_files
  SET owner_id = p_user_id
  WHERE public.minglit_files.bucket_id = v_upload.bucket_id
    AND public.minglit_files.file_path = v_upload.object_path;

  RETURN QUERY SELECT
    v_upload.id,
    v_upload.bucket_id,
    v_upload.object_path,
    v_upload.upload_bucket_id,
    v_upload.upload_object_path,
    v_upload.status,
    v_upload.actual_size,
    v_upload.rejection_reason,
    v_upload.mime_type,
    v_policy.public_bucket;
END;
$$;

CREATE OR REPLACE FUNCTION public.publish_storage_upload(
  p_upload_id uuid,
  p_user_id uuid
)
RETURNS TABLE (
  upload_id uuid,
  bucket_id text,
  object_path text,
  upload_bucket_id text,
  upload_object_path text,
  status text,
  actual_size bigint,
  rejection_reason text,
  mime_type text,
  public_bucket boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, storage, auth, extensions
AS $$
DECLARE
  v_upload public.active_storage_uploads%ROWTYPE;
  v_policy public.storage_upload_bucket_policies%ROWTYPE;
  v_object storage.objects%ROWTYPE;
BEGIN
  SELECT *
  INTO v_upload
  FROM public.active_storage_uploads
  WHERE id = p_upload_id
    AND user_id = p_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'active_upload_not_found';
  END IF;

  SELECT *
  INTO v_policy
  FROM public.storage_upload_bucket_policies
  WHERE storage_upload_bucket_policies.bucket_id = v_upload.bucket_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'storage_upload_policy_missing';
  END IF;

  IF NOT v_policy.public_bucket THEN
    RAISE EXCEPTION 'storage_upload_publish_not_required';
  END IF;

  IF v_upload.status = 'completed' THEN
    RETURN QUERY SELECT
      v_upload.id,
      v_upload.bucket_id,
      v_upload.object_path,
      v_upload.upload_bucket_id,
      v_upload.upload_object_path,
      v_upload.status,
      v_upload.actual_size,
      v_upload.rejection_reason,
      v_upload.mime_type,
      v_policy.public_bucket;
    RETURN;
  END IF;

  IF v_upload.status <> 'publishing' THEN
    RAISE EXCEPTION 'storage_upload_not_ready_to_publish';
  END IF;

  SELECT *
  INTO v_object
  FROM storage.objects
  WHERE storage.objects.bucket_id = v_upload.bucket_id
    AND storage.objects.name = v_upload.object_path;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'storage_published_object_not_found';
  END IF;

  UPDATE public.minglit_files
  SET owner_id = p_user_id
  WHERE storage_object_id = v_object.id;

  IF NOT FOUND THEN
    INSERT INTO public.minglit_files (
      storage_object_id,
      bucket_id,
      file_path,
      owner_id
    )
    VALUES (
      v_object.id,
      v_upload.bucket_id,
      v_upload.object_path,
      p_user_id
    );
  END IF;

  UPDATE public.active_storage_uploads
  SET
    status = 'completed',
    completed_at = now(),
    updated_at = now()
  WHERE id = v_upload.id
  RETURNING * INTO v_upload;

  RETURN QUERY SELECT
    v_upload.id,
    v_upload.bucket_id,
    v_upload.object_path,
    v_upload.upload_bucket_id,
    v_upload.upload_object_path,
    v_upload.status,
    v_upload.actual_size,
    v_upload.rejection_reason,
    v_upload.mime_type,
    v_policy.public_bucket;
END;
$$;

CREATE OR REPLACE FUNCTION public.abort_storage_upload(
  p_upload_id uuid,
  p_user_id uuid
)
RETURNS TABLE (
  upload_id uuid,
  bucket_id text,
  object_path text,
  status text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, storage, auth, extensions
AS $$
DECLARE
  v_upload public.active_storage_uploads%ROWTYPE;
BEGIN
  UPDATE public.active_storage_uploads
  SET
    status = 'aborted',
    rejection_reason = 'client_aborted',
    updated_at = now()
  WHERE id = p_upload_id
    AND user_id = p_user_id
    AND status = 'pending'
  RETURNING * INTO v_upload;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'active_upload_not_found_or_not_pending';
  END IF;

  RETURN QUERY SELECT
    v_upload.id,
    v_upload.bucket_id,
    v_upload.object_path,
    v_upload.status;
END;
$$;

-- Signed upload tokens now gate covered product uploads. Remove broad
-- authenticated INSERT policies so clients cannot bypass the presign EF.
DROP POLICY IF EXISTS "Users can upload own verification proofs" ON storage.objects;
DROP POLICY IF EXISTS "Partners can upload party assets" ON storage.objects;
DROP POLICY IF EXISTS "Partners can upload own proofs" ON storage.objects;

-- Existing trigger assumed storage.objects.owner is present. Signed upload
-- token requests may not carry the end-user JWT, so recover owner_id from the
-- active upload reservation when available.
CREATE OR REPLACE FUNCTION public.handle_storage_object_created()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_owner_id uuid;
BEGIN
  v_owner_id := new.owner;

  IF v_owner_id IS NULL THEN
    SELECT user_id
    INTO v_owner_id
    FROM public.active_storage_uploads
    WHERE upload_bucket_id = new.bucket_id
      AND upload_object_path = new.name
      AND active_storage_uploads.bucket_id = new.bucket_id
      AND active_storage_uploads.object_path = new.name
      AND status = 'pending'
    ORDER BY created_at DESC
    LIMIT 1;
  END IF;

  IF v_owner_id IS NOT NULL THEN
    INSERT INTO public.minglit_files (storage_object_id, bucket_id, file_path, owner_id)
    VALUES (new.id, new.bucket_id, new.name, v_owner_id);
  END IF;

  RETURN new;
END;
$$;

REVOKE ALL ON FUNCTION public.storage_object_metadata_size(jsonb) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.cleanup_stale_storage_uploads(timestamptz) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.reserve_storage_upload(uuid, text, text, bigint, text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.complete_storage_upload(uuid, uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.publish_storage_upload(uuid, uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.abort_storage_upload(uuid, uuid) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.storage_object_metadata_size(jsonb) TO service_role;
GRANT EXECUTE ON FUNCTION public.cleanup_stale_storage_uploads(timestamptz) TO service_role;
GRANT EXECUTE ON FUNCTION public.reserve_storage_upload(uuid, text, text, bigint, text) TO service_role;
GRANT EXECUTE ON FUNCTION public.complete_storage_upload(uuid, uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.publish_storage_upload(uuid, uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.abort_storage_upload(uuid, uuid) TO service_role;

COMMENT ON TABLE public.active_storage_uploads IS
  'Fix #2993: EF-issued signed Storage upload reservations. Tracks declared size, concurrency, quota, and reconcile state.';
COMMENT ON FUNCTION public.reserve_storage_upload(uuid, text, text, bigint, text) IS
  'Fix #2993: service_role-only presign guard for Storage uploads. Enforces bucket policy, user/partner path scope, byte-rate, quota, and concurrency.';
COMMENT ON FUNCTION public.complete_storage_upload(uuid, uuid) IS
  'Fix #2993: service_role-only post-upload reconcile. Closes active upload and rejects declared/actual size mismatches.';
COMMENT ON FUNCTION public.publish_storage_upload(uuid, uuid) IS
  'Fix #2993: service_role-only public bucket publish step after private staging upload is reconciled.';
