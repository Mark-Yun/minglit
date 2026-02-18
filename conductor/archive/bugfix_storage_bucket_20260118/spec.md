# 명세서: 주요 버그 수정: 인증 파일 업로드 에러

## 1. 개요
유저 앱에서 자격 심사 신청 시 파일 업로드가 실패하는 문제(Issue #4: `Bucket not found`)를 해결합니다. `verification-proofs` 스토리지 버킷을 생성하고, 적절한 접근 권한(RLS 정책)을 설정하여 안정적인 파일 업로드 환경을 구축합니다.

## 2. 문제 정의 및 원인
- **증상:** `MinglitFilePicker`를 통해 파일 업로드 시 `StorageException(message: Bucket not found, statusCode: 404)` 발생.
- **원인:** Supabase 프로젝트(로컬 및 리모트)에 `verification-proofs`라는 이름의 스토리지 버킷이 생성되어 있지 않거나, 익명/인증 유저에 대한 쓰기 권한이 설정되지 않음.

## 3. 해결 방안 (Scope)

### 3.1. 스토리지 버킷 생성 및 정책 설정
- **Migration 파일 작성:** `supabase/migrations/` 경로에 SQL 마이그레이션 파일을 추가하여 다음을 수행합니다:
    1.  `verification-proofs` 버킷 생성 (존재하지 않을 경우).
    2.  버킷을 `private`으로 설정 (보안 강화).
    3.  **RLS 정책 추가:**
        -   `INSERT`: 인증된 유저(`auth.uid()`)만 자신의 폴더에 업로드 가능.
        -   `SELECT`: 파트너(매니저) 및 본인만 조회 가능.

### 3.2. 검증 (Verification)
- **TDD 접근:**
    1.  `tests/backend_integration`: 백엔드 레벨에서 버킷 존재 및 RLS 정책 검증.
    2.  `apps/integration_scenario_tester`: 클라이언트 시나리오 레벨에서 실제 업로드 플로우 검증.

## 4. 수락 기준 (Acceptance Criteria)
- [ ] `supabase db reset` 수행 시 자동으로 `verification-proofs` 버킷이 생성되어야 함.
- [ ] 백엔드 통합 테스트(`storage_policy_test.dart`)가 통과해야 함.
- [ ] 클라이언트 시나리오 테스트(`s01_03_verification_upload_test.dart`)가 통과해야 함.
- [ ] 유저 앱에서 실제 파일 업로드 시 404 에러 없이 성공하고, 올바른 URL을 반환해야 함.
