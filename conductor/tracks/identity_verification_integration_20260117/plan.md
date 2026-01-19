# 계획: 실명 본인인증 시스템 연동 (PASS/SMS)

## Phase 1: `minglit_identification` 패키지 구축 (아키텍처)
- [x] Task: 패키지 스캐폴딩 및 설정 e58ec02
    - [x] `shared/packages/minglit_identification` 생성.
    - [x] `pubspec.yaml` 설정 (플랫폼별 의존성 분리 준비).
- [x] Task: 조건부 임포트 구조 구현 e58ec02
    - [x] `src/interface/identification_provider.dart` (추상 클래스 정의).
    - [x] `src/implementation/identification_stub.dart` (Stub).
    - [x] `src/implementation/identification_io.dart` (`portone_flutter` 의존).
    - [x] `src/implementation/identification_web.dart` (Web JS Interop).
    - [x] `minglit_identification.dart` (export 설정).
- [x] Task: Conductor - User Manual Verification 'Phase 1: 패키지 구조 및 임포트 확인' (Protocol in workflow.md)

## Phase 2: 백엔드 검증 API 구현
- [x] Task: Supabase Edge Function (`verify-identity`) 작성 e58ec02
    - [x] Portone API 호출을 위한 `Deno` 설정 및 시크릿 키 구성.
    - [x] `imp_uid`를 통해 인증 정보를 조회하고 CI/DI를 추출하는 로직 구현.
    - [x] DB 내 중복 CI 체크 로직 구현.
- [x] Task: `IdentityRepository` 확장 (`minglit_kit`) e58ec02
    - [x] Mock 로직을 Edge Function 호출 로직으로 교체.
- [x] Task: Conductor - User Manual Verification 'Phase 2: 서버 연동 및 CI 추출 확인' (Protocol in workflow.md)

## Phase 3: 클라이언트 UI 및 로직 연동
- [x] Task: IO (Mobile) 구현 (`identification_io.dart`) e58ec02
    - [x] `IamportCertification` 위젯을 래핑하거나 호출 로직 구현.
- [x] Task: Web 구현 (`identification_web.dart`) e58ec02
    - [x] PortOne JS SDK V2 연동 (IFrame/Redirect).
- [x] Task: UI 연동 (`IdentityVerificationScreen`) e58ec02
    - [x] `minglit_identification` 패키지를 사용하여 인증 창 호출.
    - [x] 성공 시 `IdentityRepository`를 통해 서버 검증 요청.
- [x] Task: Conductor - User Manual Verification 'Phase 3: E2E 인증 테스트' (Protocol in workflow.md)
