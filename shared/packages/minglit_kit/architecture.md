# minglit_kit — 아키텍처

`app_user` 와 `app_partner` 가 공유하는 클라이언트 코어. 두 앱이 동일한 데이터·로직·UI 를 사용하도록 단일 출처를 제공한다.

앱 측 공통 아키텍처 (Tech Stack, Feature-first, Coordinator, Routing) 는 [`apps/architecture.md`](../../../apps/architecture.md) 참고.

## 1. 책임 구조 (5 계층)

| 계층 | 위치 | 책임 | 상세 |
|---|---|---|---|
| **Data** | `src/data/` | Supabase 테이블/RPC 접근 | [data/BLUEDOC.md](./lib/src/data/BLUEDOC.md) |
| **Logic** | `src/logic/providers/` | 공용 Provider (auth, user_profile, supabase 등) | [logic/BLUEDOC.md](./lib/src/logic/BLUEDOC.md) |
| **UI** | `src/ui/` | Design System + 공용 위젯 | [ui/BLUEDOC.md](./lib/src/ui/BLUEDOC.md) |
| **Domain** | `src/domain/` | 비즈니스 타입 (enum, model). UI/DB 와 독립 | (단순, 별도 문서 없음) |
| **Features** | `src/features/` | 공용 feature (auth/verification/notification 등) — Data+Logic+UI 묶음 | (각 feature 폴더 참고) |

보조 계층: `services/` (외부 SDK 래퍼), `components/` (feedback), `config/` (환경 설정), `utils/` (도메인 헬퍼).

## 2. Data Flow

```
Repository (Supabase 호출)
    ↓ Future<List<T>>
Provider (@riverpod, 캐싱)
    ↓ AsyncValue<T>
UI (ref.watch, AsyncValue 패턴)
    ↓ 사용자 액션
Coordinator (앱 측에서 라우팅/상태 변경)
```

## 3. Error Handling

모든 에러는 `handleMinglitError` 경유.

| Exception | 처리 |
|---|---|
| `MinglitUserException` | 사용자 친절 메시지 (SnackBar Secondary) |
| `MinglitAuthException` | 인증 오류 |
| `MinglitSystemException` / Unknown | 사용자에겐 안전 메시지, StackTrace 로깅 (SnackBar Error) |

Riverpod 패턴:
- `AsyncValueMinglitX<T>.showMinglitError(context)` — 선언적 에러 표시
- `guardMinglit()` — Future 를 에러 변환과 함께 래핑

## 4. Cross-Cutting

| 항목 | 위치 |
|---|---|
| Logging | `src/utils/log.dart` — `Log.d/i/w/e`, 메모리 1000 줄 이력, release 자동 비활성화 |
| Navigation Observer | `MinglitNavigationObserver` — push/pop/replace/remove 로깅 |
| URL Config | `src/config/url_config.dart` |
| Iamport Config | `src/config/iamport_config.dart` |
| Location | `src/services/location_service.dart` |
| Utility | `age_util`, `refund_calculator`, `ticket_crypto`, `image_utils`, `layout_dump`, `environment_info` 등 |

## 5. Trust & Verification (kit 측면)

2-layer 신뢰 모델 상세는 [`docs/architecture/trust-and-verification.md`](../../../docs/architecture/trust-and-verification.md). kit 의 역할:

- **Identity (Layer 1)** — `src/features/verification/` + `minglit_iamport_v1` 패키지로 클라이언트 SDK, 백엔드는 Portone V2 EF
- **Qualification (Layer 2)** — `verification_repository` 가 `user_verifications` → `verification_submissions` → `partner_verified_users` 흐름 wrapping

## 6. 모노레포 내 다른 공용 패키지

| 패키지 | 경로 | 역할 |
|---|---|---|
| `mds` (core) | `shared/packages/mds/core/` | Minglit Design System 순수 UI 컴포넌트·테마·토큰 통합 |
| `mds_tokens` | `shared/packages/mds/tokens/` | 디자인 토큰 SSOT (Style Dictionary → Dart 코드젠) |
| `mds_icons` | `shared/packages/mds/icons/` | SVG 기반 테마-어웨어 아이콘 |
| `minglit_iamport_v1` | `shared/packages/minglit_iamport_v1/` | Iamport V1 결제·본인인증 SDK 래퍼 |
| `minglit_lints` | `shared/packages/minglit_lints/` | 모노레포 공통 lint 규칙 |

## 관련

- [BLUEDOC](./BLUEDOC.md) — 본 패키지 진입점·이정표
- [lib/src/data/BLUEDOC.md](./lib/src/data/BLUEDOC.md) — Repository pattern 상세
- [lib/src/logic/BLUEDOC.md](./lib/src/logic/BLUEDOC.md) — Provider 조직 상세
- [lib/src/ui/BLUEDOC.md](./lib/src/ui/BLUEDOC.md) — Design System 상세
- [apps/architecture.md](../../../apps/architecture.md) — Flutter 앱 측 공통 아키텍처
- [docs/architecture/trust-and-verification.md](../../../docs/architecture/trust-and-verification.md)
- [docs/architecture/backend.md](../../../docs/architecture/backend.md) — Supabase 백엔드
