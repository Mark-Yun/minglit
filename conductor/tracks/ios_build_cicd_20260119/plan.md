# 계획: iOS 앱 빌드 및 CI/CD 환경 구축

## Phase 1: 애플 개발자 계정 준비 (User Action 필수)
- [ ] Task: Apple Developer Program 등록 및 결제
    - [ ] Apple ID 준비 (이중 인증 필수).
    - [ ] [Apple Developer 사이트](https://developer.apple.com/)에서 'Enroll' 진행.
    - [ ] 결제 ($99) 및 신원 확인 절차 완료.
- [ ] Task: App Store Connect 앱 생성
    - [ ] 식별자(Identifier) 등록: `com.minglit.app_user` (Bundle ID).
    - [ ] 앱 생성: 'Minglit' 이름으로 새 앱 등록.

## Phase 2: 인증서 및 로컬 빌드 설정
- [ ] Task: 서명 인증서(Certificate) 발급
    - [ ] 개발용(Development) 및 배포용(Distribution) 인증서 생성 (CSR 방식).
    - [ ] 키체인(Keychain)에 등록 및 p12 파일 내보내기.
- [ ] Task: 프로비저닝 프로파일(Provisioning Profile) 생성
    - [ ] App ID와 인증서를 연결한 프로파일 생성 (Dev/AppStore).
    - [ ] Xcode에서 'Automatically manage signing' 해제 또는 프로파일 매핑 확인.
- [ ] Task: 로컬 아카이브 테스트
    - [ ] `flutter build ios --release --no-codesign` (또는 서명 포함) 테스트.
    - [ ] Xcode > Product > Archive 성공 확인.

## Phase 3: CI/CD 파이프라인 구축 (GitHub Actions)
- [ ] Task: App Store Connect API Key 발급
    - [ ] 사용자 및 액세스 > 키 탭에서 'App Store Connect API' 키 생성.
    - [ ] Issuer ID, Key ID, p8 파일(Private Key) 확보 및 GitHub Secrets 등록.
- [ ] Task: 워크플로우 작성 (`.github/workflows/ios-deploy.yml`)
    - [ ] `macos-latest` 러너 설정.
    - [ ] 인증서 및 프로파일 디코딩/설치 스텝 추가.
    - [ ] `flutter build ipa` 및 `xcrun altool` (또는 Fastlane) 업로드 스크립트 작성.
- [ ] Task: Conductor - User Manual Verification 'TestFlight 업로드 확인'
