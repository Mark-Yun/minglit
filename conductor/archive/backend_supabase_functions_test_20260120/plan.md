# 계획: Backend Supabase Functions 테스트 코드 구현

## Phase 1: 테스트 환경 설정 및 공통 모듈 작성
- [ ] Task: Deno 테스트 설정 확인 및 문서화
    - [ ] `deno.json` 설정 검토 및 테스트 태스크 추가.
- [ ] Task: 공통 Mocking 유틸리티 작성
    - [ ] `supabase/functions/_shared/tests/` 폴더 생성.
    - [ ] Supabase Client Mock (`mockSupabaseClient.ts`) 구현: DB 쿼리 메서드(`from`, `select`, `eq`, `update` 등)를 체이닝할 수 있는 Mock 클래스 작성.
    - [ ] Fetch Mock 유틸리티 구현: 외부 API 호출 가로채기 위한 헬퍼 함수.
- [ ] Task: Conductor - User Manual Verification 'Phase 1: 테스트 실행 환경 확인' (Protocol in workflow.md)

## Phase 2: 핵심 비즈니스 로직 테스트 구현
- [ ] Task: `verify-payment-v1` 테스트 작성
    - [ ] 결제 검증 성공 시나리오 테스트.
    - [ ] 결제 금액 불일치 등 실패 시나리오 테스트.
- [ ] Task: `verify-identity-v1` & `v2` 테스트 작성
    - [ ] 본인인증 데이터 파싱 및 프로필 업데이트 로직 테스트.
- [ ] Task: `notification-worker` 테스트 작성
    - [ ] 알림 큐 처리 로직 및 FCM 페이로드 생성 테스트.
- [ ] Task: `vector-worker` 테스트 작성
    - [ ] 텍스트 임베딩 생성 요청 및 벡터 저장 로직 테스트.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: 핵심 함수 테스트 통과' (Protocol in workflow.md)

## Phase 3: 기타 함수 및 CI 연동
- [ ] Task: 나머지 유틸리티 함수 테스트 작성
    - [ ] `_shared/` 내의 유틸리티 함수 단위 테스트.
    - [ ] `portone-webhook-v1` 등 기타 함수 테스트.
- [ ] Task: 전체 테스트 실행 및 리팩토링
    - [ ] 모든 함수에 대해 `deno test` 실행 및 통과 확인.
    - [ ] 중복된 Mock 코드 제거 및 최적화.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: 전체 테스트 스위트 완성' (Protocol in workflow.md)
