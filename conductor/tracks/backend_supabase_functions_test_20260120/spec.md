# 명세서: Backend Supabase Functions 테스트 코드 구현

## 1. 개요
Supabase Edge Functions의 비즈니스 로직을 검증하고, 코드 변경 시 발생할 수 있는 결함을 사전에 방지하기 위해 Deno 기반의 단위 테스트 환경을 구축하고 테스트 코드를 작성합니다.

## 2. 주요 요구 사항

### 2.1. 테스트 환경 구축
- **Deno Test Runner:** `deno test`를 표준 테스트 도구로 사용합니다.
- **Mocking Framework:** `std/testing/mock` 또는 유사한 라이브러리를 사용하여 Supabase 클라이언트 및 외부 HTTP 요청을 Mocking합니다.
- **No-DB Dependency:** 테스트 실행 시 실제 데이터베이스 연결이 필요하지 않도록 설계하여 실행 속도를 높이고 환경 의존성을 제거합니다.

### 2.2. 테스트 대상 함수
- `verify-payment-v1`: 결제 검증 로직, 상태 업데이트 흐름 테스트.
- `notification-worker`: 알림 발송 로직, 템플릿 처리 테스트.
- `vector-worker`: 임베딩 생성 및 저장 로직 테스트.
- `verify-identity-v1/v2`: 본인인증 처리 및 프로필 업데이트 로직 테스트.
- 기타 `functions` 폴더 내의 유틸리티 및 공유 함수.

### 2.3. 테스트 케이스 구성
- **성공 케이스 (Happy Path):** 유효한 입력에 대해 예상되는 올바른 응답 및 동작 확인.
- **에러 케이스 (Edge Cases):** 잘못된 파라미터, 권한 없음, 외부 API 실패 시의 예외 처리 검증.

## 3. 기술 설계 (Technical Approach)
- **파일 구조:** 각 함수 폴더 내에 `[function_name]_test.ts` 또는 `tests/` 폴더를 생성하여 관리합니다.
- **CI 연동:** GitHub Actions에서 린트 체크와 함께 `deno test`가 자동으로 실행되도록 구성 기반을 마련합니다.

## 4. 수락 기준 (Acceptance Criteria)
- [ ] 모든 핵심 Edge Functions에 대해 최소 1개 이상의 유효한 테스트 파일이 존재함.
- [ ] `deno test` 명령어 실행 시 모든 테스트가 성공적으로 통과함.
- [ ] 실제 DB 연결 없이 독립적으로 테스트가 실행됨.
- [ ] 외부 API(결제 등) 호출 부가 적절히 Mocking되어 있음.

## 5. 제외 범위 (Out of Scope)
- 실제 Supabase DB 인스턴스를 활용한 통합 테스트.
- 실제 외부 서비스(Portone, FCM 등)와의 통신 테스트.
