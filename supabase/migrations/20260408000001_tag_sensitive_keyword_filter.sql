-- Tag Sensitive Keyword Filter
-- Issue #1158
-- 개인정보보호법 제23조(민감정보 처리 제한) 대비: tags 테이블 INSERT/UPDATE 시 민감 키워드 차단

-- ============================================================
-- 1. check_tag_name_sensitivity(): 민감 키워드 blocklist 트리거 함수
-- ============================================================
CREATE OR REPLACE FUNCTION check_tag_name_sensitivity()
RETURNS TRIGGER AS $$
DECLARE
  v_keyword text;
BEGIN
  -- 인종/민족 (개인정보보호법 제23조 제1호)
  FOREACH v_keyword IN ARRAY ARRAY[
    '흑인', '백인', '황인', '혼혈', '다문화'
  ] LOOP
    IF NEW.name ILIKE '%' || v_keyword || '%' THEN
      RAISE EXCEPTION 'Tag name contains sensitive content (category: racial_ethnic)'
        USING ERRCODE = 'P0001';
    END IF;
  END LOOP;

  -- 건강/질병 (개인정보보호법 제23조 제3호)
  FOREACH v_keyword IN ARRAY ARRAY[
    '장애', '질병', 'HIV', '에이즈', '정신병', '우울증', '자폐'
  ] LOOP
    IF NEW.name ILIKE '%' || v_keyword || '%' THEN
      RAISE EXCEPTION 'Tag name contains sensitive content (category: health_medical)'
        USING ERRCODE = 'P0001';
    END IF;
  END LOOP;

  -- 성적 지향 (개인정보보호법 제23조 제2호)
  FOREACH v_keyword IN ARRAY ARRAY[
    '동성애', '게이', '레즈비언', '트랜스젠더', '바이섹슈얼', '퀴어', '성소수자'
  ] LOOP
    IF NEW.name ILIKE '%' || v_keyword || '%' THEN
      RAISE EXCEPTION 'Tag name contains sensitive content (category: sexual_orientation)'
        USING ERRCODE = 'P0001';
    END IF;
  END LOOP;

  -- 정치적 견해 (개인정보보호법 제23조 제4호)
  FOREACH v_keyword IN ARRAY ARRAY[
    '좌파', '우파', '보수', '진보', '빨갱이'
  ] LOOP
    IF NEW.name ILIKE '%' || v_keyword || '%' THEN
      RAISE EXCEPTION 'Tag name contains sensitive content (category: political)'
        USING ERRCODE = 'P0001';
    END IF;
  END LOOP;

  -- 종교 (개인정보보호법 제23조 제5호)
  -- 종교 이벤트 정책 수립 시 allowlist 방식으로 전환 검토. plan.md ADR-5 참고.
  FOREACH v_keyword IN ARRAY ARRAY[
    '기독교', '불교', '이슬람', '천주교', '무슬림', '개신교'
  ] LOOP
    IF NEW.name ILIKE '%' || v_keyword || '%' THEN
      RAISE EXCEPTION 'Tag name contains sensitive content (category: religious)'
        USING ERRCODE = 'P0001';
    END IF;
  END LOOP;

  -- 범죄 전력 (개인정보보호법 제23조 제6호)
  FOREACH v_keyword IN ARRAY ARRAY[
    '전과', '범죄자', '성범죄'
  ] LOOP
    IF NEW.name ILIKE '%' || v_keyword || '%' THEN
      RAISE EXCEPTION 'Tag name contains sensitive content (category: criminal)'
        USING ERRCODE = 'P0001';
    END IF;
  END LOOP;

  -- 유전 정보 (개인정보보호법 제23조 제7호)
  FOREACH v_keyword IN ARRAY ARRAY[
    '유전자', 'DNA'
  ] LOOP
    IF NEW.name ILIKE '%' || v_keyword || '%' THEN
      RAISE EXCEPTION 'Tag name contains sensitive content (category: genetic)'
        USING ERRCODE = 'P0001';
    END IF;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- 2. trg_check_tag_sensitivity: tags BEFORE INSERT OR UPDATE OF name
-- ============================================================
CREATE TRIGGER trg_check_tag_sensitivity
  BEFORE INSERT OR UPDATE OF name ON tags
  FOR EACH ROW EXECUTE FUNCTION check_tag_name_sensitivity();
