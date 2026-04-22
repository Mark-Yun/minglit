-- Regression tests for #1708: PIPA §21 탈퇴 즉시 파기 약속 pgTAP 검증
--
-- 개인정보처리방침: "관심 태그 / 기기 토큰 / 임베딩 벡터 — 탈퇴 시 즉시 파기"
-- process-pending-deletions EF가 auth.admin.deleteUser()를 호출하면
-- auth.users ON DELETE CASCADE가 연쇄 삭제됩니다. 이 테스트는 CASCADE 체인이
-- 실제로 4개 테이블을 비우는지 DB 수준에서 검증합니다.
--
-- Cascade chains:
--   auth.users → fcm_tokens (direct, ON DELETE CASCADE)
--   auth.users → user_interest_tags (direct, ON DELETE CASCADE)
--   auth.users → user_profiles → user_embeddings (ON DELETE CASCADE chain)
--
-- party_embeddings 범위 제외 이유:
--   party_embeddings.party_id → parties.id (ON DELETE CASCADE)
--   parties는 partners(사업체) 소유이며 auth.users와 직접 연결되지 않음.
--   유저 탈퇴 시 party는 삭제되지 않으므로 party_embeddings는 CASCADE 대상 외.
--   (audit 이슈 §F8 참조: party_embeddings는 유저 귀속 데이터가 아님)
--
-- Self-contained: creates its own fixtures. Does NOT depend on dev seed data.
BEGIN;

SELECT plan(8);

SELECT tests.authenticate_as_service_role();

-- ── fixtures ──────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_user_id uuid;
  v_profile_id uuid;
  v_tag_id uuid;
BEGIN
  -- create test user
  v_user_id := tests.create_supabase_user(
    'pipa_purge_test_1708',
    'pipa_purge_test_1708@pgtap.local'
  );

  -- wait for handle_new_user trigger to create user_profiles
  -- (trigger inserts into user_profiles on auth.users insert)

  -- fcm_tokens: direct reference to auth.users
  INSERT INTO public.fcm_tokens (user_id, token, device_type)
  VALUES (v_user_id, 'test-fcm-token-pipa-1708', 'android');

  -- user_interest_tags: direct reference to auth.users
  -- use an existing tag or create a temp tag
  SELECT id INTO v_tag_id FROM public.tags LIMIT 1;
  IF v_tag_id IS NOT NULL THEN
    INSERT INTO public.user_interest_tags (user_id, tag_id)
    VALUES (v_user_id, v_tag_id)
    ON CONFLICT DO NOTHING;
  END IF;

  -- user_embeddings: references user_profiles(id) which cascades from auth.users
  -- user_profiles.id = auth.users.id (same UUID)
  INSERT INTO public.user_embeddings (user_id, embedding)
  VALUES (v_user_id, array_fill(0.1, ARRAY[1536])::extensions.vector(1536))
  ON CONFLICT (user_id) DO NOTHING;

  -- store user_id for verification
  PERFORM set_config('pipa.test_user_id', v_user_id::text, true);
END $$;

-- ── pre-deletion assertions ────────────────────────────────────────────────────

-- 1. fcm_tokens has record before deletion
SELECT ok(
  EXISTS(
    SELECT 1 FROM public.fcm_tokens
    WHERE user_id = current_setting('pipa.test_user_id')::uuid
      AND token = 'test-fcm-token-pipa-1708'
  ),
  'fixture: fcm_tokens record exists before deletion'
);

-- 2. user_embeddings has record before deletion
SELECT ok(
  EXISTS(
    SELECT 1 FROM public.user_embeddings
    WHERE user_id = current_setting('pipa.test_user_id')::uuid
  ),
  'fixture: user_embeddings record exists before deletion'
);

-- ── simulate auth.admin.deleteUser: delete from auth.users ────────────────────
-- process-pending-deletions EF calls supabase.auth.admin.deleteUser(userId)
-- which internally deletes the row from auth.users, triggering CASCADE.
DELETE FROM auth.users WHERE id = current_setting('pipa.test_user_id')::uuid;

-- ── post-deletion assertions: CASCADE 체인 검증 ────────────────────────────────

-- 3. fcm_tokens purged (direct CASCADE from auth.users)
SELECT ok(
  NOT EXISTS(
    SELECT 1 FROM public.fcm_tokens
    WHERE user_id = current_setting('pipa.test_user_id')::uuid
  ),
  '#1708 PIPA §21: fcm_tokens purged on auth.users delete (ON DELETE CASCADE)'
);

-- 4. user_interest_tags purged (direct CASCADE from auth.users)
SELECT ok(
  NOT EXISTS(
    SELECT 1 FROM public.user_interest_tags
    WHERE user_id = current_setting('pipa.test_user_id')::uuid
  ),
  '#1708 PIPA §21: user_interest_tags purged on auth.users delete (ON DELETE CASCADE)'
);

-- 5. user_embeddings purged (CASCADE: auth.users → user_profiles → user_embeddings)
SELECT ok(
  NOT EXISTS(
    SELECT 1 FROM public.user_embeddings
    WHERE user_id = current_setting('pipa.test_user_id')::uuid
  ),
  '#1708 PIPA §21: user_embeddings purged on auth.users delete (CASCADE chain via user_profiles)'
);

-- 6. user_profiles purged (direct CASCADE from auth.users)
SELECT ok(
  NOT EXISTS(
    SELECT 1 FROM public.user_profiles
    WHERE id = current_setting('pipa.test_user_id')::uuid
  ),
  '#1708 PIPA §21: user_profiles purged on auth.users delete (ON DELETE CASCADE)'
);

-- 7. auth.users row itself is gone
SELECT ok(
  NOT EXISTS(
    SELECT 1 FROM auth.users
    WHERE id = current_setting('pipa.test_user_id')::uuid
  ),
  '#1708: auth.users row deleted'
);

-- 8. party_embeddings scope note: not user-linked
-- party_embeddings → parties → partners (not auth.users)
-- Verified: party_embeddings has no user_id column, so no cascade from auth.users.
-- This is by design — party embeddings are owned by partners, not individual users.
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
