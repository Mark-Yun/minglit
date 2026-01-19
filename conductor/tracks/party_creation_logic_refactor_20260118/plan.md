# 계획: 파티 생성 시 최대 인원 로직 개선 및 티켓 수량 통합

## Phase 1: 데이터베이스 트리거 및 제약조건 구현
- [ ] Task: 최대 인원 자동 동기화 트리거 작성
    - [ ] `backend/supabase/migrations/`에 `tickets` 테이블 변경 시 `parties` 및 `events`의 `max_participants`를 합산 업데이트하는 PL/pgSQL 함수 및 트리거 추가.
- [ ] Task: 최소/최대 인원 정합성 제약조건 추가
    - [ ] `min_confirmed_count`가 `max_participants`를 초과할 수 없도록 하는 체크 제약조건(Check Constraint) 추가.
- [ ] Task: 백엔드 통합 테스트 작성 및 검증 (`backend_integration`)
    - [ ] 티켓 추가/삭제/수정 시 `max_participants` 값이 의도대로 변하는지 TDD 방식으로 검증.
- [ ] Task: Conductor - User Manual Verification 'Phase 1: DB 자동 동기화 확인' (Protocol in workflow.md)

## Phase 2: 시더(Seeder) 및 통합 테스트 인프라 업데이트
- [ ] Task: `DatabaseSeeder` 로직 수정
    - [ ] `tests/test_data_seeder`의 시딩 데이터 생성 시, 임의의 인원수 대신 티켓 수량에 맞춰 `max_participants`가 설정되도록 수정.
- [ ] Task: 시더 실행 및 정합성 검사
    - [ ] 시딩 후 모든 파티/이벤트의 데이터가 새로운 규칙을 만족하는지 확인.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: 시더 데이터 무결성 확인' (Protocol in workflow.md)

## Phase 3: 파트너 앱 UI/UX 리팩토링 (`app_partner`)
- [ ] Task: 파티 생성 위저드에서 최대 인원 입력란 제거
    - [ ] `PartyCreateWizard` 내 관련 단계의 텍스트 필드 삭제 및 UI 레이아웃 조정.
- [ ] Task: 티켓 수량 실시간 합계 UI 구현
    - [ ] 티켓 설정 화면에서 각 티켓 수량의 총합을 "총 수용 인원: N명"으로 실시간 표시하는 기능 추가.
- [ ] Task: 최소 인원 유효성 검사 강화
    - [ ] 입력한 최소 인원이 티켓 총합을 넘을 경우 경고 및 진행 차단 로직 추가.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: 파트너 앱 생성 플로우 확인' (Protocol in workflow.md)
