# 명세서: 실명 본인인증 시스템 연동 (PASS/SMS)

## 1. 개요
현재 Mock으로 구현된 본인인증 로직을 `PortOne(구 Iamport)` API를 통해 실제 PASS/SMS 본인인증 서비스와 연동합니다. 인증된 사용자의 실명, 생년월일, 성별, 전화번호, CI/DI 값을 `user_profiles`에 저장하여 신뢰 기반 서비스의 핵심 인프라를 완성합니다.

## 2. 주요 기능

### 2.1. PortOne 본인인증 연동
- **위젯:** `IamportCertification` 위젯을 사용하여 모바일(WebView) 및 웹 환경에서 본인인증 창 호출.
- **설정:** `IamportConfig`를 통해 가맹점 식별코드 등 환경변수 관리.
- **플랫폼별 분기:**
    - **Mobile (App):** `portone_flutter` SDK 사용.
    - **Web:** PortOne JS SDK V2 (`requestIdentityVerification`) 연동.

### 2.2. 인증 데이터 처리 및 검증
- **데이터 업데이트:** 인증 성공 시 반환되는 `imp_uid`를 서버로 전송.
- **서버 검증 (Edge Function):**
    - PortOne API로 `imp_uid` 조회하여 위변조 여부 확인.
    - 반환된 `unique_key(CI)`, `unique_in_site(DI)`, 이름, 생년월일, 성별, 전화번호를 추출.
    - `user_profiles` 테이블에 해당 정보를 **신뢰할 수 있는 데이터**로 저장 (`is_verified = true`).

### 2.3. 중복 가입 방지 (Account Linking)
- **CI/DI 조회:** 인증된 CI(Connecting Information)가 이미 DB에 존재하는지 확인.
- **기존 계정 발견 시:**
    - **"이미 가입된 계정이 있습니다."** 다이얼로그 표시.
    - 해당 계정의 이메일 일부(`ma**@gmail.com`)를 보여주고 로그인 화면으로 유도.
    - 현재 세션의 인증 시도는 취소.

### 2.4. UI/UX
- **인증 화면:** `IdentityVerificationScreen`을 실제 연동 로직으로 교체.
- **결과 처리:** 성공 시 스낵바/토스트 피드백 후 화면 닫기.

## 3. 기술 스택 및 아키텍처
- **Client Package:** `minglit_identification` (신규 패키지)
    - **Interface:** `IdentificationProvider`
    - **Implementation:** 조건부 임포트(`dart.library.io` / `dart.library.js`)를 통해 플랫폼별 의존성 분리.
    - **Dependencies:** `portone_flutter` (IO), `webview_flutter` (IO), `js` (Web).
- **Server:** Supabase Edge Function (`verify-identity`).
- **External:** PortOne API V2.

## 4. 수락 기준
- [ ] 유저가 본인인증 버튼을 누르면 PASS/SMS 인증 창이 떠야 함.
- [ ] 인증 완료 후 `user_profiles` 테이블에 `ci`, `di`, `birth_date`, `is_verified: true`가 정확히 저장되어야 함.
- [ ] 이미 인증된 유저가 다른 계정으로 인증을 시도하면 차단하고 안내 메시지를 띄워야 함.
- [ ] 모바일 앱과 웹 브라우저 모두에서 인증 흐름이 정상 동작해야 함.
