BEGIN;

SELECT plan(25);

SELECT has_table('edge_rate_limit_buckets');
SELECT has_table('edge_idempotency_keys');
SELECT has_function(
  'public',
  'consume_edge_rate_limit',
  ARRAY['text', 'numeric', 'numeric', 'numeric', 'timestamp with time zone'],
  'consume_edge_rate_limit function exists'
);
SELECT has_function(
  'public',
  'begin_edge_idempotency',
  ARRAY['text', 'text', 'text', 'text', 'integer', 'integer', 'timestamp with time zone'],
  'begin_edge_idempotency function exists'
);
SELECT has_function(
  'public',
  'complete_edge_idempotency',
  ARRAY['text', 'text', 'text', 'text', 'integer', 'jsonb', 'integer', 'timestamp with time zone'],
  'complete_edge_idempotency function exists'
);
SELECT has_function(
  'public',
  'fail_edge_idempotency',
  ARRAY['text', 'text', 'text', 'text', 'integer', 'timestamp with time zone'],
  'fail_edge_idempotency function exists'
);
SELECT has_function(
  'public',
  'cleanup_edge_runtime_guardrails',
  ARRAY['timestamp with time zone', 'integer'],
  'cleanup_edge_runtime_guardrails function exists'
);

SELECT is_empty(
  $$
  WITH target(function_signature) AS (
    VALUES
      ('public.consume_edge_rate_limit(text,numeric,numeric,numeric,timestamp with time zone)'),
      ('public.begin_edge_idempotency(text,text,text,text,integer,integer,timestamp with time zone)'),
      ('public.complete_edge_idempotency(text,text,text,text,integer,jsonb,integer,timestamp with time zone)'),
      ('public.fail_edge_idempotency(text,text,text,text,integer,timestamp with time zone)'),
      ('public.cleanup_edge_runtime_guardrails(timestamp with time zone,integer)')
  )
  SELECT function_signature
  FROM target
  WHERE has_function_privilege('anon', function_signature, 'EXECUTE')
  ORDER BY function_signature
  $$,
  'anon cannot execute Edge runtime guardrail RPCs'
);

SELECT is_empty(
  $$
  WITH target(function_signature) AS (
    VALUES
      ('public.consume_edge_rate_limit(text,numeric,numeric,numeric,timestamp with time zone)'),
      ('public.begin_edge_idempotency(text,text,text,text,integer,integer,timestamp with time zone)'),
      ('public.complete_edge_idempotency(text,text,text,text,integer,jsonb,integer,timestamp with time zone)'),
      ('public.fail_edge_idempotency(text,text,text,text,integer,timestamp with time zone)'),
      ('public.cleanup_edge_runtime_guardrails(timestamp with time zone,integer)')
  )
  SELECT function_signature
  FROM target
  WHERE has_function_privilege('authenticated', function_signature, 'EXECUTE')
  ORDER BY function_signature
  $$,
  'authenticated cannot execute Edge runtime guardrail RPCs'
);

SELECT is_empty(
  $$
  WITH target(function_signature) AS (
    VALUES
      ('public.consume_edge_rate_limit(text,numeric,numeric,numeric,timestamp with time zone)'),
      ('public.begin_edge_idempotency(text,text,text,text,integer,integer,timestamp with time zone)'),
      ('public.complete_edge_idempotency(text,text,text,text,integer,jsonb,integer,timestamp with time zone)'),
      ('public.fail_edge_idempotency(text,text,text,text,integer,timestamp with time zone)'),
      ('public.cleanup_edge_runtime_guardrails(timestamp with time zone,integer)')
  )
  SELECT function_signature
  FROM target
  WHERE NOT has_function_privilege('service_role', function_signature, 'EXECUTE')
  ORDER BY function_signature
  $$,
  'service_role can execute Edge runtime guardrail RPCs'
);

SELECT results_eq(
  $$
  SELECT allowed, remaining::integer, retry_after_seconds
  FROM public.consume_edge_rate_limit(
    'test:rate:user-1',
    2,
    1,
    1,
    '2026-01-01T00:00:00Z'::timestamptz
  )
  $$,
  $$ VALUES (true, 1, 0) $$,
  'token bucket starts full and consumes one token'
);

SELECT results_eq(
  $$
  SELECT allowed, remaining::integer, retry_after_seconds
  FROM public.consume_edge_rate_limit(
    'test:rate:user-1',
    2,
    1,
    1,
    '2026-01-01T00:00:00Z'::timestamptz
  )
  $$,
  $$ VALUES (true, 0, 0) $$,
  'token bucket allows burst up to capacity'
);

SELECT results_eq(
  $$
  SELECT allowed, remaining::integer, retry_after_seconds
  FROM public.consume_edge_rate_limit(
    'test:rate:user-1',
    2,
    1,
    1,
    '2026-01-01T00:00:00Z'::timestamptz
  )
  $$,
  $$ VALUES (false, 0, 1) $$,
  'token bucket denies once capacity is exhausted'
);

SELECT results_eq(
  $$
  SELECT allowed, remaining::integer, retry_after_seconds
  FROM public.consume_edge_rate_limit(
    'test:rate:user-1',
    2,
    1,
    1,
    '2026-01-01T00:00:01Z'::timestamptz
  )
  $$,
  $$ VALUES (true, 0, 0) $$,
  'token bucket refills deterministically by elapsed seconds'
);

SELECT results_eq(
  $$
  SELECT decision, retry_after_seconds
  FROM public.begin_edge_idempotency(
    'apply-event',
    'user:user-1',
    'idem-key-1',
    'hash-a',
    60,
    10,
    '2026-01-01T00:00:00Z'::timestamptz
  )
  $$,
  $$ VALUES ('started'::text, 0) $$,
  'idempotency begins a new in-progress operation'
);

SELECT results_eq(
  $$
  SELECT decision, retry_after_seconds
  FROM public.begin_edge_idempotency(
    'apply-event',
    'user:user-1',
    'idem-key-1',
    'hash-a',
    60,
    10,
    '2026-01-01T00:00:01Z'::timestamptz
  )
  $$,
  $$ VALUES ('in_progress'::text, 9) $$,
  'same idempotency key reports in-progress until lock expiry'
);

SELECT results_eq(
  $$
  SELECT decision, retry_after_seconds
  FROM public.begin_edge_idempotency(
    'apply-event',
    'user:user-1',
    'idem-key-1',
    'hash-b',
    60,
    10,
    '2026-01-01T00:00:01Z'::timestamptz
  )
  $$,
  $$ VALUES ('conflict'::text, 0) $$,
  'same idempotency key with a different request hash conflicts'
);

SELECT is(
  public.fail_edge_idempotency(
    'apply-event',
    'user:user-1',
    'idem-key-1',
    'hash-a',
    60,
    '2026-01-01T00:00:02Z'::timestamptz
  ),
  true,
  'failed in-progress idempotency record can be marked failed'
);

SELECT results_eq(
  $$
  SELECT decision, retry_after_seconds
  FROM public.begin_edge_idempotency(
    'apply-event',
    'user:user-1',
    'idem-key-1',
    'hash-a',
    60,
    10,
    '2026-01-01T00:00:03Z'::timestamptz
  )
  $$,
  $$ VALUES ('started'::text, 0) $$,
  'same request hash can retry after a failed attempt'
);

SELECT is(
  public.complete_edge_idempotency(
    'apply-event',
    'user:user-1',
    'idem-key-1',
    'hash-a',
    201,
    '{"ok":true}'::jsonb,
    60,
    '2026-01-01T00:00:04Z'::timestamptz
  ),
  true,
  'completed idempotency record stores JSON response'
);

SELECT results_eq(
  $$
  SELECT decision, response_status, response_body, retry_after_seconds
  FROM public.begin_edge_idempotency(
    'apply-event',
    'user:user-1',
    'idem-key-1',
    'hash-a',
    60,
    10,
    '2026-01-01T00:00:05Z'::timestamptz
  )
  $$,
  $$ VALUES ('replay'::text, 201, '{"ok":true}'::jsonb, 0) $$,
  'completed idempotency record replays cached response'
);

SELECT results_eq(
  $$
  SELECT decision, retry_after_seconds
  FROM public.begin_edge_idempotency(
    'cleanup',
    'user:user-1',
    'cleanup-key',
    'hash-cleanup',
    1,
    1,
    '2026-01-01T00:00:00Z'::timestamptz
  )
  $$,
  $$ VALUES ('started'::text, 0) $$,
  'cleanup fixture idempotency row is inserted'
);

SELECT results_eq(
  $$
  SELECT allowed, remaining::integer, retry_after_seconds
  FROM public.consume_edge_rate_limit(
    'test:cleanup:bucket',
    1,
    1,
    1,
    '2026-01-01T00:00:00Z'::timestamptz
  )
  $$,
  $$ VALUES (true, 0, 0) $$,
  'cleanup fixture rate limit bucket is inserted'
);

SELECT is(
  public.cleanup_edge_runtime_guardrails(
    '2026-01-01T00:00:02Z'::timestamptz,
    2
  ),
  2,
  'expired idempotency records and stale rate limit buckets are cleaned up'
);

SELECT is_empty(
  $$
  SELECT 1
  FROM public.edge_rate_limit_buckets
  WHERE key = 'test:cleanup:bucket'
  $$,
  'stale rate limit buckets are removed'
);

SELECT * FROM finish();

ROLLBACK;
