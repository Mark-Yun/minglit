BEGIN;
SELECT plan(12);

-- ============================================================
-- Issue #1177: 민감 키워드 필터 Unicode 우회 취약점 수정 테스트
-- normalize_for_filter() + 트리거 적용 후 우회 벡터 차단 검증
-- ============================================================

SELECT tests.create_supabase_user('unicode_admin', 'unicode_admin@test.com');
SELECT tests.authenticate_as_service_role();

INSERT INTO public.app_roles (user_id, role)
VALUES (tests.get_supabase_uid('unicode_admin'), 'super_admin');

-- ============================================================
-- 1. normalize_for_filter() 함수 존재 확인
-- ============================================================
SELECT has_function(
  'public',
  'normalize_for_filter',
  ARRAY['text'],
  'normalize_for_filter(text) function exists'
);

-- ============================================================
-- 2. Zero-width 문자 제거 검증
--    chr(8203) = U+200B (zero-width space)
--    chr(8204) = U+200C (zero-width non-joiner)
--    chr(8205) = U+200D (zero-width joiner)
-- ============================================================
SELECT results_eq(
  $$SELECT normalize_for_filter('흑' || chr(8203) || '인')$$,
  $$VALUES ('흑인')$$,
  'normalize_for_filter removes U+200B (zero-width space) between Korean chars'
);

SELECT results_eq(
  $$SELECT normalize_for_filter('흑' || chr(8204) || '인')$$,
  $$VALUES ('흑인')$$,
  'normalize_for_filter removes U+200C (zero-width non-joiner)'
);

SELECT results_eq(
  $$SELECT normalize_for_filter('흑' || chr(8205) || '인')$$,
  $$VALUES ('흑인')$$,
  'normalize_for_filter removes U+200D (zero-width joiner)'
);

-- ============================================================
-- 3. NFKC 정규화 검증
--    Fullwidth Latin: chr(65320)=Ｈ, chr(65321)=Ｉ, chr(65334)=Ｖ
--    NFKC 정규화 후 ASCII H, I, V로 변환되어야 함
-- ============================================================
SELECT results_eq(
  $$SELECT normalize_for_filter(chr(65320) || chr(65321) || chr(65334))$$,
  $$VALUES ('HIV')$$,
  'normalize_for_filter NFKC-normalizes Fullwidth Latin ＨＩＶ to HIV'
);

-- chr(65279) = U+FEFF (BOM / zero-width no-break space)
SELECT results_eq(
  $$SELECT normalize_for_filter('HIV' || chr(65279))$$,
  $$VALUES ('HIV')$$,
  'normalize_for_filter removes U+FEFF (BOM)'
);

-- chr(173) = U+00AD (soft hyphen)
SELECT results_eq(
  $$SELECT normalize_for_filter('흑' || chr(173) || '인')$$,
  $$VALUES ('흑인')$$,
  'normalize_for_filter removes U+00AD (soft hyphen)'
);

-- ============================================================
-- 4. 트리거 차단 — Zero-width 우회 시도 차단
--    U+200B 삽입으로 ILIKE 우회 시도 → 정규화 후 차단
-- ============================================================
SELECT tests.authenticate_as('unicode_admin');

SAVEPOINT before_zw_racial;
SELECT throws_ok(
  $$INSERT INTO public.tags (name) VALUES ('흑' || chr(8203) || '인모임')$$,
  'P0001',
  'Tag name contains sensitive content (category: racial_ethnic)',
  'zero-width space bypass of racial_ethnic keyword "흑인" is blocked'
);
ROLLBACK TO SAVEPOINT before_zw_racial;

-- U+200D (zero-width joiner)
SAVEPOINT before_zw_joiner;
SELECT throws_ok(
  $$INSERT INTO public.tags (name) VALUES ('동성' || chr(8205) || '애클럽')$$,
  'P0001',
  'Tag name contains sensitive content (category: sexual_orientation)',
  'zero-width joiner bypass of sexual_orientation keyword "동성애" is blocked'
);
ROLLBACK TO SAVEPOINT before_zw_joiner;

-- ============================================================
-- 5. 트리거 차단 — Fullwidth Latin 우회 시도 차단
--    ＨＩＶ (Fullwidth) → NFKC 정규화 후 HIV로 변환 → 차단
-- ============================================================
SAVEPOINT before_fullwidth_hiv;
SELECT throws_ok(
  $$INSERT INTO public.tags (name) VALUES (chr(65320) || chr(65321) || chr(65334) || '양성')$$,
  'P0001',
  'Tag name contains sensitive content (category: health_medical)',
  'Fullwidth Latin ＨＩＶ bypass of health_medical keyword "HIV" is blocked'
);
ROLLBACK TO SAVEPOINT before_fullwidth_hiv;

-- ============================================================
-- 6. 정상 태그 무영향 — 관련 없는 유사 문자열은 허용
-- ============================================================
SAVEPOINT before_safe_unicode;

-- '복인' — 흑인과 유사하지만 다른 단어
SELECT lives_ok(
  $$INSERT INTO public.tags (name) VALUES ('복인파티')$$,
  'safe tag "복인파티" (not a sensitive keyword) INSERT succeeds'
);

-- 기타 정상 태그
SELECT lives_ok(
  $$INSERT INTO public.tags (name) VALUES ('소셜다이닝')$$,
  'safe tag "소셜다이닝" INSERT succeeds'
);

ROLLBACK TO SAVEPOINT before_safe_unicode;

SELECT * FROM finish();
ROLLBACK;
