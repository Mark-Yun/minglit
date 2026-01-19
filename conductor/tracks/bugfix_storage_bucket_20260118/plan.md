# 계획: 주요 버그 수정: 인증 파일 업로드 에러

## Phase 1: 문제 재현 및 검증 테스트 구축 (TDD)
- [ ] Task: 스토리지 버킷 검증용 통합 테스트 작성 (`backend_integration`)
    - [ ] `tests/backend_integration/src/infrastructure/storage_policy_test.dart` 생성.
    - [ ] RLS 정책 및 버킷 존재 여부 확인 (Backend Level).
- [ ] Task: 앱 시나리오 테스트 작성 (`integration_scenario_tester`)
    - [ ] `apps/integration_scenario_tester/integration_test/scenarios/s01_auth/s01_03_verification_upload_test.dart` 생성.
    - [ ] 실제 유저 플로우(로그인 -> 인증 화면 -> 파일 선택 -> 업로드)를 시뮬레이션하여 404 에러 재현.
- [ ] Task: Conductor - User Manual Verification 'Phase 1: 테스트 실패 확인 (Bug Detection)' (Protocol in workflow.md)

## Phase 2: 스토리지 설정 및 마이그레이션 적용
- [ ] Task: SQL 마이그레이션 파일 작성 (`backend/supabase/migrations/`)
    - [ ] 버킷 생성 SQL (`storage.buckets` 삽입).
    - [ ] 스토리지 RLS 정책 정의 (업로드/조회 권한 분리).
- [ ] Task: 로컬 환경 반영 및 테스트 검증
    - [ ] `supabase db reset` 실행.
    - [ ] Phase 1에서 작성한 **모든 테스트(Backend + App Scenario)**를 재실행하여 통과 확인.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: 테스트 통과 및 로컬 환경 확인' (Protocol in workflow.md)

## Phase 3: 유저 앱 연동 확인 및 마무리
- [ ] Task: 유저 앱 실제 동작 테스트
    - [ ] `app_user` 실행 후 실제 파일 업로드 수행.
    - [ ] Supabase Dashboard에서 파일이 생성된 버킷에 잘 저장되는지 확인.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: 실제 앱 업로드 성공 확인' (Protocol in workflow.md)
