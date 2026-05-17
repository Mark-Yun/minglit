# app_user

Minglit 의 **일반 사용자 Flutter 앱**. 파티 탐색·참여 신청·결제·티켓 관리·인증 제출 등 사용자 측 워크플로우 담당.

## 이정표

| 항목 | 무엇 |
|---|---|
| `lib/main.dart` / `lib/dev_main.dart` | 프로덕션 / 개발용 엔트리포인트 (후자는 DevMap) |
| [`lib/src/features/`](./lib/src/features/) | 기능별 모듈 (아래 표) |
| [`lib/src/routing/`](./lib/src/routing/) | `app_router` (GoRouter) + `app_routes` (Type-safe) + `app_coordinator` |
| [`lib/src/logic/`](./lib/src/logic/) | 앱-레벨 Coordinator / Provider (`event_coordinator`, `auth_coordinator`, `feed_state_provider`) |
| `lib/src/common/` · `widgets/` · `utils/` · `l10n/` | 앱 공통 위젯·Provider·헬퍼·다국어 |
| [`integration_test/`](./integration_test/) | 통합 테스트 / CUJ ([BLUEDOC](./integration_test/BLUEDOC.md)) |
| [`README.md`](./README.md) | 빌드·실행 명령 |

## Features 이정표

| Feature | 무엇 |
|---|---|
| `auth/` | 로그인·회원가입·OAuth |
| `home/` | 홈 피드·마이페이지 |
| `event/` | 이벤트 상세·신청·입장 |
| `party/` | 파티 목록·상세 |
| `partner/` | 파트너 상세 페이지 |
| `payment/` | 결제 플로우·결제 완료 |
| `ticket/` · `tickets/` · `my_tickets/` | 티켓 선택·관리·내 티켓 목록 |
| `search/` | 이벤트·파티 검색 (PGroonga) |
| `tag/` | 태그 기반 탐색 |
| `settings/` | 앱 설정 |
| `account_deletion/` | 회원 탈퇴 플로우 |
| `consent/` | 이용약관 동의 |
| `dev/` | 개발 유틸리티 (DevMap 화면 등) |

## 핵심 컨벤션

- **공용 로직은 `minglit_kit`** — Repository·공용 Provider·공용 UI 는 거기. 앱 레포에는 유저 앱 고유 로직만.
- **Cross-feature import 금지** — `pr-gate.check-cross-feature-imports` 가 차단.
- **화면 이동은 Coordinator 경유** — UI 가 `context.push` 직접 호출 X.
- **공통 아키텍처는 [`apps/architecture.md`](../architecture.md) 참고** — Tech Stack, Coordinator/Routing/Repository pattern.

## 관련

- [apps/architecture.md](../architecture.md) — Flutter 공통 아키텍처
- [apps/BLUEDOC.md](../BLUEDOC.md) — 앱 폴더 진입점
- [minglit_kit/BLUEDOC.md](../../shared/packages/minglit_kit/BLUEDOC.md) — 공용 패키지
- [README.md](./README.md) — 빌드·실행 명령
- [integration_test/BLUEDOC.md](./integration_test/BLUEDOC.md) — 통합 테스트

---
_Reviewed: 2026-05-17 22:32_
