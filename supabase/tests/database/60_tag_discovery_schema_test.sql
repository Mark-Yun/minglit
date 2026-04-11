BEGIN;
SELECT no_plan();

-- ============================================================
-- 1. tags 테이블 존재 + 컬럼 + PK
-- ============================================================
SELECT has_table('public', 'tags', 'tags table exists');

SELECT col_is_pk('public', 'tags', 'id', 'tags.id is primary key');
SELECT col_type_is('public', 'tags', 'id', 'uuid', 'tags.id is uuid');
SELECT col_type_is('public', 'tags', 'name', 'text', 'tags.name is text');
SELECT col_type_is('public', 'tags', 'is_featured', 'boolean', 'tags.is_featured is boolean');
SELECT col_type_is('public', 'tags', 'usage_count', 'integer', 'tags.usage_count is integer');
SELECT col_type_is('public', 'tags', 'created_at', 'timestamp with time zone', 'tags.created_at is timestamptz');

SELECT col_not_null('public', 'tags', 'id', 'tags.id is NOT NULL');
SELECT col_not_null('public', 'tags', 'name', 'tags.name is NOT NULL');
SELECT col_not_null('public', 'tags', 'is_featured', 'tags.is_featured is NOT NULL');
SELECT col_not_null('public', 'tags', 'usage_count', 'tags.usage_count is NOT NULL');
SELECT col_not_null('public', 'tags', 'created_at', 'tags.created_at is NOT NULL');

-- tags.name UNIQUE 제약
SELECT results_eq(
  $$
    SELECT count(*)::int
    FROM pg_constraint c
    JOIN pg_class t ON t.oid = c.conrelid
    JOIN pg_namespace n ON n.oid = t.relnamespace
    WHERE n.nspname = 'public'
      AND t.relname = 'tags'
      AND c.contype = 'u'
  $$,
  $$VALUES (1)$$,
  'tags.name has unique constraint'
);

-- ============================================================
-- 2. party_tags 테이블 존재 + 컬럼 + 복합 PK + FK
-- ============================================================
SELECT has_table('public', 'party_tags', 'party_tags table exists');

SELECT col_type_is('public', 'party_tags', 'party_id', 'uuid', 'party_tags.party_id is uuid');
SELECT col_type_is('public', 'party_tags', 'tag_id', 'uuid', 'party_tags.tag_id is uuid');
SELECT col_not_null('public', 'party_tags', 'party_id', 'party_tags.party_id is NOT NULL');
SELECT col_not_null('public', 'party_tags', 'tag_id', 'party_tags.tag_id is NOT NULL');

SELECT fk_ok(
  'public', 'party_tags', 'party_id',
  'public', 'parties', 'id',
  'party_tags.party_id → parties.id FK exists'
);

SELECT fk_ok(
  'public', 'party_tags', 'tag_id',
  'public', 'tags', 'id',
  'party_tags.tag_id → tags.id FK exists'
);

-- ============================================================
-- 3. user_interest_tags 테이블 존재 + 컬럼 + FK
-- ============================================================
SELECT has_table('public', 'user_interest_tags', 'user_interest_tags table exists');

SELECT col_type_is('public', 'user_interest_tags', 'user_id', 'uuid', 'user_interest_tags.user_id is uuid');
SELECT col_type_is('public', 'user_interest_tags', 'tag_id', 'uuid', 'user_interest_tags.tag_id is uuid');
SELECT col_not_null('public', 'user_interest_tags', 'user_id', 'user_interest_tags.user_id is NOT NULL');
SELECT col_not_null('public', 'user_interest_tags', 'tag_id', 'user_interest_tags.tag_id is NOT NULL');

SELECT fk_ok(
  'public', 'user_interest_tags', 'tag_id',
  'public', 'tags', 'id',
  'user_interest_tags.tag_id → tags.id FK exists'
);

-- ============================================================
-- 4. tag_usage_daily 테이블 존재 + 컬럼 + FK
-- ============================================================
SELECT has_table('public', 'tag_usage_daily', 'tag_usage_daily table exists');

SELECT col_type_is('public', 'tag_usage_daily', 'tag_id', 'uuid', 'tag_usage_daily.tag_id is uuid');
SELECT col_type_is('public', 'tag_usage_daily', 'date', 'date', 'tag_usage_daily.date is date');
SELECT col_type_is('public', 'tag_usage_daily', 'daily_count', 'integer', 'tag_usage_daily.daily_count is integer');
SELECT col_not_null('public', 'tag_usage_daily', 'tag_id', 'tag_usage_daily.tag_id is NOT NULL');
SELECT col_not_null('public', 'tag_usage_daily', 'date', 'tag_usage_daily.date is NOT NULL');
SELECT col_not_null('public', 'tag_usage_daily', 'daily_count', 'tag_usage_daily.daily_count is NOT NULL');

SELECT fk_ok(
  'public', 'tag_usage_daily', 'tag_id',
  'public', 'tags', 'id',
  'tag_usage_daily.tag_id → tags.id FK exists'
);

-- ============================================================
-- 5. RLS enabled
-- ============================================================
SELECT tests.rls_enabled('public', 'tags');
SELECT tests.rls_enabled('public', 'party_tags');
SELECT tests.rls_enabled('public', 'user_interest_tags');
SELECT tests.rls_enabled('public', 'tag_usage_daily');

-- ============================================================
-- 6. 시드 데이터: 인기 태그 25개 존재 확인
-- ============================================================
SELECT results_eq(
  $$SELECT count(*)::int FROM tags WHERE is_featured = true$$,
  $$VALUES (25)$$,
  '25 featured seed tags exist'
);

-- ============================================================
-- 7. trg_party_tags_limit — 6개째 태그 삽입 시 에러
-- ============================================================
SELECT tests.authenticate_as_service_role();

WITH p AS (
  INSERT INTO public.partners (name, introduction)
  VALUES ('Test Partner Tags', 'for trigger test')
  RETURNING id
),
loc AS (
  INSERT INTO public.locations (partner_id, name, address)
  SELECT p.id, 'Test Venue', 'Seoul'
  FROM p
  RETURNING id, partner_id
),
party AS (
  INSERT INTO public.parties (partner_id, location_id, title, description)
  SELECT loc.partner_id, loc.id, 'Tag Limit Test Party', '"Test"'::jsonb
  FROM loc
  RETURNING id
)
SELECT set_config('tests.tag_party_id', id::text, true) FROM party;

-- 태그 6개 준비
WITH inserted AS (
  INSERT INTO public.tags (name) VALUES
    ('test_tag_1'), ('test_tag_2'), ('test_tag_3'),
    ('test_tag_4'), ('test_tag_5'), ('test_tag_6')
  RETURNING id
)
SELECT set_config(
  'tests.tag_ids',
  (SELECT string_agg(id::text, ',' ORDER BY id) FROM inserted),
  true
);

-- 1~5번 태그 삽입은 성공해야 함
SELECT lives_ok(
  format(
    $$
      INSERT INTO public.party_tags (party_id, tag_id)
      SELECT '%s'::uuid, unnest(
        (SELECT array_agg(id) FROM (
          SELECT id FROM public.tags
          WHERE name IN ('test_tag_1','test_tag_2','test_tag_3','test_tag_4','test_tag_5')
        ) sub)
      )
    $$,
    current_setting('tests.tag_party_id')
  ),
  'inserting 5 party_tags succeeds'
);

-- 6번째 태그 삽입은 실패해야 함
SAVEPOINT before_6th_tag;
SELECT throws_ok(
  format(
    $$
      INSERT INTO public.party_tags (party_id, tag_id)
      SELECT '%s'::uuid, id FROM public.tags WHERE name = 'test_tag_6'
    $$,
    current_setting('tests.tag_party_id')
  ),
  'P0001',
  'A party can have at most 5 tags',
  '6th party_tag rejected by trigger'
);
ROLLBACK TO SAVEPOINT before_6th_tag;

-- ============================================================
-- 8. trg_update_tag_usage — INSERT 시 usage_count + 1, tag_usage_daily upsert
-- ============================================================

-- 현재 usage_count 기록
SELECT results_eq(
  format(
    $$
      SELECT count(*)::int FROM public.party_tags WHERE party_id = '%s'
    $$,
    current_setting('tests.tag_party_id')
  ),
  $$VALUES (5)$$,
  'party has exactly 5 tags after insert'
);

-- test_tag_1의 usage_count 확인 (1이어야 함)
SELECT results_eq(
  $$
    SELECT usage_count FROM public.tags WHERE name = 'test_tag_1'
  $$,
  $$VALUES (1)$$,
  'usage_count incremented to 1 after party_tag insert'
);

-- tag_usage_daily 레코드 생성 확인
SELECT results_eq(
  $$
    SELECT count(*)::int FROM public.tag_usage_daily
    WHERE tag_id = (SELECT id FROM public.tags WHERE name = 'test_tag_1')
      AND date = CURRENT_DATE
  $$,
  $$VALUES (1)$$,
  'tag_usage_daily record created for test_tag_1'
);

-- ============================================================
-- 9. trg_update_tag_usage — DELETE 시 usage_count - 1
-- ============================================================
DELETE FROM public.party_tags
WHERE party_id = current_setting('tests.tag_party_id')::uuid
  AND tag_id = (SELECT id FROM public.tags WHERE name = 'test_tag_1');

SELECT results_eq(
  $$SELECT usage_count FROM public.tags WHERE name = 'test_tag_1'$$,
  $$VALUES (0)$$,
  'usage_count decremented to 0 after party_tag delete'
);

-- ============================================================
-- 10. trg_user_interest_tags_limit — 6개째 관심 태그 삽입 시 에러
-- ============================================================
SELECT tests.create_supabase_user('tag_test_user', 'tag_test@test.com');

-- service_role로 직접 INSERT (user_interest_tags RLS가 SELECT-only이므로)
-- 트리거 동작 자체를 테스트하는 것이므로 service_role 사용이 적절
SELECT tests.authenticate_as_service_role();

SELECT lives_ok(
  format(
    $$
      INSERT INTO public.user_interest_tags (user_id, tag_id)
      SELECT '%s'::uuid, id FROM public.tags
      WHERE name IN ('test_tag_1','test_tag_2','test_tag_3','test_tag_4','test_tag_5')
    $$,
    tests.get_supabase_uid('tag_test_user')
  ),
  'inserting 5 user_interest_tags succeeds'
);

SAVEPOINT before_6th_interest_tag;
SELECT throws_ok(
  format(
    $$
      INSERT INTO public.user_interest_tags (user_id, tag_id)
      SELECT '%s'::uuid, id FROM public.tags WHERE name = 'test_tag_6'
    $$,
    tests.get_supabase_uid('tag_test_user')
  ),
  'P0001',
  'A user can have at most 5 interest tags',
  '6th user_interest_tag rejected by trigger'
);
ROLLBACK TO SAVEPOINT before_6th_interest_tag;

-- ============================================================
-- 11. PGroonga 인덱스 존재 확인
-- ============================================================
SELECT has_index(
  'public',
  'tags',
  'idx_tags_name_pgroonga',
  'PGroonga index idx_tags_name_pgroonga exists on tags'
);

SELECT * FROM finish();
ROLLBACK;
