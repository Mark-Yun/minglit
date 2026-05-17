# app_partner

Minglit 의 **파트너 사장님 Flutter 앱**. 매장 관리·멤버 초대·유저 인증 심사·이벤트 신청 처리·정산 등 파트너 측 워크플로우 담당.

## 이정표

| 항목 | 무엇 |
|---|---|
| `lib/main.dart` / `lib/dev_main.dart` | 프로덕션 / 개발용 엔트리포인트 (후자는 DevMap) |
| [`lib/src/features/`](./lib/src/features/) | 기능별 모듈 (아래 표) |
| [`lib/src/routing/`](./lib/src/routing/) | `app_router` (auth + 권한 + 온보딩 redirect) + `app_routes` (Type-safe) |
| [`lib/src/logic/`](./lib/src/logic/) | 앱-레벨 Provider (`current_partner_provider`, `onboarding_state_provider`, `event_application_logic`, `dashboard_refresh_notifier`) |
| `lib/src/ui/` · `widgets/` · `utils/` · `l10n/` | 파트너 전용 UI (shell, widgets) · 공용 위젯 · 헬퍼 · 다국어 |
| [`integration_test/`](./integration_test/) | 통합 테스트 / CUJ ([BLUEDOC](./integration_test/cuj/BLUEDOC.md)) |
| [`architecture.md`](./architecture.md) | 파트너 앱 고유 아키텍처 (권한 기반 라우팅 redirect) |
| [`README.md`](./README.md) | 빌드·실행 명령 |

## Features 이정표

| Feature | 무엇 |
|---|---|
| `auth/` | 파트너 로그인·인증 |
| `home/` | 파트너 대시보드 |
| `admin/` | 관리자 기능 (입점 신청 관리) |
| `onboarding/` | 파트너 온보딩 (신규 신청·서류 작성) |
| `member/` | 멤버 관리 (초대·권한) |
| `party/` | 파티·이벤트 관리 |
| `application/` | 이벤트 신청 관리 (승인·거절) |
| `checkin/` | 이벤트 체크인 |
| `verification/` | 유저 인증 심사 (제출 서류 승인·반려·보완) |
| `ticket/` | 티켓 관리 |
| `settlement/` | 정산 관리 |
| `more/` | 더보기 메뉴 |
| `account_deletion/` | 파트너 탈퇴 |

## 핵심 컨벤션

- **공용 로직은 `minglit_kit`** — 파트너 앱 레포에는 파트너 고유 로직만.
- **Cross-feature import 금지** — `pr-gate.check-cross-feature-imports` 가 차단.
- **권한 분기는 router redirect 에서** — feature 안에 권한 체크 흩뿌리지 않음. 자세한 흐름은 [`architecture.md`](./architecture.md).
- **공통 Flutter 아키텍처는 [`apps/architecture.md`](../architecture.md)** — Tech Stack, Coordinator/Routing/Repository pattern.

## 관련

- [architecture.md](./architecture.md) — 파트너 앱 라우팅·권한 redirect 상세
- [apps/architecture.md](../architecture.md) — Flutter 공통 아키텍처
- [apps/BLUEDOC.md](../BLUEDOC.md) — 앱 폴더 진입점
- [minglit_kit/BLUEDOC.md](../../shared/packages/minglit_kit/BLUEDOC.md) — 공용 패키지
- [README.md](./README.md) — 빌드·실행 명령
- [integration_test/cuj/BLUEDOC.md](./integration_test/cuj/BLUEDOC.md) — CUJ 통합 테스트
