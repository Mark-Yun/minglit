# minglit_kit/logic — Provider 조직 상세

Provider 가 어디에 살아야 하는지 결정하는 기준과 안티패턴.

## Provider 위치 매트릭스

| Provider 타입 | 위치 | 예 |
|---|---|---|
| Shared Repository | `minglit_kit/src/data/repositories/` | `partnerRepositoryProvider`, `eventRepositoryProvider` |
| Shared Logic | `minglit_kit/src/logic/providers/` | `supabaseProvider`, `userProfileProvider`, `eventFeedProvider` |
| Feature-local Controller | `apps/<app>/src/features/<feature>/logic/` | `purchaseHistoryControllerProvider` |
| Feature-local Provider | `apps/<app>/src/features/<feature>/` | `currentPartnerInfoProvider` (in `party_providers.dart`) |
| Coordinator | `apps/<app>/src/features/<feature>/logic/` 또는 feature 루트 | `eventCoordinatorProvider`, `adminCoordinatorProvider` |

## 결정 기준

**kit 으로 가는 조건 (3 가지 중 하나):**
- 두 앱 모두 필요
- Supabase 테이블·RPC wrap (= Repository 자동)
- 글로벌 도메인 (user profile, auth, event feed 등)

**앱 feature 폴더로 가는 조건:**
- 한 앱만 사용
- UI 상태 (controller, form state)
- Coordinator (앱별 라우트에 의존)

## 안티패턴

- **다른 feature 의 controller 를 import** (cross-feature 결합)
  - Bad: `settlement_page.dart` 가 `home/partner_dashboard_controller.dart` import
  - Fix: 공유 data model 을 공통 위치로, feature-local controller 작성
  - 차단: `pr-gate.check-cross-feature-imports` job (Fix #1872)
- **앱-specific UI 상태를 `minglit_kit` 에 두기** — kit 비대화, 한 앱만 쓰는 코드 strangler
- **`@riverpod` annotation 없이 manual provider 작성** — code-gen 우선
- **`StreamProvider`/`FutureProvider` raw 사용** — `@riverpod` 함수가 더 안정적, 변환 자동

## 관련

- [BLUEDOC](./BLUEDOC.md)
- [../data/BLUEDOC.md](../data/BLUEDOC.md) — Repository pattern (provider 자동 생성 짝)
- [minglit_kit/architecture.md](../../architecture.md) — 5 계층 개요
- [apps/architecture.md](../../../../../apps/architecture.md) — feature-local controller 의 위치
