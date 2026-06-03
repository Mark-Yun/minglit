-- Issue #2992: shared Edge Function runtime guardrails.
-- Count rate limit uses token-bucket semantics. Idempotency stores JSON
-- responses for duplicate replay within a bounded TTL.

CREATE TABLE IF NOT EXISTS public.edge_rate_limit_buckets (
  key text PRIMARY KEY,
  tokens numeric NOT NULL,
  capacity numeric NOT NULL,
  refill_per_second numeric NOT NULL,
  last_refill_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT edge_rate_limit_buckets_capacity_positive CHECK (capacity > 0),
  CONSTRAINT edge_rate_limit_buckets_refill_positive CHECK (refill_per_second > 0),
  CONSTRAINT edge_rate_limit_buckets_tokens_non_negative CHECK (tokens >= 0)
);

ALTER TABLE public.edge_rate_limit_buckets ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS edge_rate_limit_buckets_service_role_only
  ON public.edge_rate_limit_buckets;
CREATE POLICY edge_rate_limit_buckets_service_role_only
  ON public.edge_rate_limit_buckets
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

REVOKE ALL ON public.edge_rate_limit_buckets FROM PUBLIC;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.edge_rate_limit_buckets TO service_role;

CREATE TABLE IF NOT EXISTS public.edge_idempotency_keys (
  scope text NOT NULL,
  requester_key text NOT NULL,
  idempotency_key text NOT NULL,
  request_hash text NOT NULL,
  status text NOT NULL,
  response_status integer,
  response_body jsonb,
  locked_until timestamptz NOT NULL,
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT edge_idempotency_keys_pkey
    PRIMARY KEY (scope, requester_key, idempotency_key),
  CONSTRAINT edge_idempotency_keys_status_check
    CHECK (status IN ('in_progress', 'completed', 'failed')),
  CONSTRAINT edge_idempotency_keys_completed_response_check
    CHECK (
      status <> 'completed'
      OR (response_status BETWEEN 100 AND 599 AND response_body IS NOT NULL)
    )
);

CREATE INDEX IF NOT EXISTS edge_idempotency_keys_expires_at_idx
  ON public.edge_idempotency_keys (expires_at);

ALTER TABLE public.edge_idempotency_keys ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS edge_idempotency_keys_service_role_only
  ON public.edge_idempotency_keys;
CREATE POLICY edge_idempotency_keys_service_role_only
  ON public.edge_idempotency_keys
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

REVOKE ALL ON public.edge_idempotency_keys FROM PUBLIC;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.edge_idempotency_keys TO service_role;

CREATE OR REPLACE FUNCTION public.consume_edge_rate_limit(
  p_key text,
  p_capacity numeric,
  p_refill_per_second numeric,
  p_cost numeric DEFAULT 1,
  p_now timestamptz DEFAULT now()
)
RETURNS TABLE (
  allowed boolean,
  remaining numeric,
  retry_after_seconds integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_tokens numeric;
  v_last_refill_at timestamptz;
  v_elapsed_seconds numeric;
  v_retry_after numeric;
BEGIN
  IF p_key IS NULL OR btrim(p_key) = '' THEN
    RAISE EXCEPTION 'rate limit key is required';
  END IF;
  IF p_capacity <= 0 THEN
    RAISE EXCEPTION 'rate limit capacity must be positive';
  END IF;
  IF p_refill_per_second <= 0 THEN
    RAISE EXCEPTION 'rate limit refill_per_second must be positive';
  END IF;
  IF p_cost <= 0 OR p_cost > p_capacity THEN
    RAISE EXCEPTION 'rate limit cost must be positive and <= capacity';
  END IF;

  PERFORM pg_advisory_xact_lock(hashtextextended(p_key, 0));

  SELECT b.tokens, b.last_refill_at
    INTO v_tokens, v_last_refill_at
  FROM public.edge_rate_limit_buckets b
  WHERE b.key = p_key
  FOR UPDATE;

  IF NOT FOUND THEN
    v_tokens := p_capacity;
    v_last_refill_at := p_now;
    INSERT INTO public.edge_rate_limit_buckets (
      key,
      tokens,
      capacity,
      refill_per_second,
      last_refill_at,
      updated_at
    )
    VALUES (
      p_key,
      v_tokens,
      p_capacity,
      p_refill_per_second,
      p_now,
      p_now
    );
  ELSE
    v_elapsed_seconds := greatest(
      0,
      extract(epoch FROM (p_now - v_last_refill_at))
    );
    v_tokens := least(
      p_capacity,
      v_tokens + (v_elapsed_seconds * p_refill_per_second)
    );
  END IF;

  IF v_tokens >= p_cost THEN
    v_tokens := v_tokens - p_cost;
    UPDATE public.edge_rate_limit_buckets
    SET tokens = v_tokens,
        capacity = p_capacity,
        refill_per_second = p_refill_per_second,
        last_refill_at = p_now,
        updated_at = p_now
    WHERE key = p_key;

    RETURN QUERY SELECT true, v_tokens, 0;
    RETURN;
  END IF;

  v_retry_after := ceil((p_cost - v_tokens) / p_refill_per_second);
  UPDATE public.edge_rate_limit_buckets
  SET tokens = v_tokens,
      capacity = p_capacity,
      refill_per_second = p_refill_per_second,
      last_refill_at = p_now,
      updated_at = p_now
  WHERE key = p_key;

  RETURN QUERY SELECT false, v_tokens, greatest(1, v_retry_after::integer);
END;
$$;

CREATE OR REPLACE FUNCTION public.begin_edge_idempotency(
  p_scope text,
  p_requester_key text,
  p_idempotency_key text,
  p_request_hash text,
  p_ttl_seconds integer DEFAULT 86400,
  p_in_progress_ttl_seconds integer DEFAULT 60,
  p_now timestamptz DEFAULT now()
)
RETURNS TABLE (
  decision text,
  response_status integer,
  response_body jsonb,
  retry_after_seconds integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_row public.edge_idempotency_keys%ROWTYPE;
BEGIN
  IF p_scope IS NULL OR btrim(p_scope) = '' THEN
    RAISE EXCEPTION 'idempotency scope is required';
  END IF;
  IF p_requester_key IS NULL OR btrim(p_requester_key) = '' THEN
    RAISE EXCEPTION 'idempotency requester_key is required';
  END IF;
  IF p_idempotency_key IS NULL OR btrim(p_idempotency_key) = '' THEN
    RAISE EXCEPTION 'idempotency key is required';
  END IF;
  IF p_request_hash IS NULL OR btrim(p_request_hash) = '' THEN
    RAISE EXCEPTION 'idempotency request_hash is required';
  END IF;
  IF p_ttl_seconds <= 0 OR p_in_progress_ttl_seconds <= 0 THEN
    RAISE EXCEPTION 'idempotency TTL values must be positive';
  END IF;

  PERFORM pg_advisory_xact_lock(
    hashtextextended(
      p_scope || ':' || p_requester_key || ':' || p_idempotency_key,
      0
    )
  );

  DELETE FROM public.edge_idempotency_keys
  WHERE scope = p_scope
    AND requester_key = p_requester_key
    AND idempotency_key = p_idempotency_key
    AND expires_at <= p_now;

  SELECT *
    INTO v_row
  FROM public.edge_idempotency_keys
  WHERE scope = p_scope
    AND requester_key = p_requester_key
    AND idempotency_key = p_idempotency_key
  FOR UPDATE;

  IF NOT FOUND THEN
    INSERT INTO public.edge_idempotency_keys (
      scope,
      requester_key,
      idempotency_key,
      request_hash,
      status,
      locked_until,
      expires_at,
      created_at,
      updated_at
    )
    VALUES (
      p_scope,
      p_requester_key,
      p_idempotency_key,
      p_request_hash,
      'in_progress',
      p_now + make_interval(secs => p_in_progress_ttl_seconds),
      p_now + make_interval(secs => p_ttl_seconds),
      p_now,
      p_now
    );

    RETURN QUERY SELECT 'started'::text, NULL::integer, NULL::jsonb, 0;
    RETURN;
  END IF;

  IF v_row.request_hash <> p_request_hash THEN
    RETURN QUERY SELECT 'conflict'::text, NULL::integer, NULL::jsonb, 0;
    RETURN;
  END IF;

  IF v_row.status = 'completed' THEN
    RETURN QUERY SELECT
      'replay'::text,
      v_row.response_status,
      v_row.response_body,
      0;
    RETURN;
  END IF;

  IF v_row.status = 'in_progress' AND v_row.locked_until > p_now THEN
    RETURN QUERY SELECT
      'in_progress'::text,
      NULL::integer,
      NULL::jsonb,
      greatest(1, ceil(extract(epoch FROM (v_row.locked_until - p_now)))::integer);
    RETURN;
  END IF;

  UPDATE public.edge_idempotency_keys
  SET status = 'in_progress',
      response_status = NULL,
      response_body = NULL,
      locked_until = p_now + make_interval(secs => p_in_progress_ttl_seconds),
      expires_at = p_now + make_interval(secs => p_ttl_seconds),
      updated_at = p_now
  WHERE scope = p_scope
    AND requester_key = p_requester_key
    AND idempotency_key = p_idempotency_key;

  RETURN QUERY SELECT 'started'::text, NULL::integer, NULL::jsonb, 0;
END;
$$;

CREATE OR REPLACE FUNCTION public.complete_edge_idempotency(
  p_scope text,
  p_requester_key text,
  p_idempotency_key text,
  p_request_hash text,
  p_response_status integer,
  p_response_body jsonb,
  p_ttl_seconds integer DEFAULT 86400,
  p_now timestamptz DEFAULT now()
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_updated boolean;
BEGIN
  IF p_response_status < 100 OR p_response_status > 599 THEN
    RAISE EXCEPTION 'response_status must be a valid HTTP status';
  END IF;
  IF p_response_body IS NULL THEN
    RAISE EXCEPTION 'response_body is required';
  END IF;

  UPDATE public.edge_idempotency_keys
  SET status = 'completed',
      response_status = p_response_status,
      response_body = p_response_body,
      locked_until = p_now,
      expires_at = p_now + make_interval(secs => p_ttl_seconds),
      updated_at = p_now
  WHERE scope = p_scope
    AND requester_key = p_requester_key
    AND idempotency_key = p_idempotency_key
    AND request_hash = p_request_hash
    AND status = 'in_progress'
  RETURNING true INTO v_updated;

  RETURN coalesce(v_updated, false);
END;
$$;

CREATE OR REPLACE FUNCTION public.fail_edge_idempotency(
  p_scope text,
  p_requester_key text,
  p_idempotency_key text,
  p_request_hash text,
  p_ttl_seconds integer DEFAULT 86400,
  p_now timestamptz DEFAULT now()
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_updated boolean;
BEGIN
  UPDATE public.edge_idempotency_keys
  SET status = 'failed',
      response_status = NULL,
      response_body = NULL,
      locked_until = p_now,
      expires_at = p_now + make_interval(secs => p_ttl_seconds),
      updated_at = p_now
  WHERE scope = p_scope
    AND requester_key = p_requester_key
    AND idempotency_key = p_idempotency_key
    AND request_hash = p_request_hash
    AND status = 'in_progress'
  RETURNING true INTO v_updated;

  RETURN coalesce(v_updated, false);
END;
$$;

CREATE OR REPLACE FUNCTION public.cleanup_edge_runtime_guardrails(
  p_now timestamptz DEFAULT now()
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_count integer;
BEGIN
  DELETE FROM public.edge_idempotency_keys
  WHERE expires_at <= p_now;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

REVOKE ALL ON FUNCTION public.consume_edge_rate_limit(text, numeric, numeric, numeric, timestamptz)
  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.begin_edge_idempotency(text, text, text, text, integer, integer, timestamptz)
  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.complete_edge_idempotency(text, text, text, text, integer, jsonb, integer, timestamptz)
  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.fail_edge_idempotency(text, text, text, text, integer, timestamptz)
  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.cleanup_edge_runtime_guardrails(timestamptz)
  FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.consume_edge_rate_limit(text, numeric, numeric, numeric, timestamptz)
  TO service_role;
GRANT EXECUTE ON FUNCTION public.begin_edge_idempotency(text, text, text, text, integer, integer, timestamptz)
  TO service_role;
GRANT EXECUTE ON FUNCTION public.complete_edge_idempotency(text, text, text, text, integer, jsonb, integer, timestamptz)
  TO service_role;
GRANT EXECUTE ON FUNCTION public.fail_edge_idempotency(text, text, text, text, integer, timestamptz)
  TO service_role;
GRANT EXECUTE ON FUNCTION public.cleanup_edge_runtime_guardrails(timestamptz)
  TO service_role;
