# 계획: 통합 알림 시스템 및 센터

## Phase 1: 백엔드 파이프라인 구축
- [x] Task: DB 스키마 설계 및 알림 센터 테이블 생성
    - [x] `user_notifications` 테이블 및 `pg_cron` 삭제 로직 구현.
- [x] Task: Supabase Edge Function (Push Worker) 구현
    - [x] PGMQ 메시지를 읽어 FCM으로 전송하는 워커 작성.
    - [x] Firebase Admin SDK (Deno compatible) 연동.
- [x] Task: 야간 에티켓 및 카테고리 필터링 로직 구현 (Worker 로직에 포함됨)
- [x] Task: Conductor - 사용자 수동 검증 'Phase 1: 푸시 발송 테스트' (Protocol in workflow.md)

## Phase 2: 앱 인프라 및 리시버 구현 (`minglit_kit`)
- [x] Task: `firebase_messaging` 설정 및 FCM 토큰 관리
    - [x] 유저 로그인 시 토큰을 서버에 등록/갱신하는 로직 추가.
- [x] Task: 앱 내 알림 핸들러(Notification Handler) 구현
    - [x] Foreground/Background 알림 수신 로직 및 딥링크 처리 로직.
- [x] Task: 뱃지(Badge) 카운트 동기화 로직 구현 (서버 API `getNotifications`로 대체)
- [x] Task: Conductor - 사용자 수동 검증 'Phase 2: 앱 수신 및 토큰 등록 확인' (Protocol in workflow.md)

## Phase 3: 알림 센터 UI 구현 (`app_user` / `app_partner`)
- [x] Task: 알림 센터 화면 UI 작성
    - [x] 읽음/안읽음 리스트, 전체 읽음 버튼, 스와이프 삭제 기능.
- [x] Task: 알림 탭 시 딥링크 이동 로직 연동
- [x] Task: 알림 설정 화면(수신 동의 토글) 구현
- [x] Task: Conductor - 사용자 수동 검증 'Phase 3: 알림 센터 기능 통합 확인' (Protocol in workflow.md)
