# 계획: 안드로이드 앱 빌드 및 CI/CD 설정

## Phase 1: 안드로이드 빌드 환경 구성 (로컬)
- [x] Task: 키스토어(Keystore) 생성 및 서명 설정
    - [x] `upload-keystore.jks` 생성 및 비밀번호 설정.
    - [x] `android/key.properties` 파일 구성 (Git 무시).
    - [x] `app/build.gradle`에 서명 로직(Signing Config) 추가.
- [x] Task: 빌드 플레이버(Flavor) 및 환경 설정
    - [x] `dev` 및 `prod` 플레이버 정의 (`build.gradle`).
    - [x] 플레이버별 고유 패키지명(`applicationId`) 및 앱 이름 설정.
    - [x] 환경별 `AndroidManifest.xml` 분리 또는 메타데이터 주입.
- [x] Task: Conductor - User Manual Verification 'Phase 1: 로컬 빌드 성공 확인' (Protocol in workflow.md)

## Phase 2: GitHub Actions CI 파이프라인 구축
- [x] Task: GitHub Secrets 보안 정보 등록
    - [x] 키스토어 파일 Base64 인코딩 후 `ANDROID_KEYSTORE_BASE64`에 등록.
    - [x] 키 비밀번호 및 별칭 등 기타 비밀값 등록.
- [x] Task: 배포 자동화 워크플로우 생성 (`.github/workflows/android-deploy.yml`)
    - [x] JDK 및 Flutter 환경 설정 스텝 작성.
    - [x] 키스토어 디코딩 및 임시 파일 생성 스텝 추가.
    - [x] `flutter build apk` 및 `aab` 명령어 자동화.
- [x] Task: Conductor - User Manual Verification 'Phase 2: CI 빌드 아티팩트 생성 확인' (Protocol in workflow.md)

## Phase 3: 배포 플랫폼 연동
- [x] Task: Firebase App Distribution 연동
    - [x] Firebase CLI Token 획득 및 GitHub Secrets 등록.
    - [x] 워크플로우에 Firebase 업로드 액션(`w9jds/firebase-action` 등) 추가.
- [x] Task: Google Play Store 배포 연동
    - [x] Google Play Console 서비스 계정(JSON 키) 생성 및 Secrets 등록.
    - [x] AAB 파일을 Play Store 내부 테스트 트랙에 업로드하는 스텝 추가.
- [x] Task: Conductor - User Manual Verification 'Phase 3: 실제 배포 완료 확인' (Protocol in workflow.md)
