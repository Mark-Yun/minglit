# 계획: 백엔드 통합 테스트 강화 (Backend Test Enhancement)

## Phase 1: 테스트 환경 정비 및 기존 파일 이관 [checkpoint: e6f2aac]
- [x] Task: 디렉토리 구조 생성
    - [x] `user/`, `partner/`, `party/`, `admission/`, `system/` 폴더 생성.
- [x] Task: 기존 테스트 파일 이관 및 리팩토링
    - [x] `apply_event_flow_test.dart` -> `admission/submission_flow_test.dart` 이동 및 정리.
    - [x] `sql_functions_test.dart` -> `user/action_trigger_test.dart` (일부) 및 `system/`으로 분산 이관.
    - [x] `verify_db_extensions_test.dart` -> `system/schema_health_test.dart` 통합.
- [x] Task: Conductor - 사용자 수동 검증 'Phase 1: 테스트 환경 정비' (Protocol in workflow.md)

## Phase 2: Admission & Security 테스트 강화 (최우선)
- [ ] Task: `admission/application_rls_test.dart` 구현
- [ ] Task: `admission/auto_approval_trigger_test.dart` 구현
- [ ] Task: `user/profile_rls_test.dart` 구현
- [ ] Task: 코드 품질 강화 (Zero-Warning 루프)
- [ ] Task: Conductor - 사용자 수동 검증 'Phase 2: 보안 및 신청 로직 검증' (Protocol in workflow.md)

## Phase 3: Party & Partner 도메인 테스트 구현
- [ ] Task: `party/party_rls_test.dart` 구현
- [ ] Task: `party/event_constraints_test.dart` 구현
- [ ] Task: `partner/permission_policy_test.dart` 구현
- [ ] Task: `partner/verification_manage_test.dart` 구현
- [ ] Task: 코드 품질 강화 (Zero-Warning 루프)
- [ ] Task: Conductor - 사용자 수동 검증 'Phase 3: 파티 및 파트너 권한 검증' (Protocol in workflow.md)

## Phase 4: 시스템 건전성 및 파이프라인 검증
- [ ] Task: `system/schema_health_test.dart` 고도화 (인덱스 체크 포함)
- [ ] Task: `system/pipeline_robustness_test.dart` 구현 (멱등성)
- [ ] Task: 전체 테스트 통합 실행 및 Green 확인
- [ ] Task: Conductor - 사용자 수동 검증 'Phase 4: 전체 시스템 안정성 확인' (Protocol in workflow.md)
