# Implementation Plan: Client Scenario Integration Test Setup

## Phase 1: Strategy Documentation [checkpoint: 9907e20]
- [x] **Task: Create `tests/TESTING.md`** [9907e20]
- [x] Task: Conductor - User Manual Verification 'Strategy Docs' (Protocol in workflow.md)

## Phase 2: Project Scaffolding
- [ ] **Task: Initialize `apps/integration_scenario_tester`**
    - `flutter create`로 프로젝트 생성.
    - `pubspec.yaml` 설정: `minglit_kit`, `test_data_seeder` 패키지 연결.
    - 불필요한 보일러플레이트 제거 및 최소 `main.dart` 구성.
- [ ] Task: Conductor - User Manual Verification 'Scaffolding' (Protocol in workflow.md)

## Phase 3: Seeder Integration & Base Logic
- [ ] **Task: Setup Test Environment Helper**
    - 테스트 시 Supabase 초기화 및 세션 관리 유틸리티 구현.
    - `test_data_seeder`를 테스트 코드 내에서 호출할 수 있도록 래퍼(Wrapper) 구현.
- [ ] Task: Conductor - User Manual Verification 'Seeder Integration' (Protocol in workflow.md)

## Phase 4: Core Scenarios Implementation
- [ ] **Task: Implement Scenario A (Matching)**
    - 매칭 투표부터 실시간 성사, 연락처 공개까지의 흐름 테스트 코드 작성.
- [ ] **Task: Implement Scenario B (Auth/Signup)**
    - 본인인증(Mock) 후 회원가입 및 프로필 생성 흐름 테스트 코드 작성.
- [ ] Task: Conductor - User Manual Verification 'Core Scenarios' (Protocol in workflow.md)
