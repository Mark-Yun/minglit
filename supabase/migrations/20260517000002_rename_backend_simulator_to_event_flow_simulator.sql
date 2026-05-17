-- backend-simulator EF 가 event-flow-simulator 로 이름 변경됨에 따른 마무리:
-- 1. pg_cron 의 stale 'backend-simulation' 잡 unschedule
--    (실 트리거는 .github/workflows/monitor-event-flow-{hourly,daily}.yml 로 이관)
-- 2. ef_auth_manifest 의 'backend-simulator' 행 삭제
--    (이름 변경 + cron 미사용 — 매니페스트는 cron-targeted EF 만 등록 대상)

set search_path to public, extensions;

-- 1. cron job unschedule (잡 이름 backend-simulation — PR #1583 GH Actions 이관 후 미정리)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'backend-simulation') THEN
    PERFORM cron.unschedule('backend-simulation');
    RAISE NOTICE 'unscheduled cron job: backend-simulation';
  ELSE
    RAISE NOTICE 'cron job backend-simulation already absent — skipping';
  END IF;
END $$;

-- 2. ef_auth_manifest 정리
DELETE FROM public.ef_auth_manifest WHERE ef_name = 'backend-simulator';
