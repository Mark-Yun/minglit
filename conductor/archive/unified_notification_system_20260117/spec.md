# 명세서: 통합 알림 시스템 및 센터 (Unified Notification System)

## 1. 개요
FCM/APN 기반의 푸시 알림 파이프라인을 구축하고, 앱 내에서 지난 알림을 확인하고 관리할 수 있는 알림 센터(In-App Notification Center)를 구현합니다. PGMQ와 Edge Function을 활용한 비동기 아키텍처를 채택하여 확장성을 확보합니다.

## 2. 주요 기능

### 2.1. Backend (Pipeline)
- **이벤트 발행:** 주요 로직(결제, 채팅 등)에서 `notifications` 테이블 insert 또는 PGMQ 메시지 발행.
- **Edge Function Worker:**
    - 알림 큐를 구독하고 FCM 발송 요청 처리.
    - **야간 에티켓(21:00~08:00):** '마케팅' 카테고리는 발송 보류(Queueing) 또는 취소, '서비스' 카테고리는 정상 발송.
- **FCM 연동:** `firebase-admin` SDK를 통해 Android/iOS 타겟 발송.

### 2.2. Database (Storage & Policy)
- **테이블:** `user_notifications`
    - `category`: `marketing` | `service` | `social`
    - `is_read`: 읽음 상태.
    - `deep_link`: 탭 시 이동할 경로 (예: `/events/:id`).
- **보관 정책:** `pg_cron`을 사용하여 생성된 지 **30일**이 지난 알림 자동 삭제.

### 2.3. Frontend (App UI)
- **FCM 핸들링:**
    - Foreground: 상단 `MinglitToast` (피드백 시스템 활용) 표시.
    - Background/Terminated: 시스템 트레이 알림.
- **알림 센터 화면:**
    - 읽음/안읽음 구분, 전체 읽음 처리, 개별 삭제.
    - 딥링크 라우팅 연동.
- **설정 화면:**
    - 마케팅 정보 수신 동의 토글.
    - 야간 알림 수신 설정 (서비스 알림에 한해 Silent 수신 여부).

## 3. 기술 스택
- **Infra:** Supabase (PGMQ, Edge Functions, pg_cron)
- **Push:** Firebase Cloud Messaging (FCM)
- **Client:** `firebase_messaging`, `flutter_local_notifications`

## 4. 수락 기준
- [ ] 서버에서 메시지 발행 시 5초 이내에 앱으로 푸시가 도착해야 함.
- [ ] 앱이 꺼져 있을 때 푸시를 누르면 해당 딥링크 화면으로 정확히 이동해야 함.
- [ ] 알림 센터 진입 시 뱃지 카운트가 초기화되어야 함.
- [ ] 30일 지난 알림은 DB에서 자동으로 사라져야 함.
