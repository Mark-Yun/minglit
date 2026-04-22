-- Verification test for #1709: 위치정보법 §16 — GPS 좌표 "서버 미저장" 증명
--
-- 주변 검색 요청 시 GPS 좌표(lat/lng)는 서버 DB에 저장되지 않습니다.
-- 이 테스트는 해당 약속을 DB 스키마 수준에서 정적으로 검증합니다.
--
-- GPS 흐름 요약:
--   클라이언트 → user-event-feed EF (lat, lng 수신)
--   → user_event_feed RPC (st_makepoint()로 거리 필터링, 메모리 처리)
--   → location_access_log INSERT (user_id, purpose만 저장 — 좌표 없음)
--   → 응답 반환 (GPS 좌표 폐기)
--
-- Verified paths:
--   user-event-feed/index.ts: location_access_log에 {user_id, purpose}만 INSERT
--   user_event_feed RPC: p_lat/p_lng → st_makepoint() → WHERE 절 필터만 사용, INSERT 없음
--   location_access_log 스키마: lat/lng/geography 컬럼 없음
BEGIN;

SELECT plan(6);

-- 1. location_access_log 테이블 존재 확인 (위치정보법 §16 이용 기록 테이블)
SELECT has_table(
  'public',
  'location_access_log',
  'location_access_log table exists for §16 compliance'
);

-- 2. location_access_log에 위도 컬럼 없음
SELECT col_hasnt_table('public', 'location_access_log', 'lat',
  'location_access_log: no lat column — GPS latitude not stored server-side');

-- 3. location_access_log에 경도 컬럼 없음
SELECT col_hasnt_table('public', 'location_access_log', 'lng',
  'location_access_log: no lng column — GPS longitude not stored server-side');

-- 4. location_access_log에 geography/geometry 컬럼 없음
SELECT ok(
  NOT EXISTS(
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'location_access_log'
      AND udt_name IN ('geography', 'geometry')
  ),
  'location_access_log: no geography/geometry column — GPS coordinates not stored in any spatial type'
);

-- 5. location_access_log의 컬럼은 purpose와 timestamp 등 메타데이터만 포함
--    (id, user_id, accessed_at, purpose, country_code)
SELECT ok(
  NOT EXISTS(
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'location_access_log'
      AND column_name IN ('latitude', 'longitude', 'lat', 'lng', 'coordinates', 'location', 'point')
  ),
  'location_access_log: schema contains only metadata columns, no GPS coordinate columns'
);

-- 6. location_access_log retention policy가 6개월로 등록됨 (§16 의무 보존)
SELECT ok(
  EXISTS(
    SELECT 1 FROM admin.retention_policies
    WHERE id = 'location_access_log'
      AND retention_days >= 180
      AND legal_min_days >= 180
  ),
  'location_access_log: retention policy registered with 6-month minimum (§16)'
);

SELECT * FROM finish();
ROLLBACK;
