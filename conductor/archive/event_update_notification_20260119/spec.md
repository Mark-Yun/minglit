# 명세서: 이벤트 업데이트 알림 자동화

## 1. 개요
파트너(주최자)가 이벤트의 중요 정보를 수정했을 때, 해당 이벤트에 참여 신청한 유저들에게 자동으로 변경 사항을 알리는 시스템을 구축합니다. Postgres Trigger와 PGMQ를 활용하여 백엔드 레벨에서 자동화합니다.

## 2. 주요 기능
- **변경 감지:** `events` 테이블의 `title`, `event_date`, `location`, `status` 컬럼 변경 시 트리거 발동.
- **수신자 타겟팅:** `event_applications` 테이블에서 해당 이벤트의 신청자(status: `approved`, `pending`) 목록 조회.
- **알림 발송:** PGMQ `q_notifications`에 메시지 발행 -> (Worker가 처리).

## 3. 알림 정책
- **트리거 조건:**
    - 제목 변경
    - 날짜/시간 변경
    - 장소 변경
    - 파티 상태 변경 (예: 취소됨)
- **메시지 포맷:**
    - 제목: "[이벤트 업데이트] {이벤트명}"
    - 내용: "주최자가 이벤트 정보를 업데이트했습니다. 변경된 내용을 확인해보세요." (또는 변경된 필드 명시)
    - 딥링크: `/events/{eventId}`

## 4. 기술 스택
- PostgreSQL (PL/pgSQL Trigger)
- Supabase PGMQ extension

## 5. 수락 기준
- [ ] 이벤트 제목이나 날짜를 수정하면, 신청자들의 `user_notifications` 테이블에 알림이 생성되어야 함.
- [ ] 동시에 FCM 푸시 알림이 발송되어야 함 (Worker 로그 확인).
