# 명세서: 백엔드 통합 테스트 강화 (Backend Test Enhancement)

## 1. 개요
Supabase(PostgreSQL) 기반 아키텍처의 신뢰성을 확보하기 위해 도메인별로 세분화된 통합 테스트 스위트를 구축합니다. RLS 보안, 데이터 무결성, 비즈니스 로직(트리거), 스키마 건전성을 포괄적으로 검증합니다.

## 2. 테스트 목표
- **빈틈없는 보안 검증:** 모든 테이블에 대해 권한 없는 접근(조회/수정/삭제)이 차단되는지 확인.
- **견고한 데이터 무결성:** 비즈니스 규칙에 어긋나는 데이터(음수 값, 날짜 오류 등)가 DB 레벨에서 거부되는지 확인.
- **정확한 로직 실행:** 복잡한 트리거 연쇄 작용(신청->승인->발권)이 예외 상황에서도 정확히 동작하는지 확인.

## 3. 상세 테스트 구조 (Directory & Files)
`tests/backend_integration/src/` 내부에 다음 구조로 테스트를 구현합니다.

### 3.1. User Domain (`/user`)
- **`profile_rls_test.dart`**:
    - 본인 프로필 수정 성공.
    - 타인 프로필 수정 실패 (RLS Error).
    - `is_verified` 등 민감한 필드 직접 수정 시도 실패.
- **`action_trigger_test.dart`**:
    - `user_actions` INSERT 시 `q_vectors` 큐에 이벤트 발행 확인.

### 3.2. Partner Domain (`/partner`)
- **`permission_policy_test.dart`**:
    - Owner: 파트너 정보 수정, 멤버 추가 가능.
    - Staff: 파트너 정보 수정 불가, 멤버 추가 불가.
    - Outsider: 파트너 내부 데이터 접근 불가.
- **`verification_manage_test.dart`**:
    - 파트너가 `verifications` 생성/수정/삭제 가능 여부.

### 3.3. Party & Event Domain (`/party`)
- **`party_rls_test.dart`**:
    - 호스트만 파티/이벤트 수정 가능.
    - 공개(`active`) 파티는 누구나 조회 가능, 초안(`draft`)은 호스트만 조회.
- **`event_constraints_test.dart`**:
    - `start_time` > `end_time` 입력 시 에러.
    - `max_participants` 음수 입력 시 에러.
    - `price` 음수 입력 시 에러.
- **`ticket_concurrency_test.dart`**:
    - 티켓 발권 시 `sold_count` 증가 확인.
    - (가능하다면) 재고 초과 발권 시도 시 차단 확인.

### 3.4. Admission Domain (`/admission`)
- **`application_rls_test.dart`**:
    - 본인 신청서만 조회 가능.
    - 타인 신청서 조회/수정 불가.
- **`submission_flow_test.dart`**:
    - (기존 `apply_event_flow_test` 고도화) 원샷 신청, 심사, 승인 전체 흐름.
- **`auto_approval_trigger_test.dart`**:
    - `verification_submissions` 상태 변경 시 `event_applications` 및 `partner_verified_users` 연동 동작 정밀 검증.

### 3.5. System Domain (`/system`)
- **`schema_health_test.dart`**:
    - 핵심 테이블 및 컬럼 존재 여부.
    - 성능 필수 인덱스(`geo_point` GIST 등) 존재 여부.
- **`pipeline_robustness_test.dart`**:
    - 멱등성(Idempotency): 동일 이벤트 중복 처리 시도 시 무시.

## 4. 기술적 요구사항
- **가짜 JWT 활용:** `dart_jsonwebtoken`으로 다양한 역할(User, Owner, Admin)의 토큰을 즉석에서 생성하여 테스트.
- **시딩 데이터 활용:** `test_data_seeder`로 생성된 데이터를 조회하여 테스트 베이스로 활용.
- **TestDatabase 유틸:** DB 연결 설정 중앙화 (`utils/test_database.dart`).

## 5. 작업 순서
1.  기존 테스트 파일 정리 (`apply_event_flow_test` -> `admission/submission_flow_test`로 이동 등).
2.  도메인별 폴더 생성.
3.  각 도메인별 테스트 파일 구현 (우선순위: Admission > User > Party > Partner).
