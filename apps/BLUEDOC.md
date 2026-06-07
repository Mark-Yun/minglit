# apps/

> **동결 공지 (2026-06-06)**: Flutter 앱 2개 (`app_user`, `app_partner`) 는 웹 MVP 피벗으로 **동결** — 개발/배포 중단, 코드 보존. 랜딩·MDS 는 유지. 배경: [docs/architecture/web-mvp-pivot.md](../docs/architecture/web-mvp-pivot.md)

Minglit 의 **사용자 대면 애플리케이션** 폴더. Flutter 모바일 앱 2 개 + Next.js 랜딩 2 개 + MDS 디자인 시스템 문서.

## 이정표

| 항목 | 무엇 |
|---|---|
| [`app_user/`](./app_user/BLUEDOC.md) | 일반 사용자 Flutter 앱 (**동결**) — 파티 탐색·결제·인증 제출 |
| [`app_partner/`](./app_partner/BLUEDOC.md) | 파트너 사장님 Flutter 앱 (**동결**) — 매장 관리·심사·정산 |
| [`landing_user/`](./landing_user/) | 사용자 웹 MVP — 이벤트 탐색/상세/구매 진입 (Next.js) |
| [`landing_partner/`](./landing_partner/) | 파트너 랜딩 페이지 (Next.js) |
| [`mds/docs/`](./mds/docs/BLUEDOC.md) | Minglit Design System spec/문서 (Next.js) |
| [`architecture.md`](./architecture.md) | Flutter 앱 공통 아키텍처 (Tech Stack, Patterns, Data Flow) |

## 핵심 컨벤션 (Flutter 측)

- **Feature-first 구조** — 모든 코드는 `lib/src/features/<feature>/` 아래로 응집. 기술적 폴더 (`screens/`, `widgets/`) 금지.
- **공용 로직은 `minglit_kit`** — 두 앱 모두 쓰는 Repository·Provider·UI 는 `shared/packages/minglit_kit/` 에. 앱 레포에는 앱 고유 로직만.
- **Admin Next.js console 은 미스캐폴드 상태** — canonical target 은 `apps/admin_web/`; 현재 `app_partner/admin/` 기능은 제품 admin-dashboard 구현이 아님.
- **Coordinator 가 routing 을 담당** — UI 위젯은 "어디로 갈지" 모름. `ref.read(<feature>CoordinatorProvider).goTo...()` 만 호출.
- **Cross-feature import 금지** — `pr-gate.check-cross-feature-imports` job 이 차단 (Fix #1872).
- **Type-safe routing** — `go_router_builder` 로 컴파일 타임 검증. URL 문자열 직접 입력 금지.

## 핵심 컨벤션 (웹 MVP)

- **MDS spec-first** — UI 변경은 `apps/mds/docs/public/specs/` 화면 spec 과 `src/lib/components.ts` 컴포넌트 manifest 를 먼저 인용한다.
- **유저웹 공개 browse** — `landing_user` 는 비로그인 이벤트 탐색/상세를 허용하고, 신청·결제 같은 보호 액션에서 로그인으로 보낸다.
- **데이터 경계** — 공개 read 는 Supabase RLS/PostgREST, write 는 Edge Function/checkout 후속 화면에서 처리한다.

## 관련

- [architecture.md](./architecture.md) — Flutter 앱 공통 아키텍처 상세
- [shared/packages/minglit_kit/BLUEDOC.md](../shared/packages/minglit_kit/BLUEDOC.md) — 공용 클라이언트 패키지
- [BLUEDOC 컨벤션](../docs/infra/bluedoc/BLUEDOC.md)
- [docs/architecture/backend.md](../docs/architecture/backend.md) — Supabase 백엔드 아키텍처
- [CLAUDE.md `## Build Defaults`](../CLAUDE.md) — flutter build 명령 / Java 17 설정

---
_Reviewed: 2026-06-08 01:25_
