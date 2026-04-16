# CI/CD 배포 파이프라인 테스트 케이스

> 목적: 배포 워크플로우에 필요한 Secret/환경 설정이 누락 없이 구성되어 있는지 검증.
> Secret 미설정으로 인한 배포 실패(#1433, #1434)를 사전에 탐지한다.
>
> 검증 주체: CI 워크플로우 자체 (self-validating) + 수동 체크리스트

---

## 1. 배포 워크플로우별 필수 Secret 매트릭스

### 1.1 Android 배포 (Reusable: `android-deploy-reusable.yml`)

| Secret | User (`android-deploy.yml`) | Partner (`android-deploy-partner.yml`) | 용도 |
|--------|:---:|:---:|------|
| `ANDROID_KEYSTORE_BASE64` | **필수** | **필수** | 서명용 keystore (base64) |
| `ANDROID_KEYSTORE_PASSWORD` | **필수** | **필수** | keystore 비밀번호 |
| `ANDROID_KEY_PASSWORD` | **필수** | **필수** | key 비밀번호 |
| `ANDROID_KEY_ALIAS` | **필수** | **필수** | key alias |
| `SUPABASE_DEV_URL` | **필수** | **필수** | dev 환경 Supabase URL |
| `SUPABASE_DEV_PUBLISHABLE_KEY` | **필수** | **필수** | dev 환경 Supabase key |
| `SUPABASE_MAIN_URL` | **필수** | **필수** | prod 환경 Supabase URL |
| `SUPABASE_MAIN_PUBLISHABLE_KEY` | **필수** | **필수** | prod 환경 Supabase key |
| `SENTRY_DSN_FLUTTER` | **필수** | **필수** | Sentry 에러 리포팅 DSN |
| `FIREBASE_APP_ID_ANDROID` | **필수** (DEV) | **필수** (PARTNER_DEV) | Firebase App Distribution ID |
| `FIREBASE_SERVICE_ACCOUNT_JSON_DEV` | **필수** | **필수** | Firebase 서비스 계정 |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | **필수** | **필수** | Google Play 업로드 |
| `JUSO_CONFIRM_KEY` | 선택 | **필수** | 행정안전부 도로명주소 API 키 |

> **주의**: `JUSO_CONFIRM_KEY`는 reusable workflow에서 `required: false`로 선언되어 있지만, partner 앱 빌드 시 `Validate JUSO key for partner` 스텝에서 빈 값이면 **빌드 실패**한다. 이 불일치가 #1433/#1434의 근본 원인이었다.

### 1.2 iOS 배포 (Action: `.github/actions/ios-deploy/`)

| Secret | User (`ios-deploy-user.yml`) | Partner (`ios-deploy-partner.yml`) | 용도 |
|--------|:---:|:---:|------|
| `APPLE_CERTIFICATE_BASE64` | **필수** | **필수** | Apple 서명 인증서 |
| `APPLE_CERTIFICATE_PASSWORD` | **필수** | **필수** | 인증서 비밀번호 |
| `APPLE_PROVISION_PROFILE_*_DEV_BASE64` | **필수** (USER) | **필수** (PARTNER) | dev 프로비저닝 프로파일 |
| `APPLE_PROVISION_PROFILE_*_BASE64` | **필수** (USER) | **필수** (PARTNER) | prod 프로비저닝 프로파일 |
| `APP_STORE_CONNECT_API_KEY_BASE64` | **필수** | **필수** | App Store Connect API 키 |
| `APP_STORE_CONNECT_API_KEY_ID` | **필수** | **필수** | API 키 ID |
| `APP_STORE_CONNECT_ISSUER_ID` | **필수** | **필수** | 발급자 ID |
| `SUPABASE_DEV_URL` | **필수** | **필수** | dev 환경 Supabase URL |
| `SUPABASE_DEV_PUBLISHABLE_KEY` | **필수** | **필수** | dev 환경 Supabase key |
| `SUPABASE_MAIN_URL` | **필수** | **필수** | prod 환경 Supabase URL |
| `SUPABASE_MAIN_PUBLISHABLE_KEY` | **필수** | **필수** | prod 환경 Supabase key |
| `KAKAO_LOCAL_REST_API_KEY` | **필수** | **필수** | 카카오 로컬 REST API |
| `JUSO_CONFIRM_KEY` | 선택 | **필수** | 행정안전부 도로명주소 API 키 |
| `SENTRY_DSN_FLUTTER` | **필수** | **필수** | Sentry DSN |

---

## 2. 테스트 시나리오

### 2.1 Secret 존재 검증 (수동 체크리스트)

Secret 추가/변경 시 아래 체크리스트로 검증한다:

| # | 검증 항목 | 명령어 | 기대 결과 |
|---|----------|--------|-----------|
| CD-C01 | 전체 Secret 목록 확인 | `gh secret list` | 아래 §3 필수 Secret 전부 존재 |
| CD-C02 | Partner 전용 Secret 확인 | `gh secret list \| grep JUSO` | `JUSO_CONFIRM_KEY` 존재 |
| CD-C03 | Firebase App ID 구분 | `gh secret list \| grep FIREBASE_APP_ID` | `_DEV`, `_PARTNER_DEV` 각각 존재 |
| CD-C04 | Provisioning Profile 구분 | `gh secret list \| grep PROVISION` | `_USER_DEV`, `_USER`, `_PARTNER_DEV`, `_PARTNER` 각각 존재 |

### 2.2 CI 자체 검증 스텝 (워크플로우 내장)

| # | 워크플로우 | 스텝 | 트리거 조건 | 기대 동작 | 실패 시 |
|---|-----------|------|-----------|-----------|---------|
| CD-V01 | `android-deploy-reusable.yml` | `Validate JUSO key for partner` | `app-name == 'partner'` | `JUSO_CONFIRM_KEY` 비어있으면 exit 1 | 빌드 중단 + 에러 메시지 |
| CD-V02 | `.github/actions/ios-deploy/` | `Validate JUSO key for partner` | `app-name == 'partner'` | 동일 | 빌드 중단 + 에러 메시지 |
| CD-V03 | `android-deploy-reusable.yml` | `Decode Keystore` | 항상 | keystore base64 디코딩 성공 | 서명 실패 → 빌드 에러 |
| CD-V04 | `ios-deploy` action | `Import signing certificate` | 항상 | 인증서 임포트 성공 | codesign 실패 |
| CD-V05 | `ios-deploy` action | `Install provisioning profile` | 항상 | UUID 추출 + 설치 성공 | 아카이브 실패 |

### 2.3 배포 실패 알림 검증

| # | 시나리오 | 트리거 | 기대 결과 |
|---|----------|--------|-----------|
| CD-N01 | Android Partner 빌드 실패 | `build` job 실패 | `notify-failure.yml` → 이슈 자동 생성 |
| CD-N02 | iOS Partner 빌드 실패 | `ios-deploy` job 실패 | `notify-failure.yml` → 이슈 자동 생성 |
| CD-N03 | Android User 빌드 성공 | `build` job 성공 | 알림 이슈 미생성 |
| CD-N04 | iOS User 빌드 성공 | `ios-deploy` job 성공 | 알림 이슈 미생성 |

### 2.4 환경별 빌드 분기 검증

| # | 시나리오 | 브랜치 | 기대 빌드 산출물 |
|---|----------|--------|-----------------|
| CD-B01 | Android dev 빌드 | `dev` | APK (dev flavor, `--release`) + Firebase App Distribution 업로드 |
| CD-B02 | Android prod 빌드 | `main` | AAB (prod flavor, `--release`) + Google Play internal 업로드 |
| CD-B03 | iOS dev 빌드 | `dev` | IPA (dev bundle ID `.dev` 접미사) + TestFlight |
| CD-B04 | iOS prod 빌드 | `main` | IPA (prod bundle ID) + App Store Connect |
| CD-B05 | iOS dev URL scheme (user only) | `dev` + `app_user` | `minglit-dev://` scheme 추가 |
| CD-B06 | iOS dev URL scheme (partner) | `dev` + `app_partner` | URL scheme 미추가 |

---

## 3. 필수 Secret 전체 목록 (운영 체크리스트)

새 환경 셋업 또는 Secret 로테이션 시 아래 목록을 확인한다:

### 공통 (User + Partner)

| Secret | 설명 |
|--------|------|
| `ANDROID_KEYSTORE_BASE64` | Android 서명 keystore |
| `ANDROID_KEYSTORE_PASSWORD` | keystore 비밀번호 |
| `ANDROID_KEY_PASSWORD` | key 비밀번호 |
| `ANDROID_KEY_ALIAS` | key alias |
| `APPLE_CERTIFICATE_BASE64` | Apple 서명 인증서 |
| `APPLE_CERTIFICATE_PASSWORD` | 인증서 비밀번호 |
| `APP_STORE_CONNECT_API_KEY_BASE64` | App Store Connect API 키 |
| `APP_STORE_CONNECT_API_KEY_ID` | API 키 ID |
| `APP_STORE_CONNECT_ISSUER_ID` | 발급자 ID |
| `SUPABASE_DEV_URL` | dev Supabase URL |
| `SUPABASE_DEV_PUBLISHABLE_KEY` | dev Supabase publishable key |
| `SUPABASE_MAIN_URL` | prod Supabase URL |
| `SUPABASE_MAIN_PUBLISHABLE_KEY` | prod Supabase publishable key |
| `SENTRY_DSN_FLUTTER` | Sentry DSN |
| `KAKAO_LOCAL_REST_API_KEY` | 카카오 로컬 REST API |
| `FIREBASE_SERVICE_ACCOUNT_JSON_DEV` | Firebase 서비스 계정 |

### 앱별 고유

| Secret | 앱 | 설명 |
|--------|-----|------|
| `FIREBASE_APP_ID_ANDROID_DEV` | User | Firebase App ID (User dev) |
| `FIREBASE_APP_ID_ANDROID_PARTNER_DEV` | Partner | Firebase App ID (Partner dev) |
| `APPLE_PROVISION_PROFILE_USER_DEV_BASE64` | User | iOS dev 프로비저닝 |
| `APPLE_PROVISION_PROFILE_USER_BASE64` | User | iOS prod 프로비저닝 |
| `APPLE_PROVISION_PROFILE_PARTNER_DEV_BASE64` | Partner | iOS dev 프로비저닝 |
| `APPLE_PROVISION_PROFILE_PARTNER_BASE64` | Partner | iOS prod 프로비저닝 |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | 공통 | Google Play 서비스 계정 |
| `JUSO_CONFIRM_KEY` | **Partner 필수** | 행정안전부 도로명주소 API 키 |

---

## 4. 알려진 취약점 및 개선 제안

| # | 취약점 | 영향 | 제안 |
|---|--------|------|------|
| CD-I01 | `JUSO_CONFIRM_KEY`가 reusable workflow에서 `required: false` | Partner 빌드 시 런타임 실패 (빌드 스텝까지 가야 발견) | `required: true`로 변경하거나, partner workflow에서 전달 전 검증 |
| CD-I02 | User 앱에 `JUSO_CONFIRM_KEY` 전달 안 됨 (android-deploy.yml) | User 앱에서 주소 검색 기능 사용 시 빈 값 → 런타임 에러 가능 | User 앱에서 JUSO API 사용 여부 확인 후 필요 시 추가 |
| CD-I03 | Secret 만료 모니터링 없음 | Apple 인증서/프로비저닝 만료 시 배포 중단 | 인증서 만료일 체크 워크플로우 추가 (월 1회 cron) |

---

## 5. 총 테스트 케이스 수

| 구분 | 수량 |
|------|------|
| Secret 존재 검증 (수동) | 4 |
| CI 자체 검증 스텝 | 5 |
| 배포 실패 알림 검증 | 4 |
| 환경별 빌드 분기 검증 | 6 |
| **합계** | **19** |
