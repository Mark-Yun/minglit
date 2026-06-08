# Web Client Architecture

> 웹 MVP 클라이언트 (`landing_user` 확장 = 유저웹, `landing_partner` 확장 = 파트너웹) 의 아키텍처 기준 문서. 피벗 결정 배경은 [web-mvp-pivot.md](./web-mvp-pivot.md), Flutter 클라이언트 (동결, behavior reference) 는 [apps/architecture.md](../../apps/architecture.md) 를 본다.

---

## 1. 전제 — 백엔드 계약이 구조를 결정한다

[EF-only mutation gateway](./overview.md#22-ef-only-원칙-mutation-gateway) 원칙은 웹에서도 동일하다.

```text
읽기  ──> Supabase JS (RLS 적용 직접 조회)
쓰기  ──> Edge Function 호출 (Bearer 토큰, auth-manifest 기준)
```

- 클라이언트는 DB 에 직접 INSERT/UPDATE/DELETE 하지 않는다.
- EF 함수명·인증 요구는 `supabase/functions/auth-manifest.json` 이 SSoT — typed EF 클라이언트는 이를 기준으로 작성한다.
- 화면 디자인 SSoT 는 MDS 웹 spec (`apps/mds/docs/public/specs/web_user_*`, `web_partner_*`) 이다.

## 2. 레이어 구조

### 2.1 공유 패키지 — `shared/packages/web_kit`

유저웹·파트너웹이 공유하는 플랫폼 로직. Flutter 시절 `minglit_kit` 의 역할을 웹에서 수행한다.

| 모듈 | 내용 |
|------|------|
| `supabase/` | 클라이언트 팩토리 — browser / server (RSC) / middleware, `@supabase/ssr` 쿠키 세션 |
| `ef/` | typed EF 클라이언트 — 함수별 request/response 타입 + zod 런타임 검증, `auth-manifest.json` 정합 |
| `types/` | `supabase gen types typescript` 생성 DB 타입 (수기 수정 금지) + EF DTO |
| `domain/` | 플랫폼 무관 도메인 로직 — 환불 계산, 상태 칩 매핑, 나이/날짜 표기 |
| `ui/` | MDS 웹 컴포넌트 (radix 프리미티브 + MDS 토큰) — Button, StatusChip, EventCard, ConsoleSidebar 등 |

규칙:

- **두 앱 모두 쓰는 것만 web_kit 에** — 단일 앱 전용 UI/로직은 앱의 `features/` 에 둔다 (minglit_kit 와 동일 기준).
- **DB 타입은 생성물** — 스키마 변경 시 `supabase gen types typescript` 재생성. 수기 타입과 drift 금지.
- **상태 어휘는 `domain/` 단일 매핑** — 신청/구매 상태 칩 (승인 대기/확정/거절·환불됨 등) 은 MDS spec 의 어휘 표가 기준.

### 2.2 앱 구조 — feature-first + route group

```text
apps/landing_user/src/
  app/(marketing)/    # 기존 랜딩·약관 (변경 없음)
  app/(app)/          # 웹앱 라우트: / · /events/[id] · /events/[id]/checkout · /my/purchases
  features/<feature>/ # discovery / event / checkout / purchases / account
  middleware.ts       # (app) 보호 라우트 가드 (/my/*, checkout)

apps/landing_partner/src/
  app/(marketing)/
  app/(console)/      # /login · /dashboard · /events · /parties/new · /applications · /settlements
  features/<feature>/ # auth / dashboard / party / event / applications / settlements
  middleware.ts       # (console) 전체 인증 가드 (로그인 + 파트너 권한)
```

- 라우트 파일 (`page.tsx`) 은 thin — 데이터 로딩 진입과 feature 컴포넌트 조립만. 로직은 `features/` 로.
- 기술 폴더 (`components/`, `hooks/` 최상위) 금지 — feature 폴더 내부에만 둔다.
- **cross-feature import 금지** — Flutter 의 pr-gate 룰과 동일 원칙. 공유가 필요해지면 web_kit 또는 feature 승격.

### 2.3 렌더링·데이터 전략

| | 유저웹 | 파트너웹 |
|---|---|---|
| 렌더링 | RSC + SSR — 이벤트 상세/홈은 비로그인 공개 + SEO 필수 | CSR 위주 (콘솔, SEO 불필요) |
| 초기 데이터 | Server Component 에서 Supabase 서버 클라이언트로 조회 | TanStack Query |
| 인터랙션 | TanStack Query (캐싱/무효화) | TanStack Query |
| 캐싱 | 이벤트 목록/상세 dynamic + 짧은 revalidate | 최소화 — 콘솔은 항상 fresh |

- **TanStack Query 가 서버 상태의 단일 소유자** (Riverpod 의 자리). 전역 클라이언트 상태 스토어는 기본 도입하지 않는다 — 필요가 증명되면 그때 추가.
- URL 이 공유 가능한 상태의 SSoT — 필터/탭/선택 등은 `nuqs` 로 query param 에 둔다 (MDS spec 결정: 참가 가능 체크, applications 의 이벤트·탭·모드).

## 3. 인증·권한

- `@supabase/ssr` 쿠키 세션. OAuth (Kakao/Apple/Google) 는 Supabase Auth 그대로.
- 유저웹: 공개 열람 기본, `/my/*`·checkout 만 middleware 가드. 보호 액션은 화면 내 로그인 유도 (spec 참조).
- 파트너웹: `(console)` route group 전체 가드 — 세션 + 파트너 권한 (파트너 아님 → 로그인 화면의 "권한 없음" state). 판정 위치는 middleware 한 곳.
- 본인인증: Portone V2 (`@portone/browser-sdk`) → `identity-verify` EF 검증. 결제와 SDK 일원화.

## 4. 디자인 시스템 연결

- `mds_tokens` (style dictionary) → `tokens.css` → **Tailwind 4 `@theme` 매핑**. spec 의 `MinglitColors.*` 어휘가 CSS 변수와 1:1.
- 아이콘은 `shared/packages/mds/icons/react` (생성물) 우선 — lucide 는 MDS 에 없는 것만 보조.
- UI 프리미티브는 radix-ui headless + MDS 토큰 스킨 (shadcn 방식 copy-in, web_kit `ui/` 소유). 외부 UI 킷 (MUI 등) 금지.
- 컴포넌트 단위는 MDS spec 의 Sub-anatomy 를 따른다.

## 5. 의존성 기준

| 분류 | 채택 | 비고 |
|------|------|------|
| 코어 | `@supabase/supabase-js` `@supabase/ssr` `@tanstack/react-query` `zod` `@portone/browser-sdk` | 계약 레이어 |
| UI/폼 | radix-ui 프리미티브, `react-hook-form`(+zod resolver), `cva` `clsx` `tailwind-merge`, `nuqs`, `date-fns` | headless + MDS 토큰 |
| 관측 | `@sentry/nextjs` | EF 의 `withSentry` 와 동일 목적지 |
| 보류 | `@tanstack/react-table` (테이블 복잡해지면), Zustand (전역 상태 필요가 증명되면), Turborepo (앱 3개+ 시) | |
| 금지 | Redux 류 기본 도입, GraphQL 레이어, 외부 UI 킷, i18n (현 단계) | 계약은 두껍게, UI 의존은 얇게 |

## 6. 테스트·검증

- **웹 CUJ (e2e)**: `apps/landing_<user|partner>/e2e/cuj/<category>/<feature>.spec.ts` — Playwright, feature 당 파일 1개, 기존 cujGroup 구조 이식 ([web-mvp-pivot.md §8](./web-mvp-pivot.md) 의 예약 컨벤션).
- 로컬 검증: local Supabase (`supabase start` + seed) 또는 dev 환경. 결제는 `dev-mock-portone` EF 재사용.
- 시각 검증: 구현 화면 스크린샷 ↔ MDS spec mockup 대조 (spec 이 디자인 SSoT).
- 안정화 후 웹 CUJ 를 `dev-rc-cut-gate` required evidence 로 추가한다 (동결된 Flutter CUJ 신호의 대체 — [promotion-contract.md](../infra/branch-strategy/promotion-contract.md)).

## 7. 확장 경로

- **세 번째 surface** (admin_web 확장, PWA/모바일 재개): web_kit 의 ef/types/domain 그대로 재사용 — UI 만 신규.
- **EF 계약 변경**: web_kit 타입 갱신 → 두 앱이 컴파일 에러로 영향 범위를 드러냄.
- **앱 분리가 필요해지면**: route group 경계 + features/ + web_kit 구조라 마케팅/앱 분리 이전 비용이 낮다.

---

## Related Documents

| 문서 | 내용 |
|------|------|
| [web-mvp-pivot.md](./web-mvp-pivot.md) | 피벗 결정 기록 — 코어 범위, 웹 화면 목록 (§9), 문서/테스트 마이그레이션 정책 (§8) |
| [overview.md](./overview.md) | 시스템 조감도 — EF-only gateway |
| [backend.md](./backend.md) | Supabase 테이블/EF/RLS |
| [apps/architecture.md](../../apps/architecture.md) | Flutter 클라이언트 (동결) — Repository/Provider 패턴의 behavior reference |
| `apps/mds/docs/public/specs/web_foundation_responsive/` | breakpoint/그리드/포인터 규칙 |
