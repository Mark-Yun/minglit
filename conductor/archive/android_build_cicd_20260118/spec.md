# 명세서: 안드로이드 앱 빌드 및 CI/CD 설정

## 1. 개요
Minglit 안드로이드 애플리케이션의 배포 프로세스를 자동화하기 위해 빌드 환경을 구축하고 GitHub Actions 기반의 CI/CD 파이프라인을 설정합니다. 이를 통해 일관된 빌드 품질을 유지하고 테스터 및 실제 사용자에게 신속하게 앱을 전달할 수 있는 환경을 마련합니다.

## 2. 주요 기능

### 2.1. 안드로이드 빌드 최적화
- **서명 설정 (Signing):** GitHub Secrets에 저장된 키스토어를 사용하여 배포용 APK/AAB 서명 자동화.
- **환경 분리 (Flavors):** `dev`(개발/테스트) 및 `prod`(실제 배포) 빌드 플레이버 구성. 각 환경별 패키지명 및 API 서버 주소 분리.
- **버전 자동화:** GitHub Actions의 실행 번호(Run Number)를 활용하여 빌드 시 버전 코드를 자동으로 증가.
- **매니페스트 설정:** 앱 이름, 아이콘, 필요한 권한(인터넷, 저장소 등)을 각 플레이버에 맞게 최적화.

### 2.2. CI/CD 파이프라인 구축
- **빌드 자동화:** `main` 또는 `dev` 브랜치 푸시 시 자동으로 릴리즈 모드 빌드 실행.
- **Firebase App Distribution:** 내부 테스터를 위해 빌드된 APK를 Firebase에 자동으로 업로드하고 알림 발송.
- **Google Play Console 연동:** `main` 브랜치 배포 시 Google Play Store의 내부 테스트 또는 프로덕션 트랙에 AAB 파일 자동 업로드.

### 2.3. 보안 및 비밀값 관리
- **GitHub Secrets:** 키스토어 파일(Base64 인코딩), 키 비밀번호, Firebase/Google Play API 키 등을 안전하게 관리.
- **보안 빌드:** 빌드 시점에만 비밀값을 주입하고 빌드 완료 후 즉시 제거하여 보안 유지.

## 3. 기술 요구사항
- **CI/CD 플랫폼:** GitHub Actions
- **빌드 도구:** Gradle, Flutter CLI
- **배포 플랫폼:** Firebase App Distribution, Google Play Store
- **보안 도구:** GitHub Repository Secrets

## 4. 수락 기준
- [ ] `flutter build aab --release` 명령어가 로컬 및 CI 환경에서 성공적으로 수행됨.
- [ ] 빌드된 파일이 유효한 키스토어로 정상 서명됨.
- [ ] GitHub에 코드 푸시 시 Firebase App Distribution으로 앱이 자동 전달됨.
- [ ] 특정 이벤트 발생 시 Google Play Console에 앱 번들(AAB)이 성공적으로 업로드됨.

## 5. 범위 제외 (Out of Scope)
- iOS 빌드 및 배포 설정 (별도 트랙 진행 권장).
- 스토어 등록용 스크린샷 제작 및 마케팅 문구 작성.
