# minglit_kit

Minglit 의 **공용 클라이언트 패키지**. `app_user` 와 `app_partner` 가 모두 import 하는 데이터·로직·UI·디자인 시스템의 단일 출처.

## 이정표

| 항목 | 무엇 |
|---|---|
| `lib/minglit_kit.dart` | umbrella export (전체) |
| `lib/minglit_core/data/logic/ui/dev.dart` | 계층별 export (core 유틸 / data / logic / UI / 개발 유틸) |
| [`lib/src/data/`](./lib/src/data/BLUEDOC.md) | Models · Repositories — Repository pattern 상세 ([architecture](./lib/src/data/architecture.md)) |
| [`lib/src/logic/`](./lib/src/logic/BLUEDOC.md) | 공용 Providers — Provider 조직 상세 ([architecture](./lib/src/logic/architecture.md)) |
| [`lib/src/ui/`](./lib/src/ui/BLUEDOC.md) | Design System 구현 (Tokens, Theme, Feedback, Widgets) ([architecture](./lib/src/ui/architecture.md)) |
| [`lib/src/domain/`](./lib/src/domain/) | 비즈니스 도메인 타입·enum |
| [`lib/src/features/`](./lib/src/features/) | 공용 feature 13 개 (아래 표) |
| [`lib/src/services/`](./lib/src/services/) · `components/` · `config/` | 외부 SDK 래퍼 · feedback 컴포넌트 · 환경 설정 |
| [`lib/src/utils/`](./lib/src/utils/) | 헬퍼 (`Log`, `feedback_ext`, `age_util`, `refund_calculator`, `ticket_crypto` 등) |
| [`architecture.md`](./architecture.md) | Repository pattern, Provider 조직, Design System, Error Handling 상세 |
| [`README.md`](./README.md) | 패키지 사용 가이드 |

## 공용 Features 이정표

| Feature | 무엇 |
|---|---|
| `auth/` · `consent/` · `account_deletion/` | 로그인/OAuth · 약관 동의 · 계정 삭제 (소프트 + 30 일 유예) |
| `verification/` · `iamport/` | 본인인증 (Identity, Iamport V1 + Portone V2) · 결제 SDK 진입점 |
| `notification/` · `permission/` | 푸시·FCM·알림 목록/설정 · 앱 권한 설정 화면 |
| `search/` · `social/` | 전문 검색 (PGroonga) · 좋아요/구독/차단 |
| `theme/` · `loading/` · `dev/` | 테마 컨트롤러 · 글로벌 로딩 오버레이 · 개발 유틸 (세션 스위처) |

## 핵심 컨벤션

- **앱-specific 코드 금지** — 두 앱 모두 쓸 수 있는 것만. 한 앱 전용이면 그 앱 feature 폴더로.
- **Repository 는 `lib/src/data/repositories/`** — Supabase 접근의 단일 출처. 300 줄 넘으면 `part`/`mixin` split (상세는 [architecture.md](./architecture.md)).
- **공용 Provider 는 `lib/src/logic/providers/`** — `supabaseProvider`, `userProfileProvider` 등. feature-local controller 는 앱 레포로.
- **Error 는 `handleMinglitError` 경유** — `MinglitUserException` / `MinglitAuthException` / `MinglitSystemException` 분류.
- **Design System 변경은 [architecture.md § Design System](./architecture.md) + `apps/mds/docs/` 의 spec 과 동기화.**

## 관련

- [architecture.md](./architecture.md) — Repository · Provider · Design System · Error Handling 상세
- [apps/architecture.md](../../../apps/architecture.md) — Flutter 공통 아키텍처 (kit 사용 측)
- [docs/architecture/trust-and-verification.md](../../../docs/architecture/trust-and-verification.md) — 2-layer 신뢰 모델
- [README.md](./README.md) — 패키지 사용 가이드
- [BLUEDOC 컨벤션](../../../docs/infra/bluedoc/BLUEDOC.md)

---
_Reviewed: 2026-05-17 22:32_
