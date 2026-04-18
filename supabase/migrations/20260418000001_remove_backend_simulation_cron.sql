-- Fix #1583: backend-simulation pg_cron → GitHub Actions로 이관
-- pg_cron은 dev + main 양쪽에서 매시간 EF를 호출했으나,
-- main에서는 불필요한 HTTP POST이며 EF 가드 단일 레이어 의존 위험이 있다.
-- GitHub Actions는 SUPABASE_DEV_* secret만 참조하므로 구조적으로 main 도달 불가.
--
-- process-notifications, settlement-*, account-deletion-* 등 production-critical cron은 유지.

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'backend-simulation') THEN
    PERFORM cron.unschedule('backend-simulation');
  END IF;
END $$;
