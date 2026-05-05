-- ============================================================
-- #2124: event_applications.match_results_viewed_at 컬럼 추가
-- EventOngoingBanner phase 6a(미확인) ↔ 6b(확인) 분기를 위한
-- 서버 측 진실 source. NULL = 미확인, non-NULL = 첫 진입 시점.
-- ============================================================

alter table public.event_applications
  add column if not exists match_results_viewed_at timestamptz;

-- NULL이 아닌 row만 인덱싱 (미확인 row 제외 → 인덱스 크기 최소화)
create index if not exists idx_event_applications_match_results_viewed
  on public.event_applications (match_results_viewed_at)
  where match_results_viewed_at is not null;

-- 쓰기 경로는 Edge Function(service_role)에서 처리한다.
