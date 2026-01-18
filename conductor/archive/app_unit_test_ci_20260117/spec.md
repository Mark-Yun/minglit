# 명세서: 앱 단위 테스트 및 CI 파이프라인 구축 (App Unit Test & CI)

## 1. 개요
`app_user`의 핵심 비즈니스 로직(Controller)에 대한 단위 테스트를 작성하여 안정성을 확보하고, GitHub Actions CI 파이프라인에 통합하여 코드 품질을 지속적으로 관리합니다.

## 2. 주요 기능

### 2.1. 단위 테스트 (Unit Test)
- **대상:**
    - `EventAdmissionController`: 입장 조건(나이, 성별, 인증)에 따른 상태(`guest`, `eligible` 등) 변화 검증.
    - `EventDetailController`: 데이터 로딩 성공/실패 시 상태 변화 검증.
    - `AuthController`: 로그인/로그아웃 시 상태 변화 검증.
- **도구:**
    - `flutter_test`: 기본 테스트 프레임워크.
    - `mocktail`: Repository 등 의존성 Mocking (Code gen 불필요).

### 2.2. CI/CD 통합 (GitHub Actions)
- **워크플로우:** `.github/workflows/ci.yml`
- **트리거:**
    - `Pull Request`: `main`, `dev` 브랜치 대상 PR 생성/업데이트 시.
    - `Push`: `deploy` 태그 또는 배포 브랜치 푸시 시.
- **작업:**
    - Flutter 환경 설정.
    - 의존성 설치 (`flutter pub get`).
    - 린트 검사 (`flutter analyze`).
    - 단위 테스트 실행 (`flutter test`).

## 3. 기술 스택
- **Test:** `flutter_test`, `mocktail`.
- **CI:** GitHub Actions.

## 4. 수락 기준
- [ ] `app_user/test/` 하위에 각 컨트롤러별 테스트 파일이 생성되어야 함.
- [ ] Mocktail을 사용하여 Repository를 모킹하고, 컨트롤러의 상태 변화를 검증해야 함.
- [ ] 로컬에서 `flutter test` 실행 시 모든 테스트가 통과해야 함.
- [ ] GitHub에 PR을 올렸을 때 자동으로 테스트 워크플로우가 실행되고 성공해야 함.
