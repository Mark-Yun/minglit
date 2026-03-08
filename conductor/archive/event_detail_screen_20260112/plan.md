# 계획: 이벤트 상세 화면 구현

## Phase 1: 데이터 및 상태 관리 [checkpoint: 8aeb735]
- [x] Task: EventDetailController 및 상태 생성 (23d319f)
  - [x] Subtask: `app_user`에 `EventDetailController` 구현
- [x] Task: EventRepository 연동 (dfacabc)
  - [x] Subtask: `EventRepository`에 `getEvent` 메서드가 존재하고 작동하는지 확인
- [x] Task: Conductor - 사용자 수동 검증 'Phase 1: 데이터 및 상태 관리' (workflow.md의 프로토콜 따름)

## Phase 2: 입장 로직 통합 [checkpoint: de45a5d]
- [x] Task: EventAdmissionController 통합 구현 (41dbf70)
  - [x] Subtask: `EventDetailScreen` 로직에 `EventAdmissionController` 연결
- [x] Task: Conductor - 사용자 수동 검증 'Phase 2: 입장 로직 통합' (workflow.md의 프로토콜 따름) (de45a5d)

## Phase 3: UI 구현 [checkpoint: de45a5d]
- [x] Task: 화면 스켈레톤 및 헤더 구축 (de45a5d)
  - [x] Subtask: 히어로 이미지 및 제목 섹션 구현
- [x] Task: 정보 및 조건 섹션 구축 (de45a5d)
  - [x] Subtask: 정보 카드 및 입장 조건 리스트 구현
- [x] Task: 동적 CTA 버튼 구축 (de45a5d)