# [Arch] Patrol 도입 — 기술 설계

**이슈:** #1436
**상태:** Proposed
**담당:** needs-arch-claude-team-1

---

## 1. 배경 및 제약

현재 integration test는 Flutter 위젯 트리 내부에서만 동작하여 OS 권한 다이얼로그, WebView 내부 인터랙션을 자동 테스트할 수 없다.
Patrol v4.5.0을 도입하여 네이티브 레벨 자동 테스트를 가능하게 한다.

**제약:**
- 기존 23+6개 integration test 마이그레이션 없음 (공존)
- Patrol MCP 미도입
- CI에서 Android emulator 기반 Patrol 테스트는 느리고 불안정 → 주 1회 schedule + manual dispatch

---

## 2. 결정

### 패키지 버전
- `patrol: ^4.5.0` (dev_dependency, app_user + app_partner)
- `patrol_finders: ^3.2.0` (dev_dependency, app_user + app_partner)

### API 주의
이슈 #1436에 `$.native.*` 예시가 있으나, Patrol v4.0부터 deprecated.
**`$.platform.*` API를 사용한다.**

### 디렉토리 구조
```
apps/app_user/
  patrol_test/                    ← Patrol 전용 (기존 test/ 영향 없음)
    permission_grant_test.dart    ← Phase 2: 카메라, 위치, 푸시 권한
    kakao_login_test.dart         ← Phase 3: 카카오 WebView 로그인
    payment_pg_test.dart          ← Phase 3: iamport PG 결제
```

### pubspec.yaml patrol 설정
```yaml
patrol:
  app_name: Minglit Dev
  android:
    package_name: com.minglit.app_user.dev
  ios:
    bundle_id: com.minglit.appUser.dev
```

### Android 네이티브 설정
`android/app/src/androidTest/` 에 Patrol instrumentation runner 추가:
- `AndroidManifest.xml` (instrumentation 선언)
- `MainActivityTest.java` (Patrol test runner)

### CI 워크플로우
`.github/workflows/patrol-e2e.yml`:
- Schedule: 매주 월요일 06:00 UTC
- workflow_dispatch 수동 실행 지원
- Android emulator (API 34, x86_64, pixel_6)
- KVM 가속, patrol test 실행
- app_user만 대상 (app_partner는 후속)

---

## 3. 구현 태스크

| # | 태스크 | 담당 |
|---|--------|------|
| T1 | pubspec.yaml 수정 (app_user, app_partner) + patrol 설정 추가 | dev-1 |
| T2 | Android 네이티브 설정 (androidTest/) | dev-1 |
| T3 | patrol_test/ 디렉토리 + Phase 2/3 테스트 파일 작성 | dev-2 |
| T4 | CI 워크플로우 (.github/workflows/patrol-e2e.yml) | dev-3 |
| T5 | 코드 리뷰 | reviewer |

T1+T2 병렬, T3 병렬, T4 병렬. 모두 독립적.

---

## 4. 트레이드오프

| 선택 | 이득 | 대가 |
|------|------|------|
| patrol_test/ 별도 디렉토리 | 기존 test/ 영향 0 | patrol test 실행 시 별도 명령 필요 |
| 주 1회 CI | 비용 절약, emulator 불안정 회피 | 빠른 피드백 불가 |
| Phase 2/3 테스트를 skeleton으로 작성 | 구조만 잡아두고 실제 계정/환경 준비 후 활성화 | 당장 CI에서 실행 불가 (테스트 계정 미비) |

---

## 5. 참고

- [Patrol 공식 문서](https://patrol.leancode.co/)
- [pub.dev/packages/patrol](https://pub.dev/packages/patrol) v4.5.0
- [Patrol v4.0 마이그레이션 가이드](https://patrol.leancode.co/native-to-platform-migration)
