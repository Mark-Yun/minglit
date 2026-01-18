# 계획: 앱 단위 테스트 및 CI 파이프라인 구축

## Phase 1: 테스트 환경 구축 및 기본 유틸리티 [checkpoint: 7ba27e1]
- [x] Task: 테스트 의존성 추가 (`app_user`) (7ba27e1)
    - [x] `mocktail` 패키지 추가.
- [x] Task: 테스트 Base 설정 및 Helper 작성 (7ba27e1)
    - [x] Riverpod `ProviderContainer` 초기화 유틸리티 작성.
    - [x] 전용 Mock 클래스 정의 (Repository 가짜 객체).
- [x] Task: Conductor - User Manual Verification 'Phase 1: 테스트 환경 작동 확인' (Protocol in workflow.md) (7ba27e1)

## Phase 2: 핵심 컨트롤러 단위 테스트 작성 [checkpoint: 7ba27e1]
- [x] Task: `AuthController` 테스트 작성 (7ba27e1)
    - [x] 로그인 성공/실패 시 상태 변화 및 Repository 호출 검증.
- [x] Task: `EventDetailController` 테스트 작성 (7ba27e1)
    - [x] 데이터 로드 및 에러 상태 분기 테스트.
- [x] Task: `EventAdmissionController` 테스트 작성 (7ba27e1)
    - [x] **중점:** 나이/성별 미달, 인증 필요 등 복잡한 조건부 로직 전수 검사.
- [x] Task: Conductor - User Manual Verification 'Phase 2: 로컬 테스트 실행' (Protocol in workflow.md) (7ba27e1)

## Phase 3: GitHub Actions CI 통합 [checkpoint: 7ba27e1]
- [x] Task: CI 워크플로우 파일 생성/수정 (`ci.yml`) (7ba27e1)
    - [x] PR 및 Push 트리거 설정.
    - [x] 린트(`flutter analyze`) 및 테스트 실행 단계 구현.
- [x] Task: Conductor - User Manual Verification 'Phase 3: CI 연동 및 PR 테스트' (Protocol in workflow.md) (7ba27e1)
