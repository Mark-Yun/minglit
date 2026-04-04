BEGIN;
SELECT no_plan();

-- ============================================================
-- 1. Schema — recurrence_rules 테이블 존재 + 컬럼 + 제약조건
-- ============================================================
SELECT has_table('public', 'recurrence_rules', 'recurrence_rules table exists');

SELECT col_is_pk('public', 'recurrence_rules', 'id', 'recurrence_rules.id is primary key');
SELECT col_type_is('public', 'recurrence_rules', 'id', 'uuid', 'id is uuid');
SELECT col_type_is('public', 'recurrence_rules', 'party_id', 'uuid', 'party_id is uuid');
SELECT col_type_is('public', 'recurrence_rules', 'pattern', 'text', 'pattern is text');
SELECT col_type_is('public', 'recurrence_rules', 'days_of_week', 'integer[]', 'days_of_week is int[]');
SELECT col_type_is('public', 'recurrence_rules', 'month_day', 'integer', 'month_day is integer');
SELECT col_type_is('public', 'recurrence_rules', 'start_time', 'time without time zone', 'start_time is time');
SELECT col_type_is('public', 'recurrence_rules', 'end_time', 'time without time zone', 'end_time is time');
SELECT col_type_is('public', 'recurrence_rules', 'end_date', 'date', 'end_date is date');
SELECT col_type_is('public', 'recurrence_rules', 'status', 'text', 'status is text');
SELECT col_type_is('public', 'recurrence_rules', 'last_generated_date', 'date', 'last_generated_date is date');
SELECT col_type_is('public', 'recurrence_rules', 'created_at', 'timestamp with time zone', 'created_at is timestamptz');
SELECT col_type_is('public', 'recurrence_rules', 'updated_at', 'timestamp with time zone', 'updated_at is timestamptz');

SELECT col_not_null('public', 'recurrence_rules', 'party_id', 'party_id is NOT NULL');
SELECT col_not_null('public', 'recurrence_rules', 'pattern', 'pattern is NOT NULL');
SELECT col_not_null('public', 'recurrence_rules', 'days_of_week', 'days_of_week is NOT NULL');
SELECT col_not_null('public', 'recurrence_rules', 'start_time', 'start_time is NOT NULL');
SELECT col_not_null('public', 'recurrence_rules', 'end_time', 'end_time is NOT NULL');
SELECT col_not_null('public', 'recurrence_rules', 'status', 'status is NOT NULL');

-- ============================================================
-- 2. CHECK 제약조건 — pattern IN ('weekly', 'biweekly', 'monthly')
-- ============================================================
SELECT results_eq(
  $$
    SELECT count(*)::int
    FROM pg_constraint c
    JOIN pg_class t ON t.oid = c.conrelid
    JOIN pg_namespace n ON n.oid = t.relnamespace
    WHERE n.nspname = 'public'
      AND t.relname = 'recurrence_rules'
      AND c.conname = 'recurrence_rules_pattern_check'
  $$,
  $$VALUES (1)$$,
  'recurrence_rules_pattern_check constraint exists'
);

-- ============================================================
-- 3. CHECK 제약조건 — status IN ('active', 'paused', 'cancelled')
-- ============================================================
SELECT results_eq(
  $$
    SELECT count(*)::int
    FROM pg_constraint c
    JOIN pg_class t ON t.oid = c.conrelid
    JOIN pg_namespace n ON n.oid = t.relnamespace
    WHERE n.nspname = 'public'
      AND t.relname = 'recurrence_rules'
      AND c.conname = 'recurrence_rules_status_check'
  $$,
  $$VALUES (1)$$,
  'recurrence_rules_status_check constraint exists'
);

-- ============================================================
-- 4. CHECK 제약조건 — month_day BETWEEN 1 AND 31
-- ============================================================
SELECT results_eq(
  $$
    SELECT count(*)::int
    FROM pg_constraint c
    JOIN pg_class t ON t.oid = c.conrelid
    JOIN pg_namespace n ON n.oid = t.relnamespace
    WHERE n.nspname = 'public'
      AND t.relname = 'recurrence_rules'
      AND c.conname = 'recurrence_rules_month_day_check'
  $$,
  $$VALUES (1)$$,
  'recurrence_rules_month_day_check constraint exists'
);

-- ============================================================
-- 5. Partial Unique Index — uq_recurrence_rules_party_active
-- ============================================================
SELECT has_index(
  'public',
  'recurrence_rules',
  'uq_recurrence_rules_party_active',
  'uq_recurrence_rules_party_active partial unique index exists'
);

-- ============================================================
-- 6. FK — party_id → parties(id)
-- ============================================================
SELECT fk_ok(
  'public', 'recurrence_rules', 'party_id',
  'public', 'parties', 'id',
  'recurrence_rules.party_id → parties.id FK exists'
);

-- ============================================================
-- 7. events 테이블 컬럼 추가 확인
-- ============================================================
SELECT col_type_is('public', 'events', 'recurrence_rule_id', 'uuid', 'events.recurrence_rule_id is uuid');
SELECT col_type_is('public', 'events', 'is_recurrence_exception', 'boolean', 'events.is_recurrence_exception is boolean');
SELECT col_not_null('public', 'events', 'is_recurrence_exception', 'is_recurrence_exception is NOT NULL');
SELECT col_type_is('public', 'events', 'recurrence_date', 'date', 'events.recurrence_date is date');

-- ============================================================
-- 8. Partial Unique Index — uq_events_recurrence_date
-- ============================================================
SELECT has_index(
  'public',
  'events',
  'uq_events_recurrence_date',
  'uq_events_recurrence_date partial unique index exists'
);

-- ============================================================
-- 9. RLS enabled
-- ============================================================
SELECT tests.rls_enabled('public', 'recurrence_rules');

-- ============================================================
-- 10. CHECK 제약 — 잘못된 pattern 거부
-- ============================================================
SELECT tests.authenticate_as_service_role();

SAVEPOINT before_bad_pattern;
SELECT throws_ok(
  $$
    INSERT INTO public.recurrence_rules (
      party_id, pattern, start_time, end_time
    ) VALUES (
      gen_random_uuid(), 'daily', '10:00', '11:00'
    )
  $$,
  '23514',
  NULL,
  'invalid pattern value rejected by CHECK constraint'
);
ROLLBACK TO SAVEPOINT before_bad_pattern;

-- ============================================================
-- 11. CHECK 제약 — 잘못된 status 거부
-- ============================================================
SAVEPOINT before_bad_status;
SELECT throws_ok(
  $$
    INSERT INTO public.recurrence_rules (
      party_id, pattern, start_time, end_time, status
    ) VALUES (
      gen_random_uuid(), 'weekly', '10:00', '11:00', 'deleted'
    )
  $$,
  '23514',
  NULL,
  'invalid status value rejected by CHECK constraint'
);
ROLLBACK TO SAVEPOINT before_bad_status;

-- ============================================================
-- 12. Partial Unique Index — 동일 party_id의 active 규칙 2개 불가
-- ============================================================

-- 테스트 데이터 세팅
WITH p AS (
  INSERT INTO public.partners (name, introduction)
  VALUES ('Test Partner RR', 'for recurrence test')
  RETURNING id
),
loc AS (
  INSERT INTO public.locations (partner_id, name, address)
  SELECT p.id, 'Test Venue', 'Seoul'
  FROM p
  RETURNING id, partner_id
),
party AS (
  INSERT INTO public.parties (
    partner_id, location_id, title, description,
    max_participants, ticket_close_at
  )
  SELECT
    loc.partner_id,
    loc.id,
    'Recurrence Test Party',
    'Test',
    10,
    now() + interval '7 days'
  FROM loc
  RETURNING id
)
SELECT set_config('tests.rr_party_id', id::text, true) FROM party;

INSERT INTO public.recurrence_rules (
  party_id, pattern, start_time, end_time
) VALUES (
  current_setting('tests.rr_party_id')::uuid,
  'weekly',
  '10:00',
  '11:00'
);

SAVEPOINT before_dup_active;
SELECT throws_ok(
  format(
    $$
      INSERT INTO public.recurrence_rules (
        party_id, pattern, start_time, end_time
      ) VALUES (
        '%s', 'monthly', '14:00', '15:00'
      )
    $$,
    current_setting('tests.rr_party_id')
  ),
  '23505',
  NULL,
  'second active rule for same party rejected by partial unique index'
);
ROLLBACK TO SAVEPOINT before_dup_active;

-- ============================================================
-- 13. Partial Unique Index — cancelled 규칙은 중복 허용
-- ============================================================
UPDATE public.recurrence_rules
SET status = 'cancelled'
WHERE party_id = current_setting('tests.rr_party_id')::uuid;

SELECT lives_ok(
  format(
    $$
      INSERT INTO public.recurrence_rules (
        party_id, pattern, start_time, end_time
      ) VALUES (
        '%s', 'monthly', '14:00', '15:00'
      )
    $$,
    current_setting('tests.rr_party_id')
  ),
  'second rule allowed after first is cancelled'
);

-- ============================================================
-- 14. uq_events_recurrence_date — 같은 날짜 중복 이벤트 거부
-- recurrence_date 컬럼으로 중복 방지 (start_time::date 대신)
-- ============================================================
WITH rule AS (
  SELECT id FROM public.recurrence_rules
  WHERE party_id = current_setting('tests.rr_party_id')::uuid
    AND status = 'active'
  LIMIT 1
),
evt AS (
  INSERT INTO public.events (
    party_id, recurrence_rule_id,
    title, description, status,
    start_time, end_time, max_participants, recurrence_date
  )
  SELECT
    current_setting('tests.rr_party_id')::uuid,
    rule.id,
    'Recurring Event',
    'Test',
    'scheduled',
    '2026-05-01 10:00:00+09',
    '2026-05-01 11:00:00+09',
    10,
    '2026-05-01'::date
  FROM rule
  RETURNING recurrence_rule_id
)
SELECT set_config('tests.rr_rule_id', recurrence_rule_id::text, true) FROM evt;

SAVEPOINT before_dup_event;
SELECT throws_ok(
  format(
    $$
      INSERT INTO public.events (
        party_id, recurrence_rule_id,
        title, description, status,
        start_time, end_time, max_participants, recurrence_date
      ) VALUES (
        '%s', '%s',
        'Duplicate Event', 'Test', 'scheduled',
        '2026-05-01 14:00:00+09', '2026-05-01 15:00:00+09', 10,
        '2026-05-01'::date
      )
    $$,
    current_setting('tests.rr_party_id'),
    current_setting('tests.rr_rule_id')
  ),
  '23505',
  NULL,
  'duplicate event on same recurrence_rule_id + recurrence_date rejected'
);
ROLLBACK TO SAVEPOINT before_dup_event;

-- ============================================================
-- 15. moddatetime 트리거 — updated_at 갱신 확인
-- ============================================================
SELECT lives_ok(
  format(
    $$
      UPDATE public.recurrence_rules
      SET end_date = '2026-12-31'
      WHERE party_id = '%s' AND status = 'active'
    $$,
    current_setting('tests.rr_party_id')
  ),
  'update recurrence_rule succeeds'
);

SELECT results_eq(
  format(
    $$
      SELECT count(*)::int
      FROM public.recurrence_rules
      WHERE party_id = '%s'
        AND status = 'active'
        AND updated_at >= now() - interval '5 seconds'
    $$,
    current_setting('tests.rr_party_id')
  ),
  $$VALUES (1)$$,
  'updated_at refreshed by moddatetime trigger'
);

SELECT * FROM finish();
ROLLBACK;
