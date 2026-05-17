# apps/

Minglit 의 **사용자 대면 애플리케이션** 폴더. Flutter 모바일 앱 2 개 + Next.js 랜딩 2 개 + MDS 디자인 시스템 문서.

## 이정표

| 항목 | 무엇 |
|---|---|
| [`app_user/`](./app_user/BLUEDOC.md) | 일반 사용자 Flutter 앱 (파티 탐색·결제·인증 제출) |
| [`app_partner/`](./app_partner/BLUEDOC.md) | 파트너 사장님 Flutter 앱 (매장 관리·심사·정산) |
| [`landing_user/`](./landing_user/) | 사용자 랜딩 페이지 (Next.js) |
| [`landing_partner/`](./landing_partner/) | 파트너 랜딩 페이지 (Next.js) |
| [`mds/`](./mds/) | Minglit Design System spec/문서 (Next.js) |
| [`architecture.md`](./architecture.md) | Flutter 앱 공통 아키텍처 (Tech Stack, Patterns, Data Flow) |

## 핵심 컨벤션 (Flutter 측)

- **Feature-first 구조** — 모든 코드는 `lib/src/features/<feature>/` 아래로 응집. 기술적 폴더 (`screens/`, `widgets/`) 금지.
- **공용 로직은 `minglit_kit`** — 두 앱 모두 쓰는 Repository·Provider·UI 는 `shared/packages/minglit_kit/` 에. 앱 레포에는 앱 고유 로직만.
- **Coordinator 가 routing 을 담당** — UI 위젯은 "어디로 갈지" 모름. `ref.read(<feature>CoordinatorProvider).goTo...()` 만 호출.
- **Cross-feature import 금지** — `pr-gate.check-cross-feature-imports` job 이 차단 (Fix #1872).
- **Type-safe routing** — `go_router_builder` 로 컴파일 타임 검증. URL 문자열 직접 입력 금지.

## 관련

- [architecture.md](./architecture.md) — Flutter 앱 공통 아키텍처 상세
- [shared/packages/minglit_kit/BLUEDOC.md](../shared/packages/minglit_kit/BLUEDOC.md) — 공용 클라이언트 패키지
- [BLUEDOC 컨벤션](../docs/infra/bluedoc/BLUEDOC.md)
- [docs/architecture/backend.md](../docs/architecture/backend.md) — Supabase 백엔드 아키텍처
- [CLAUDE.md `## Build Defaults`](../CLAUDE.md) — flutter build 명령 / Java 17 설정

---
_Reviewed: 2026-05-17 22:32_
