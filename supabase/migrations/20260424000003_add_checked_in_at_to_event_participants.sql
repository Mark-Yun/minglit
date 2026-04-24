-- [QR Checkin] Phase 2 — checked_in_at 컬럼 추가
-- Issue #1810
--
-- event_participants에 체크인 시각을 기록하는 컬럼을 추가한다.
-- status = 'checked_in' 전환 시 process_qr_checkin RPC가 이 값을 설정한다.

alter table public.event_participants
  add column if not exists checked_in_at timestamptz;

comment on column public.event_participants.checked_in_at is
  'QR 체크인 처리 시각 (NULL = 미체크인)';
