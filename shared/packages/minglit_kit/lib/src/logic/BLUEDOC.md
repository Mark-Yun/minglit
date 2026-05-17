# minglit_kit/logic — 공용 Providers

두 앱 모두가 의존하는 글로벌 Provider 들의 단일 출처. `supabaseProvider`, `authStateChangesProvider`, `userProfileProvider`, `eventFeedProvider` 등.

## 이정표

| 항목 | 무엇 |
|---|---|
| [`providers/`](./providers/) | `@riverpod` annotation 기반 공용 provider 집합 |
| [`architecture.md`](./architecture.md) | Provider 위치 결정 · 안티패턴 상세 |

## 핵심 컨벤션

- **kit 으로 갈 조건 (3 가지 중 하나)**:
  - 두 앱 모두 필요한 logic
  - Supabase 클라이언트·세션 등 글로벌 컨텍스트 wrap
  - 사용자 프로필·이벤트 피드 등 양쪽 도메인 공유 상태
- **앱-local 로 갈 조건**: UI 상태 (form, controller), Coordinator, 한 앱만 쓰는 logic → `apps/<app>/src/features/<feature>/logic/` 로.
- **모든 provider 는 `@riverpod` annotation** — manual 작성 금지.

## 관련

- [architecture.md](./architecture.md) — Provider 위치 결정 가이드 · 안티패턴
- [../data/BLUEDOC.md](../data/BLUEDOC.md) — Repository 와 함께 사용
- [minglit_kit/architecture.md](../../architecture.md) — 5 계층 개요
- [apps/architecture.md](../../../../../apps/architecture.md) — feature-local controller 와의 분리
