-- Fix #1760: pg_cron ↔ EF auth drift 방지 — ef_auth_manifest 선언 테이블
--
-- 목적: PR #1494의 requireServiceRole() 추가 후 pg_cron Authorization이
--       업데이트되지 않아 6일간 무음 401 발생. 이를 재발 방지하기 위해
--       EF별 필요 인증 레벨을 선언하고 pgTAP으로 cron.job과의 일관성을 검증한다.
--
-- 유지보수 규칙: EF에 requireServiceRole() 추가/제거 시
--   같은 PR에서 이 테이블의 required_auth도 반드시 업데이트할 것.

CREATE TABLE IF NOT EXISTS public.ef_auth_manifest (
  ef_name     text PRIMARY KEY,
  required_auth text NOT NULL CHECK (required_auth IN (
    'public', 'authenticated', 'service_role'
  )),
  description text,
  updated_at  timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.ef_auth_manifest IS
  'Edge Function별 필요 인증 레벨 선언. '
  'EF에 requireServiceRole() 추가/제거 시 required_auth도 같은 PR에서 업데이트 필수. '
  'pgTAP 95_ef_auth_manifest_cron_consistency_test.sql이 cron.job과의 일관성을 검증한다.';

ALTER TABLE public.ef_auth_manifest ENABLE ROW LEVEL SECURITY;
CREATE POLICY ef_auth_manifest_select ON public.ef_auth_manifest
  FOR SELECT USING (true);

-- ──────────────────────────────────────────────────────────
-- 초기 seed: 알려진 모든 EF의 인증 레벨 선언
-- (PR #1494 기준 + #1758 수정 반영)
-- ──────────────────────────────────────────────────────────

INSERT INTO public.ef_auth_manifest (ef_name, required_auth, description) VALUES
  -- service_role: pg_cron에서 호출 / requireServiceRole() 가드
  ('ai-embed',                  'service_role', 'pgvector 임베딩 생성 — pg_cron 호출'),
  ('ai-extract-tags',           'service_role', 'AI 태그 추출 — pg_cron 매분 호출'),
  ('backend-simulator',         'service_role', '백엔드 시뮬레이션 — pg_cron 매시간 호출'),
  ('cleanup-blocked-dis',       'service_role', '차단/신고 삭제 정리 — pg_cron 호출'),
  ('cleanup-retention',         'service_role', 'retention 정책 실행 — pg_cron 호출'),
  ('event-matching',            'service_role', '이벤트 매칭 처리 — pg_cron 호출'),
  ('github-stats-sync',         'service_role', 'GitHub 통계 동기화 — pg_cron 매일 호출'),
  ('metrics-alert',             'service_role', '메트릭 알람 — pg_cron 매 30분 호출'),
  ('notification-worker',       'service_role', '알림 워커 — pg_cron 매분 호출'),
  ('payout-sync',               'service_role', '정산 지급 동기화 — pg_cron 호출'),
  ('process-pending-deletions', 'service_role', '지연 삭제 처리 — pg_cron 호출'),
  ('reconciliation-daily',      'service_role', '정산 대사 — pg_cron 매일 호출'),
  ('recurrence-cron',           'service_role', '반복 이벤트 생성 — pg_cron 호출'),
  ('settlement-register-transfers', 'service_role', '정산 이전 등록 — pg_cron 호출'),
  ('settlement-transfer',       'service_role', '정산 이전 실행 — requireServiceRole'),

  -- authenticated: 유저/파트너 인증 필요
  ('apply-event',               'authenticated', '이벤트 신청'),
  ('event-checkin',             'authenticated', '이벤트 체크인'),
  ('identity-verify',           'authenticated', '신원 인증'),
  ('partner-approve-application', 'authenticated', '파트너 신청 승인'),
  ('partner-manage-event',      'authenticated', '파트너 이벤트 관리'),
  ('partner-manage-match',      'authenticated', '파트너 매칭 관리'),
  ('partner-manage-member',     'authenticated', '파트너 멤버 관리'),
  ('partner-manage-party',      'authenticated', '파트너 파티 관리'),
  ('partner-manage-settlement', 'authenticated', '파트너 정산 관리'),
  ('partner-manage-verification', 'authenticated', '파트너 인증 관리'),
  ('partner-register',          'authenticated', '파트너 등록'),
  ('partner-reject-application', 'authenticated', '파트너 신청 거부'),
  ('partner-review-submission', 'authenticated', '파트너 제출 리뷰'),
  ('user-cancel-deletion',      'authenticated', '회원 탈퇴 취소'),
  ('user-cancel-order',         'authenticated', '주문 취소'),
  ('user-create-order',         'authenticated', '주문 생성'),
  ('user-delete-account',       'authenticated', '회원 탈퇴'),
  ('user-event-feed',           'authenticated', '이벤트 피드'),
  ('user-manage-notification',  'authenticated', '알림 설정'),
  ('user-manage-settings',      'authenticated', '사용자 설정'),
  ('user-manage-social',        'authenticated', '소셜 관리'),
  ('user-submit-verification',  'authenticated', '인증 제출'),
  ('user-update-verification',  'authenticated', '인증 업데이트'),
  ('recurrence-rules',          'authenticated', '반복 규칙 조회'),

  -- public: 인증 불필요
  ('health',                    'public',        'Health check')

ON CONFLICT (ef_name) DO UPDATE SET
  required_auth = EXCLUDED.required_auth,
  description   = EXCLUDED.description,
  updated_at    = now();
