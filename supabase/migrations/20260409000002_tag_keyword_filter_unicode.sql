-- Tag 민감 키워드 필터 Unicode 우회 취약점 수정
-- Issue #1177
-- ILIKE 단순 매칭 → NFKC 정규화 + zero-width 문자 제거 후 비교

-- ============================================================
-- 1. normalize_for_filter(text): NFKC 정규화 + 불가시 문자 제거
--    - NFKC: Fullwidth Latin(ＨＩＶ→HIV), Hangul Jamo 통일 등 처리
--    - regexp_replace: U+200B/200C/200D/FEFF/00AD (zero-width/soft-hyphen) 제거
-- ============================================================
CREATE OR REPLACE FUNCTION normalize_for_filter(input text)
RETURNS text
LANGUAGE sql IMMUTABLE STRICT
AS $$
  -- Fix #1177: NFKC 정규화로 Fullwidth Latin·호모글리프 통일 후 zero-width 문자 제거
  SELECT regexp_replace(
    normalize(input, NFKC),
    U&'[\200B\200C\200D\FEFF\00AD]',
    '',
    'g'
  );
$$;

-- ============================================================
-- 2. check_tag_name_sensitivity() 재정의
--    normalize_for_filter() 적용 후 ILIKE 비교
-- ============================================================
CREATE OR REPLACE FUNCTION check_tag_name_sensitivity()
RETURNS TRIGGER AS $$
DECLARE
  v_keyword text;
  v_normalized_name text;
BEGIN
  -- Fix #1177: 입력값과 키워드 모두 정규화하여 Unicode 우회 차단
  v_normalized_name := normalize_for_filter(NEW.name);

  -- 인종/민족 (개인정보보호법 제23조 제1호)
  FOREACH v_keyword IN ARRAY ARRAY[
    '흑인', '백인', '황인', '혼혈', '다문화'
  ] LOOP
    IF v_normalized_name ILIKE '%' || normalize_for_filter(v_keyword) || '%' THEN
      RAISE EXCEPTION 'Tag name contains sensitive content (category: racial_ethnic)'
        USING ERRCODE = 'P0001';
    END IF;
  END LOOP;

  -- 건강/질병 (개인정보보호법 제23조 제3호)
  FOREACH v_keyword IN ARRAY ARRAY[
    '장애', '질병', 'HIV', '에이즈', '정신병', '우울증', '자폐'
  ] LOOP
    IF v_normalized_name ILIKE '%' || normalize_for_filter(v_keyword) || '%' THEN
      RAISE EXCEPTION 'Tag name contains sensitive content (category: health_medical)'
        USING ERRCODE = 'P0001';
    END IF;
  END LOOP;

  -- 성적 지향 (개인정보보호법 제23조 제2호)
  FOREACH v_keyword IN ARRAY ARRAY[
    '동성애', '게이', '레즈비언', '트랜스젠더', '바이섹슈얼', '퀴어', '성소수자'
  ] LOOP
    IF v_normalized_name ILIKE '%' || normalize_for_filter(v_keyword) || '%' THEN
      RAISE EXCEPTION 'Tag name contains sensitive content (category: sexual_orientation)'
        USING ERRCODE = 'P0001';
    END IF;
  END LOOP;

  -- 정치적 견해 (개인정보보호법 제23조 제4호)
  FOREACH v_keyword IN ARRAY ARRAY[
    '좌파', '우파', '보수', '진보', '빨갱이'
  ] LOOP
    IF v_normalized_name ILIKE '%' || normalize_for_filter(v_keyword) || '%' THEN
      RAISE EXCEPTION 'Tag name contains sensitive content (category: political)'
        USING ERRCODE = 'P0001';
    END IF;
  END LOOP;

  -- 종교 (개인정보보호법 제23조 제5호)
  -- 종교 이벤트 정책 수립 시 allowlist 방식으로 전환 검토. plan.md ADR-5 참고.
  FOREACH v_keyword IN ARRAY ARRAY[
    '기독교', '불교', '이슬람', '천주교', '무슬림', '개신교'
  ] LOOP
    IF v_normalized_name ILIKE '%' || normalize_for_filter(v_keyword) || '%' THEN
      RAISE EXCEPTION 'Tag name contains sensitive content (category: religious)'
        USING ERRCODE = 'P0001';
    END IF;
  END LOOP;

  -- 범죄 전력 (개인정보보호법 제23조 제6호)
  FOREACH v_keyword IN ARRAY ARRAY[
    '전과', '범죄자', '성범죄'
  ] LOOP
    IF v_normalized_name ILIKE '%' || normalize_for_filter(v_keyword) || '%' THEN
      RAISE EXCEPTION 'Tag name contains sensitive content (category: criminal)'
        USING ERRCODE = 'P0001';
    END IF;
  END LOOP;

  -- 유전 정보 (개인정보보호법 제23조 제7호)
  FOREACH v_keyword IN ARRAY ARRAY[
    '유전자', 'DNA'
  ] LOOP
    IF v_normalized_name ILIKE '%' || normalize_for_filter(v_keyword) || '%' THEN
      RAISE EXCEPTION 'Tag name contains sensitive content (category: genetic)'
        USING ERRCODE = 'P0001';
    END IF;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
