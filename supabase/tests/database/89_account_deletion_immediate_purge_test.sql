-- Regression tests for #1708: PIPA §21 탈퇴 즉시 파기 약속 pgTAP 검증
--
-- 개인정보처리방침: "관심 태그 / 기기 토큰 / 임베딩 벡터 — 탈퇴 시 즉시 파기"
-- process-pending-deletions EF가 auth.admin.deleteUser()를 호출하면
-- auth.users ON DELETE CASCADE가 연쇄 삭제됩니다.
--
-- 접근 방식: 스키마 정적 검증 (pg_constraint)
--   pgTAP 환경에서 service_role은 auth.users를 직접 DELETE할 권한이 없습니다.
--   대신 ON DELETE CASCADE 제약이 DB 스키마에 선언되어 있음을 검증합니다.
--   이는 법적 약속의 기술적 근거(CASCADE constraint)를 직접 증명하는 방식입니다.
--
-- Cascade chains verified:
--   auth.users → fcm_tokens (direct, ON DELETE CASCADE)
--   auth.users → user_interest_tags (direct, ON DELETE CASCADE)
--   auth.users → user_profiles (direct, ON DELETE CASCADE)
--   user_profiles → user_embeddings (ON DELETE CASCADE — 2nd hop)
--
-- party_embeddings 범위 제외 이유:
--   party_embeddings.party_id → parties.id (ON DELETE CASCADE)
--   parties는 partners(사업체) 소유이며 auth.users와 직접 연결되지 않음.
--   유저 탈퇴 시 party는 삭제되지 않으므로 party_embeddings는 CASCADE 대상 외.
--   (audit 이슈 §F8 참조: party_embeddings는 유저 귀속 데이터가 아님)
BEGIN;

SELECT plan(8);

-- ── helper: ON DELETE CASCADE FK existence check ──────────────────────────────
-- Returns true if src_schema.src_table has an FK to ref_schema.ref_table
-- with confdeltype = 'c' (CASCADE).
CREATE OR REPLACE FUNCTION pg_temp.has_cascade_fk(
  src_schema text, src_table text,
  ref_schema text, ref_table text
) RETURNS boolean AS $$
  SELECT EXISTS(
    SELECT 1
    FROM pg_constraint c
    JOIN pg_class src ON c.conrelid = src.oid
    JOIN pg_namespace src_ns ON src.relnamespace = src_ns.oid
    JOIN pg_class ref ON c.confrelid = ref.oid
    JOIN pg_namespace ref_ns ON ref.relnamespace = ref_ns.oid
    WHERE c.contype = 'f'
      AND c.confdeltype = 'c'
      AND src_ns.nspname = src_schema
      AND src.relname = src_table
      AND ref_ns.nspname = ref_schema
      AND ref.relname = ref_table
  );
$$ LANGUAGE sql;

-- ── CASCADE constraint assertions ─────────────────────────────────────────────

-- 1. fcm_tokens → auth.users CASCADE (기기 토큰: 직접 삭제)
SELECT ok(
  pg_temp.has_cascade_fk('public', 'fcm_tokens', 'auth', 'users'),
  '#1708 PIPA §21: fcm_tokens.user_id → auth.users ON DELETE CASCADE'
);

-- 2. user_interest_tags → auth.users CASCADE (관심 태그: 직접 삭제)
SELECT ok(
  pg_temp.has_cascade_fk('public', 'user_interest_tags', 'auth', 'users'),
  '#1708 PIPA §21: user_interest_tags.user_id → auth.users ON DELETE CASCADE'
);

-- 3. user_profiles → auth.users CASCADE (프로필: CASCADE 체인 중간 노드)
SELECT ok(
  pg_temp.has_cascade_fk('public', 'user_profiles', 'auth', 'users'),
  '#1708 PIPA §21: user_profiles.id → auth.users ON DELETE CASCADE'
);

-- 4. user_embeddings → user_profiles CASCADE (임베딩 벡터: 2-hop 체인)
SELECT ok(
  pg_temp.has_cascade_fk('public', 'user_embeddings', 'public', 'user_profiles'),
  '#1708 PIPA §21: user_embeddings.user_id → user_profiles ON DELETE CASCADE (2nd hop)'
);

-- ── structural checks ─────────────────────────────────────────────────────────

-- 5. fcm_tokens has user_id column (FK column exists)
SELECT has_column(
  'public', 'fcm_tokens', 'user_id',
  'fcm_tokens: user_id column exists'
);

-- 6. user_interest_tags has user_id column
SELECT has_column(
  'public', 'user_interest_tags', 'user_id',
  'user_interest_tags: user_id column exists'
);

-- 7. user_embeddings has user_id column (references user_profiles.id)
SELECT has_column(
  'public', 'user_embeddings', 'user_id',
  'user_embeddings: user_id column exists'
);

-- 8. party_embeddings has no user_id column (not user-linked, excluded from §21 scope)
SELECT ok(
  NOT EXISTS(
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'party_embeddings'
      AND column_name = 'user_id'
  ),
  'party_embeddings has no user_id column — confirmed not user-linked (partner-owned data)'
);

SELECT * FROM finish();
ROLLBACK;
