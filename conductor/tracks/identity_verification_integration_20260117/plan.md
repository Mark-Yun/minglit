# 계획: 실명 본인인증 시스템 연동 (PASS/SMS)

## Phase 1: 백엔드 검증 API 구현
- [ ] Task: Supabase Edge Function (`verify-identity`) 작성
    - [ ] Portone API 호출을 위한 `Deno` 설정 및 시크릿 키 구성.
    - [ ] `imp_uid`를 통해 인증 정보를 조회하고 CI/DI를 추출하는 로직 구현.
    - [ ] DB 내 중복 CI 체크 로직 구현.
- [ ] Task: `IdentityRepository` 확장 (`minglit_kit`)
    - [ ] Mock 로직을 Edge Function 호출 로직으로 교체.
- [ ] Task: Conductor - User Manual Verification 'Phase 1: 서버 연동 및 CI 추출 확인' (Protocol in workflow.md)

## Phase 2: 클라이언트 연동 (`app_user`)
- [ ] Task: PortOne 본인인증 창 구현 (Mobile)
    - [ ] `IdentityVerificationScreen`에 `IamportCertification` 위젯 적용.
    - [ ] 성공/실패 콜백 연동.
- [ ] Task: PortOne 본인인증 창 구현 (Web)
    - [ ] `iamport_helper_web.dart`에 JS SDK V2 호출 로직 구현.
    - [ ] `certification_web.dart` UI 연동.
- [ ] Task: 중복 계정 처리 UI 구현
    - [ ] 기존 CI 발견 시 안내 다이얼로그(`MinglitDialog`) 표시 및 로그인 유도 로직 작성.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: 실제 인증 플로우 테스트' (Protocol in workflow.md)

## Phase 3: 데이터 정합성 및 예외 처리
- [ ] Task: 인증 정보 강제 업데이트 로직
    - [ ] 인증 성공 시 유저 메타데이터와 `user_profiles` 테이블 동기화 보장.
- [ ] Task: 취소 및 타임아웃 예외 처리
    - [ ] 유저가 인증 창을 닫거나 오류 발생 시 적절한 피드백 제공.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: 최종 연동 및 예외 시나리오 확인' (Protocol in workflow.md)
