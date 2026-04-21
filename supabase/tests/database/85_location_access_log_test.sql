-- pgTAP tests for location_access_log (feat #1697, 위치정보법 §16)
BEGIN;

SELECT plan(10);

-- 1. 테이블 존재
SELECT has_table('public', 'location_access_log', 'location_access_log table exists');

-- 2. 필수 컬럼
SELECT has_column('public', 'location_access_log', 'user_id', 'has user_id');
SELECT has_column('public', 'location_access_log', 'accessed_at', 'has accessed_at');
SELECT has_column('public', 'location_access_log', 'purpose', 'has purpose');

-- 3. RLS 활성화
SELECT ok(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'location_access_log'),
  'RLS is enabled on location_access_log'
);

-- 4. retention_policies 등록 확인: 정책 존재 + legal_min_days=180 + enabled
SELECT ok(
  EXISTS(
    SELECT 1 FROM admin.retention_policies
    WHERE id = 'location_access_log'
      AND kind = 'db_table'
      AND enabled = true
      AND legal_min_days = 180
      AND retention_days >= 180
  ),
  'location_access_log retention policy registered with legal_min_days=180'
);

-- 5. CHECK 제약: retention_days < legal_min_days 거절
SELECT throws_ok(
  $$
    UPDATE admin.retention_policies
    SET retention_days = 30
    WHERE id = 'location_access_log'
  $$,
  'retention_above_legal_min',
  'CHECK constraint rejects retention_days < legal_min_days'
);

-- 6. purpose CHECK 제약: 유효하지 않은 목적 거절
SELECT throws_ok(
  $$
    INSERT INTO public.location_access_log (purpose) VALUES ('invalid_purpose')
  $$,
  '23514',
  'purpose CHECK constraint rejects invalid value'
);

-- 7. purpose CHECK 제약: 유효한 값 허용
SELECT lives_ok(
  $$
    INSERT INTO public.location_access_log (user_id, purpose)
    VALUES (NULL, 'nearby_search')
  $$,
  'nearby_search purpose is accepted'
);

-- 8. GPS 좌표 컬럼 미존재 확인 (방침 준수)
SELECT hasnt_column('public', 'location_access_log', 'lat', 'no lat column — GPS 좌표 미저장');
SELECT hasnt_column('public', 'location_access_log', 'lng', 'no lng column — GPS 좌표 미저장');

SELECT * FROM finish();
ROLLBACK;
