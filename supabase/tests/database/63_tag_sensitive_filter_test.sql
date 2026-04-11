BEGIN;
SELECT no_plan();

-- ============================================================
-- 테스트 데이터 세팅 (service_role)
-- admin_user: super_admin — tags INSERT/UPDATE RLS는 super_admin 전용
-- ============================================================
SELECT tests.create_supabase_user('sf_admin', 'sf_admin@test.com');

SELECT tests.authenticate_as_service_role();

-- super_admin 등록
INSERT INTO public.app_roles (user_id, role)
VALUES (tests.get_supabase_uid('sf_admin'), 'super_admin');

-- ============================================================
-- 1. 트리거 존재 확인
-- ============================================================
SELECT has_trigger(
  'public',
  'tags',
  'trg_check_tag_sensitivity',
  'trg_check_tag_sensitivity trigger exists on tags table'
);

-- ============================================================
-- 2. 함수 존재 확인
-- ============================================================
SELECT has_function(
  'public',
  'check_tag_name_sensitivity',
  'check_tag_name_sensitivity() function exists'
);

-- ============================================================
-- 3. 정상 태그 허용 — 민감 키워드 미포함 태그는 INSERT 성공
-- ============================================================
SELECT tests.authenticate_as('sf_admin');

SAVEPOINT before_safe_inserts;

SELECT lives_ok(
  $$INSERT INTO public.tags (name) VALUES ('요리')$$,
  'safe tag "요리" INSERT succeeds'
);

SELECT lives_ok(
  $$INSERT INTO public.tags (name) VALUES ('보드게임')$$,
  'safe tag "보드게임" INSERT succeeds'
);

ROLLBACK TO SAVEPOINT before_safe_inserts;

-- ============================================================
-- 4. 각 카테고리별 차단 테스트
-- ============================================================

-- 4-1. racial_ethnic: 인종/민족 키워드
SAVEPOINT before_racial;
SELECT throws_ok(
  $$INSERT INTO public.tags (name) VALUES ('흑인모임')$$,
  'P0001',
  'Tag name contains sensitive content (category: racial_ethnic)',
  'racial_ethnic keyword "흑인" in tag name is blocked'
);
ROLLBACK TO SAVEPOINT before_racial;

-- 4-2. health_medical: 건강/질병 키워드
SAVEPOINT before_health;
SELECT throws_ok(
  $$INSERT INTO public.tags (name) VALUES ('HIV양성')$$,
  'P0001',
  'Tag name contains sensitive content (category: health_medical)',
  'health_medical keyword "HIV" in tag name is blocked'
);
ROLLBACK TO SAVEPOINT before_health;

-- 4-3. sexual_orientation: 성적 지향 키워드
SAVEPOINT before_sexual;
SELECT throws_ok(
  $$INSERT INTO public.tags (name) VALUES ('게이바')$$,
  'P0001',
  'Tag name contains sensitive content (category: sexual_orientation)',
  'sexual_orientation keyword "게이" in tag name is blocked'
);
ROLLBACK TO SAVEPOINT before_sexual;

-- 4-4. political: 정치 키워드
SAVEPOINT before_political;
SELECT throws_ok(
  $$INSERT INTO public.tags (name) VALUES ('좌파모임')$$,
  'P0001',
  'Tag name contains sensitive content (category: political)',
  'political keyword "좌파" in tag name is blocked'
);
ROLLBACK TO SAVEPOINT before_political;

-- 4-5. religious: 종교 키워드
SAVEPOINT before_religious;
SELECT throws_ok(
  $$INSERT INTO public.tags (name) VALUES ('기독교모임')$$,
  'P0001',
  'Tag name contains sensitive content (category: religious)',
  'religious keyword "기독교" in tag name is blocked'
);
ROLLBACK TO SAVEPOINT before_religious;

-- 4-6. criminal: 범죄 키워드
SAVEPOINT before_criminal;
SELECT throws_ok(
  $$INSERT INTO public.tags (name) VALUES ('전과자')$$,
  'P0001',
  'Tag name contains sensitive content (category: criminal)',
  'criminal keyword "전과자" in tag name is blocked'
);
ROLLBACK TO SAVEPOINT before_criminal;

-- 4-7. genetic: 유전 키워드
SAVEPOINT before_genetic;
SELECT throws_ok(
  $$INSERT INTO public.tags (name) VALUES ('DNA검사')$$,
  'P0001',
  'Tag name contains sensitive content (category: genetic)',
  'genetic keyword "DNA" in tag name is blocked'
);
ROLLBACK TO SAVEPOINT before_genetic;

-- ============================================================
-- 5. UPDATE 차단 테스트 — 안전한 태그를 민감 키워드로 rename 시 차단
-- ============================================================

-- 안전한 태그를 먼저 삽입
INSERT INTO public.tags (name) VALUES ('sf_safe_update_target');
SELECT set_config(
  'tests.sf_safe_tag_id',
  (SELECT id::text FROM public.tags WHERE name = 'sf_safe_update_target'),
  true
);

SAVEPOINT before_sensitive_update;
SELECT throws_ok(
  format(
    $$UPDATE public.tags SET name = '흑인모임' WHERE id = '%s'$$,
    current_setting('tests.sf_safe_tag_id')
  ),
  'P0001',
  'Tag name contains sensitive content (category: racial_ethnic)',
  'UPDATE to sensitive name is blocked by trigger'
);
ROLLBACK TO SAVEPOINT before_sensitive_update;

-- 안전한 이름으로의 UPDATE는 허용
SELECT lives_ok(
  format(
    $$UPDATE public.tags SET name = 'sf_safe_update_target_renamed' WHERE id = '%s'$$,
    current_setting('tests.sf_safe_tag_id')
  ),
  'UPDATE to safe name succeeds'
);

-- ============================================================
-- 6. 기존 시드 태그 무영향 — 25개 featured 태그가 정상 존재
-- ============================================================
SELECT tests.authenticate_as_service_role();

SELECT results_eq(
  $$SELECT count(*)::int FROM public.tags WHERE is_featured = true$$,
  $$VALUES (25)$$,
  '25 featured seed tags are unaffected by sensitive filter trigger'
);

SELECT * FROM finish();
ROLLBACK;
