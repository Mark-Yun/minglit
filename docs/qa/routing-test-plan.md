# 라우팅 견고성 테스트 계획

> 관련 이슈: #1000, #970, #965

## 배경

기능 추가 시 라우팅 회귀가 반복됨. 현재 GoRouter 기반 라우팅에 대한 테스트가 부분적으로만 존재하며, 체계적 커버리지가 부족하다.

### 현재 테스트 현황

| 앱 | 파일 | 테스트 범위 |
|----|------|-----------|
| app_user | `auth_redirect_test.dart` | 비인증 보호 경로 → 로그인 리다이렉트 (6건) |
| app_user | `consent_redirect_test.dart` | 동의 플로우 리다이렉트 (7건) |
| app_user | `flow_notification_routing_test.dart` | 알림 → 딥링크 네비게이션 |
| app_user | `home_navigation_test.dart` | 홈 → 마이페이지 등 기본 네비게이션 |
| app_user | `app_router_test.dart` | 계정 삭제 복구 리스너 |
| app_partner | `app_routes_test.dart` | StatefulShellRoute 구조 검증 (5 branch, 중첩 route) |

### 갭 (Gap)

- 전체 route 도달 가능성(reachability) 체계적 검증 없음
- 딥링크(HTTPS, 푸시 알림) 테스트 없음
- 백키 네비게이션 스택 무결성 테스트 부족 (#970 수정분 제외)
- Partner app redirect 로직 테스트 없음 (onboarding state 기반)
- Route snapshot(골든 파일) 없음 → 경로 추가/삭제 시 회귀 감지 불가
- 중복 push 방지, 인증 만료 중 라우팅, 삭제된 리소스 딥링크 등 엣지 케이스 미커버

---

## 계층별 테스트 계획

### Layer 1: Route 구조 Snapshot 테스트 (회귀 방지)

전체 route tree를 골든 파일로 관리. 새 route 추가/삭제 시 자동 감지.

| 앱 | 테스트 케이스 | 파일 위치 | 우선순위 |
|----|------------|----------|---------|
| app_user | 전체 route path 목록 snapshot | `test/src/routing/app_routes_test.dart` | P1 |
| app_user | 보호 경로(protected prefix/suffix) 목록 snapshot | `test/src/routing/app_routes_test.dart` | P1 |
| app_partner | 전체 route path 목록 snapshot (기존 구조 테스트 확장) | `test/src/routing/app_routes_test.dart` | P1 |

**구현 가이드:**
```dart
// app_routes_test.dart 에 추가
test('route path snapshot — 경로 추가/제거 시 테스트 업데이트 필수', () {
  final routes = collectAllRoutePaths(appRoutes); // GoRoute tree 재귀 순회
  expect(routes, [
    '/',
    '/curation',
    '/search',
    '/my',
    '/my/privacy',
    // ... 전체 경로 나열
  ]);
});
```

- `collectAllRoutePaths()` 헬퍼: GoRoute tree를 재귀 순회하여 모든 path를 추출
- Partner app의 기존 `app_routes_test.dart`를 참고 (이미 구조 검증 패턴 있음)
- 경로 추가 시 이 테스트가 실패 → 개발자가 의도적으로 업데이트해야 함

---

### Layer 2: Redirect 로직 테스트

#### 2-A. User App Redirect (기존 확장)

기존 `auth_redirect_test.dart`, `consent_redirect_test.dart` 에 누락된 케이스 추가.

| 테스트 케이스 | 파일 위치 | 우선순위 |
|------------|----------|---------|
| `/explore` → `/` 하위 호환 리다이렉트 | `test/integration/auth_redirect_test.dart` | P2 |
| `/events/:id/apply` suffix 보호 — 비인증 시 로그인 리다이렉트 | `test/integration/auth_redirect_test.dart` | P1 |
| `/tickets/my` 보호 — 비인증 시 로그인 리다이렉트 | `test/integration/auth_redirect_test.dart` | P1 |
| `/purchase-history` 보호 — 비인증 시 로그인 리다이렉트 | `test/integration/auth_redirect_test.dart` | P2 |
| `/certification` 보호 — 비인증 시 로그인 리다이렉트 | `test/integration/auth_redirect_test.dart` | P2 |
| `_sanitizeReturnLocation` — `//`, `/login`, `/signup/consent` 차단 | `test/src/routing/app_router_test.dart` | P1 |
| `_sanitizeReturnLocation` — 정상 경로 통과 | `test/src/routing/app_router_test.dart` | P2 |

#### 2-B. Partner App Redirect (신규)

Partner app은 onboarding state 기반 redirect가 핵심이나 테스트가 전무.

| 테스트 케이스 | 파일 위치 | 우선순위 |
|------------|----------|---------|
| 비인증 + 비로그인 경로 → `/login` 리다이렉트 | `test/integration/partner_redirect_test.dart` (신규) | P1 |
| 인증 + `/login` → `/` 리다이렉트 | `test/integration/partner_redirect_test.dart` | P1 |
| `needsApplication` 상태 → `/welcome` 리다이렉트 | `test/integration/partner_redirect_test.dart` | P1 |
| `draftInProgress` 상태 → `/apply` 리다이렉트 | `test/integration/partner_redirect_test.dart` | P1 |
| `pendingReview` 상태 → `/apply/status` 리다이렉트 | `test/integration/partner_redirect_test.dart` | P1 |
| `needsCorrection` 상태 → `/apply/status` 리다이렉트 | `test/integration/partner_redirect_test.dart` | P2 |
| `hasPartner` + `/apply` → `/` 리다이렉트 | `test/integration/partner_redirect_test.dart` | P1 |
| `/dev/*` 경로 — 인증 없이 접근 허용 | `test/integration/partner_redirect_test.dart` | P2 |

---

### Layer 3: 딥링크 테스트

| 테스트 케이스 | 파일 위치 | 우선순위 |
|------------|----------|---------|
| 푸시 알림 payload `deep_link` → 올바른 화면 도달 | `app_user/test/integration/deep_link_test.dart` (신규) | P1 |
| HTTPS 딥링크 `/events/:id` → EventDetailRoute 도달 | `app_user/test/integration/deep_link_test.dart` | P1 |
| 보호 경로 딥링크 (비인증) → 로그인 → 원래 경로 복귀 | `app_user/test/integration/deep_link_test.dart` | P1 |
| 존재하지 않는 경로 딥링크 → 에러 핸들링 (크래시 없음) | `app_user/test/integration/deep_link_test.dart` | P2 |
| OAuth callback scheme (`com.minglit.app_user://callback`) 처리 | `app_user/test/integration/deep_link_test.dart` | P2 |

**구현 가이드:**
- `GoRouter`의 `initialLocation` 파라미터로 딥링크 진입 시뮬레이션
- `notificationDeepLinkHandlerProvider`를 override하여 딥링크 핸들러 테스트
- 비인증 상태에서 보호 경로 딥링크 시 `from` 파라미터 정상 전달 검증

---

### Layer 4: 네비게이션 스택 무결성 테스트

| 테스트 케이스 | 파일 위치 | 우선순위 |
|------------|----------|---------|
| 홈 → 이벤트 상세 → 백키 → 홈 | `app_user/test/integration/navigation_stack_test.dart` (신규) | P1 |
| 동의 완료 후 go('/') → push(dest) 패턴 — 백키 시 앱 종료 아닌 홈 (#970) | `app_user/test/integration/navigation_stack_test.dart` | P1 |
| 로그인 → 보호 경로 복귀 시 스택 정상 (로그인 페이지 스택에 남지 않음) | `app_user/test/integration/navigation_stack_test.dart` | P1 |
| Partner 탭 전환 → 백키 → 이전 탭 (StatefulShellRoute) | `app_partner/test/integration/navigation_stack_test.dart` (신규) | P2 |
| Partner 중첩 네비게이션: 더보기 → 파티 목록 → 파티 상세 → 이벤트 상세 → 백키 3회 → 더보기 | `app_partner/test/integration/navigation_stack_test.dart` | P2 |
| AuthGuard push 패턴 — LoginPage push 후 백키 시 원래 화면 유지 | `app_user/test/integration/navigation_stack_test.dart` | P2 |

---

### Layer 5: 엣지 케이스 테스트

| 테스트 케이스 | 파일 위치 | 우선순위 |
|------------|----------|---------|
| 같은 화면 중복 push 방지 — 빠른 연속 탭 시 중복 네비게이션 없음 | `app_user/test/integration/edge_cases_test.dart` (기존 확장) | P2 |
| 인증 만료 중 보호 경로 접근 — 크래시 없이 로그인으로 리다이렉트 | `app_user/test/integration/edge_cases_test.dart` | P1 |
| 삭제된 이벤트 딥링크 접근 — 에러 화면 또는 홈으로 안전하게 복귀 | `app_user/test/integration/edge_cases_test.dart` | P2 |
| consent loading 상태에서 redirect loop 방지 (기존 테스트 확인) | `app_user/test/integration/consent_redirect_test.dart` | P3 (기존 있음, 확인만) |
| `from` 파라미터 injection 방지 (`from=//evil.com`) (기존 테스트 확인) | `app_user/test/integration/auth_redirect_test.dart` | P3 (기존 있음, 확인만) |

---

### Layer 6: Coordinator 단위 테스트

Coordinator의 navigation 메서드를 단위 테스트하여 올바른 GoRouter 메서드(push vs go)와 경로가 호출되는지 검증.

| Coordinator | 테스트 케이스 | 파일 위치 | 우선순위 |
|------------|------------|----------|---------|
| `AuthCoordinator` | `pushLogin` — push 호출 + from 파라미터 전달 | `app_user/test/src/features/auth/logic/auth_coordinator_test.dart` | P2 |
| `AuthCoordinator` | `goToHome` — go('/') 호출 | 동일 | P3 |
| `HomeCoordinator` | 각 push 메서드 — 올바른 경로 push 확인 | `app_user/test/src/features/home/logic/home_coordinator_test.dart` | P2 |
| `ConsentCoordinator` | `completeSignup` — go('/') 후 push(dest) 패턴 (#970) | `app_user/test/src/features/consent/logic/consent_coordinator_test.dart` | P1 |

---

## 테스트 인프라 (공통 유틸)

### 1. `collectAllRoutePaths()` 헬퍼

```dart
/// GoRoute tree를 재귀 순회하여 모든 경로를 추출
List<String> collectAllRoutePaths(List<RouteBase> routes, [String prefix = '']) {
  final paths = <String>[];
  for (final route in routes) {
    if (route is GoRoute) {
      final fullPath = route.path.startsWith('/')
          ? route.path
          : '$prefix/${route.path}';
      paths.add(fullPath);
      paths.addAll(collectAllRoutePaths(route.routes, fullPath));
    } else if (route is ShellRoute) {
      paths.addAll(collectAllRoutePaths(route.routes, prefix));
    } else if (route is StatefulShellRoute) {
      for (final branch in route.branches) {
        paths.addAll(collectAllRoutePaths(branch.routes, prefix));
      }
    }
  }
  return paths;
}
```

### 2. Routing Test Harness

```dart
/// GoRouter를 테스트 환경에서 구성하는 헬퍼
GoRouter createTestRouter({
  required List<RouteBase> routes,
  String initialLocation = '/',
  GoRouterRedirect? redirect,
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  return GoRouter(
    routes: routes,
    initialLocation: initialLocation,
    redirect: redirect,
    navigatorKey: navigatorKey,
  );
}
```

- `app_user/test/utils/routing_test_helpers.dart` (신규)
- `app_partner/test/utils/routing_test_helpers.dart` (신규)
- 기존 `test_utils.dart`와 동일 디렉터리에 배치

---

## 실행 순서

### P1 (필수) — 14건
1. Route path snapshot 테스트 (app_user, app_partner) — 3건
2. Partner app redirect 로직 핵심 (비인증, onboarding state) — 5건
3. User app 누락 보호 경로 redirect (`/apply` suffix, `/tickets/my`) — 2건
4. 딥링크 핵심 (푸시→화면, HTTPS→화면, 비인증 딥링크) — 3건
5. ConsentCoordinator `completeSignup` 단위 테스트 — 1건

### P2 (권장) — 16건
- User app 추가 보호 경로 redirect — 2건
- `_sanitizeReturnLocation` 단위 테스트 — 2건
- Partner app 추가 redirect — 2건
- 딥링크 에러 핸들링 — 2건
- 네비게이션 스택 무결성 — 6건

### P3 (선택/확인) — 4건
- 기존 테스트 확인 (consent loop, from injection) — 2건
- Coordinator 단위 테스트 (AuthCoordinator goToHome) — 1건
- Partner dev 경로 인증 우회 — 1건

**총 34건**

---

## 기술 접근법 권장

### GoRouter 테스트 패턴

1. **`initialLocation`으로 진입점 시뮬레이션**: GoRouter 생성 시 `initialLocation` 파라미터로 딥링크/직접 진입 테스트
2. **`redirect` 함수 단위 테스트**: `GoRouterState`를 직접 생성하여 redirect 함수만 독립 테스트 (가장 빠르고 안정적)
3. **`pumpWidget` + `GoRouter`**: 위젯 테스트에서 실제 네비게이션 동작 검증
4. **Route snapshot**: `expect(paths, [...])` 패턴으로 경로 목록 고정 — `--update-goldens` 불필요, 단순 리스트 비교

### 권장하지 않는 접근법

- **Patrol/네이티브 통합 테스트**: 현 단계에서 과도. 위젯 테스트 레벨에서 충분히 검증 가능
- **Navigation graph 자동 검증**: 구현 복잡도 대비 효용 낮음. Snapshot 테스트로 대체
- **Flaky한 타이밍 의존 테스트**: `pumpAndSettle()` 대신 특정 위젯 출현을 `pump()` + `find` 로 검증
