# 계획: 이벤트 업데이트 알림 자동화

## Phase 1: DB 트리거 구현
- [x] Task: 알림 발송 함수(`notify_event_update`) 작성
    - [x] 변경된 컬럼 감지 로직.
    - [x] 신청자(`event_applications`) 조회 커서(Loop).
    - [x] `pgmq_send` 호출 로직.
- [x] Task: `events` 테이블에 트리거 부착
    - [x] `AFTER UPDATE` 트리거 설정.

## Phase 2: 테스트 및 검증
- [x] Task: 마이그레이션 파일 생성 및 적용 (`..._notify_trigger.sql`).
- [x] Task: 수동 테스트 (SQL Editor)
    - [x] 테스트 이벤트 생성 및 유저 신청.
    - [x] 이벤트 정보 수정.
    - [x] `q_notifications` 및 `user_notifications` 확인.
