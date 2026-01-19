# 계획: 실명 본인인증 시스템 연동 (PASS/SMS)

## Phase 1: `minglit_identification` 패키지 구축 (아키텍처)
- [ ] Task: 패키지 스캐폴딩 및 설정
    - [ ] `shared/packages/minglit_identification` 생성.
    - [ ] `pubspec.yaml` 설정 (플랫폼별 의존성 분리 준비).
- [ ] Task: 조건부 임포트 구조 구현
    - [ ] `src/interface/identification_provider.dart` (추상 클래스 정의).
    - [ ] `src/implementation/identification_stub.dart` (Stub).
    - [ ] `src/implementation/identification_io.dart` (`portone_flutter` 의존).
    - [ ] `src/implementation/identification_web.dart` (Web JS Interop).
    - [ ] `minglit_identification.dart` (export 설정).
- [ ] Task: Conductor - User Manual Verification 'Phase 1: 패키지 구조 및 임포트 확인' (Protocol in workflow.md)

## Phase 2: 백엔드 검증 API 구현
- [ ] Task: Supabase Edge Function (`verify-identity`) 작성
    - [ ] Portone API 호출을 위한 `Deno` 설정 및 시크릿 키 구성.
    - [ ] `imp_uid`를 통해 인증 정보를 조회하고 CI/DI를 추출하는 로직 구현.
    - [ ] DB 내 중복 CI 체크 로직 구현.
- [ ] Task: `IdentityRepository` 확장 (`minglit_kit`)
    - [ ] Mock 로직을 Edge Function 호출 로직으로 교체.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: 서버 연동 및 CI 추출 확인' (Protocol in workflow.md)

## Phase 3: 클라이언트 UI 및 로직 연동
- [ ] Task: IO (Mobile) 구현 (`identification_io.dart`)
    - [ ] `IamportCertification` 위젯을 래핑하거나 호출 로직 구현.
- [ ] Task: Web 구현 (`identification_web.dart`)
    - [ ] PortOne JS SDK V2 연동 (IFrame/Redirect).
- [ ] Task: UI 연동 (`IdentityVerificationScreen`)
    - [ ] `minglit_identification` 패키지를 사용하여 인증 창 호출.
    - [ ] 성공 시 `IdentityRepository`를 통해 서버 검증 요청.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: E2E 인증 테스트' (Protocol in workflow.md)
