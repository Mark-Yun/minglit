# 명세서: iOS 앱 빌드 및 CI/CD 환경 구축

## 1. 개요
Minglit iOS 애플리케이션의 배포 프로세스를 자동화하기 위해 Apple Developer 환경을 셋업하고, GitHub Actions(macOS Runner)를 활용한 CI/CD 파이프라인을 구축합니다. 안드로이드와 마찬가지로 `dev`(TestFlight)와 `main`(App Store 심사 제출) 파이프라인을 분리하여 관리합니다.

## 2. 필수 전제 조건 (Prerequisites)
- **Apple Developer Program 멤버십:** 연 $99 결제가 필요하며, 계정 승인까지 영업일 기준 1~3일 소요될 수 있습니다.
- **macOS 환경:** 로컬 빌드 및 서명 테스트를 위해 필수입니다. (현재 사용자의 OS가 Darwin이므로 충족)

## 3. 주요 기능
### 3.1. 계정 및 인증서 관리
- **Apple Developer Account:** 개발자 프로그램 등록 및 팀 생성.
- **Certificates & Profiles:** 배포용 인증서(Distribution Certificate)와 프로비저닝 프로파일 관리. (수동 관리 또는 Fastlane Match 도입 고려)
- **App Store Connect:** 앱 ID(`com.minglit.app_user`) 등록 및 TestFlight 설정.

### 3.2. iOS 빌드 최적화
- **Xcode 서명 설정:** `dev`(Debug/Profile)와 `prod`(Release) 스키마/타겟 분리 전략 수립.
- **Export Options:** IPA 추출을 위한 `ExportOptions.plist` 구성.

### 3.3. CI/CD 파이프라인 (GitHub Actions)
- **macOS Runner:** iOS 빌드를 위해 `macos-latest` 러너 사용 (GitHub Actions 과금 요소 확인 필요).
- **TestFlight 업로드:** `main` 또는 `dev` 브랜치 푸시 시 TestFlight로 자동 업로드.
- **App Store Connect API:** 2FA(이중 인증) 문제를 피하기 위해 API Key 기반의 인증 구현.

## 4. 수락 기준
- [ ] Apple Developer Program 등록이 완료되고 활성 상태여야 함.
- [ ] 로컬 Xcode에서 아카이브(Archive) 및 유효성 검증(Validate)이 성공해야 함.
- [ ] GitHub Actions를 통해 빌드된 `.ipa` 파일이 TestFlight에 업로드되어야 함.
