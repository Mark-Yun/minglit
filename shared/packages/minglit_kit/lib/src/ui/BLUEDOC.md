# minglit_kit/ui — Design System & 공용 UI

두 앱이 공유하는 UI 컴포넌트·테마·디자인 토큰. **시각 SSOT 는 `apps/mds/docs/`** (Next.js 카탈로그) 에 있고, 본 폴더는 그 spec 의 Flutter 구현.

## 이정표

| 항목 | 무엇 |
|---|---|
| [`widgets/`](./widgets/) | 공용 위젯 (`minglit_skeleton`, `minglit_image`, `event_card`, `location_map_view`, `minglit_dialog` 등) |
| [`pages/`](./pages/) | 공용 페이지 |
| [`architecture.md`](./architecture.md) | Design Tokens · Theme · Feedback · Loading 상세 |

## 핵심 컨벤션

- **시각 SSOT 는 `apps/mds/docs/`** — 화면/컴포넌트 spec 의 권위 source. Flutter 구현은 spec 을 따른다.
- **UI 변경 PR 본문에 spec 파일 경로·섹션 인용 필수** (CLAUDE.md "UI 변경 게이트").
- **Spec 자체는 Mark(디자인 시스템 오너)만 수정** — SWE/에이전트는 read-only.
- **Design Tokens 변경은 `shared/packages/mds/tokens/`** (모노레포 SSOT) 와 동기화.
- **앱-specific UI 는 여기에 두지 않음** — 한 앱만 쓰는 위젯은 그 앱의 `lib/src/widgets/` 또는 feature 폴더로.

## 관련

- [architecture.md](./architecture.md) — Tokens · Theme · Feedback · Loading 상세
- [`apps/mds/docs/`](../../../../../../apps/mds/docs/) — 시각 spec 카탈로그 (Next.js)
- [`shared/packages/mds/`](../../../../mds/) — Design System 모노레포 패키지 (core / tokens / icons)
- [minglit_kit/architecture.md](../../architecture.md) — 5 계층 개요

---
_Reviewed: 2026-05-17 22:32_
