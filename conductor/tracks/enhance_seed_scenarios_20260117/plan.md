# 계획: 시딩 데이터 다양화 및 시나리오 강화

## Phase 1: 시더 로직 개선 및 유저 생성 [checkpoint: 00b3938]
- [x] Task: `DatabaseSeeder.dart` 리팩토링 (00b3938)
    - [x] `_seedPersonas` 메서드 구현: 20~50세 연령별 유저 생성 로직 작성.
    - [x] 유저 상태(인증 여부, 정보 누락 등)에 따른 메타데이터 생성 로직 추가.
- [x] Task: 유저 검증 데이터 주입 (00b3938)
    - [x] 생성된 유저 중 `_ok` 그룹에게 `user_verifications` 데이터 주입. (본인인증은 프로필 레벨로 이관, 파트너 인증은 보류)
    - [x] 일부 유저에게 `partner_verified_users` 자격 증명 주입. (Phase 2로 이관 또는 보류)
- [x] Task: Conductor - 사용자 수동 검증 'Phase 1: 유저 시딩 확인' (Protocol in workflow.md) (00b3938)

## Phase 2: 파티 및 입장 조건 시나리오 구현
- [ ] Task: `seed.sql` 보강
    - [ ] `verifications` 정의(직장, 학력, 자산 등) 정교화 및 아이콘 매핑.
- [ ] Task: 시나리오별 파티 생성 로직 구현 (`_seedScenarioParties`)
    - [ ] 대학생, 직장인, 노블레스, 동네친구 파티 생성.
    - [ ] 각 파티에 맞는 `EntryGroup` 및 `Ticket` 생성.
- [ ] Task: Conductor - 사용자 수동 검증 'Phase 2: 파티 시나리오 확인' (Protocol in workflow.md)

## Phase 3: 테스트 코드 마이그레이션
- [ ] Task: 기존 테스트 코드 수정 (`backend_integration`)
    - [ ] `apply_event_flow_test.dart` 등에서 `user_1` 대신 조건에 맞는 페르소나 유저를 조회하도록 수정.
    - [ ] `created_at` 정렬을 사용하여 안정적인 테스트 유저 조회 로직 적용.
- [ ] Task: 전체 테스트 실행 및 Green 확인
- [ ] Task: Conductor - 사용자 수동 검증 'Phase 3: 테스트 안정성 확인' (Protocol in workflow.md)
