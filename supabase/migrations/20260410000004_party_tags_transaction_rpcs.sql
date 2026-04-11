-- Party Tags Transaction RPCs
-- Issue #1223
-- partner-manage-party EF가 parties + party_tags 를 2단계 write로 처리해
-- 2단계 실패 시 고아 row가 남는 문제를 RPC로 원자적 처리로 전환
--
-- ⚠️ SCHEMA SYNC WARNING:
-- create_party_with_tags()의 INSERT 컬럼 목록은 parties 테이블 스키마에 하드코딩되어 있다.
-- parties 테이블에 NOT NULL 컬럼을 추가하면 이 RPC도 함께 수정해야 한다.
-- (REST API는 자동 동기화되지만 RPC는 수동 업데이트 필요)

-- ============================================================
-- 1. create_party_with_tags
--    parties INSERT + party_tags INSERT 를 단일 트랜잭션으로 처리
-- ============================================================
CREATE OR REPLACE FUNCTION create_party_with_tags(
  p_party jsonb,
  p_tag_ids uuid[]
)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_party_id uuid;
BEGIN
  -- Insert party record from jsonb fields
  INSERT INTO parties (
    partner_id,
    location_id,
    title,
    description,
    image_urls,
    contact_options,
    required_verification_ids,
    min_confirmed_count,
    max_participants,
    balance_config,
    status
  )
  VALUES (
    (p_party->>'partner_id')::uuid,
    NULLIF(p_party->>'location_id', '')::uuid,
    p_party->>'title',
    CASE WHEN p_party ? 'description' THEN p_party->'description' ELSE NULL END,
    CASE WHEN p_party ? 'image_urls' THEN ARRAY(SELECT jsonb_array_elements_text(p_party->'image_urls')) ELSE '{}'::text[] END,
    CASE WHEN p_party ? 'contact_options' THEN p_party->'contact_options' ELSE '{}'::jsonb END,
    CASE WHEN p_party ? 'required_verification_ids'
      THEN ARRAY(SELECT (value::text::uuid) FROM jsonb_array_elements_text(p_party->'required_verification_ids'))
      ELSE '{}'::uuid[] END,
    COALESCE((p_party->>'min_confirmed_count')::integer, 0),
    COALESCE((p_party->>'max_participants')::integer, 20),
    CASE WHEN p_party ? 'balance_config' THEN p_party->'balance_config' ELSE NULL END,
    COALESCE(p_party->>'status', 'active')
  )
  RETURNING id INTO v_party_id;

  -- Insert party_tags if tag_ids provided and non-empty
  -- Fix #1223: advisory lock consistent with check_party_tags_limit trigger pattern
  IF p_tag_ids IS NOT NULL AND array_length(p_tag_ids, 1) IS NOT NULL AND array_length(p_tag_ids, 1) > 0 THEN
    PERFORM pg_advisory_xact_lock(hashtext(v_party_id::text));

    INSERT INTO party_tags (party_id, tag_id)
    SELECT v_party_id, unnest(p_tag_ids)
    ON CONFLICT (party_id, tag_id) DO NOTHING;
  END IF;

  RETURN v_party_id;
END;
$$;

-- ============================================================
-- 2. update_party_tags
--    party_tags DELETE + INSERT を 단일 트랜잭션으로 처리
--    empty array = 전체 삭제, non-empty = replace
-- ============================================================
CREATE OR REPLACE FUNCTION update_party_tags(
  p_party_id uuid,
  p_tag_ids uuid[]
)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Fix #1223: advisory lock으로 동시 호출 직렬화 (check_party_tags_limit 트리거와 동일 패턴)
  PERFORM pg_advisory_xact_lock(hashtext(p_party_id::text));

  -- Validate tag count
  IF array_length(p_tag_ids, 1) IS NOT NULL AND array_length(p_tag_ids, 1) > 5 THEN
    RAISE EXCEPTION 'A party can have at most 5 tags';
  END IF;

  IF p_tag_ids IS NULL OR array_length(p_tag_ids, 1) IS NULL THEN
    -- NULL or empty array: delete all tags
    DELETE FROM party_tags WHERE party_id = p_party_id;
  ELSE
    -- Fix #1149 pattern: DELETE stale rows first, then INSERT new ones.
    -- Deleting before inserting keeps running count ≤5 so check_party_tags_limit
    -- trigger does not reject valid same-size swaps.
    DELETE FROM party_tags
    WHERE party_id = p_party_id
      AND tag_id != ALL(p_tag_ids);

    INSERT INTO party_tags (party_id, tag_id)
    SELECT p_party_id, unnest(p_tag_ids)
    ON CONFLICT (party_id, tag_id) DO NOTHING;
  END IF;
END;
$$;

-- ============================================================
-- 3. REVOKE PUBLIC + GRANT authenticated/service_role
-- ============================================================

-- Fix #1223: create_party_with_tags
REVOKE EXECUTE ON FUNCTION create_party_with_tags(jsonb, uuid[]) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION create_party_with_tags(jsonb, uuid[]) TO authenticated, service_role;

-- Fix #1223: update_party_tags
REVOKE EXECUTE ON FUNCTION update_party_tags(uuid, uuid[]) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION update_party_tags(uuid, uuid[]) TO authenticated, service_role;
