# web_kit

Minglit 웹 MVP 의 **공유 클라이언트 패키지** (`@minglit/web-kit`). 유저웹(`landing_user`)·파트너웹(`landing_partner`)이 공유하는 플랫폼 로직 — Flutter 시절 [minglit_kit](../minglit_kit/BLUEDOC.md) 의 자리를 웹에서 수행한다. 기준 문서: [docs/architecture/web-client.md](../../../docs/architecture/web-client.md) §2.1.

## 이정표

| 모듈 | 무엇 |
|---|---|
| [`src/supabase/`](./src/supabase/) | 클라이언트 팩토리 — `createBrowserClient` / `createServerClient`(RSC) / `createMiddlewareClient`. `@supabase/ssr` 쿠키 세션 + env zod 검증 (`env.ts`) |
| [`src/ef/`](./src/ef/) | typed EF 클라이언트 — `callEdgeFunction` 코어 (Bearer 자동 첨부 · zod 응답 검증 · `MinglitError` 정규화) + 웹 MVP 코어 9개 wrapper (`functions/`) |
| [`src/types/`](./src/types/) | `db.ts` = `npm run gen:types` 생성 DB 타입 (현재 placeholder) · EF DTO 는 ef/ zod 스키마의 `z.infer` 재노출 |
| [`src/domain/`](./src/domain/) | `status-vocab.ts` — 상태 칩/탭 어휘 SSoT · `date-format.ts` — KST 포맷터 ("6월 12일 (금) 19:30" / D-day / 상대시간) |
| [`src/ui/`](./src/ui/) | MDS 토큰 스킨 컴포넌트 — `cn` / `StatusChip` / `Button` (radix copy-in 본격 작성은 후속) |
| [`README.md`](./README.md) | 사용법 · `transpilePackages` 설정 · gen:types 절차 |

## 핵심 컨벤션

- **EF-only 경계** — 쓰기는 `ef/` wrapper 경유만. 읽기는 supabase 클라이언트 직접 조회(RLS). 함수명·인증의 SSoT 는 `supabase/functions/auth-manifest.json`, wrapper 는 EF `index.ts` 파싱 로직 역산으로 작성 (불확실 필드는 `z.unknown()` + `TODO(web-kit)`).
- **생성 타입 규칙** — `src/types/db.ts` 는 `supabase gen types typescript` 생성물, 수기 수정 금지. 스키마 변경 시 재생성.
- **두-앱-공유 기준** — 두 앱 모두 쓰는 것만 web_kit 에. 단일 앱 전용 UI/로직은 그 앱의 `features/` 로 (minglit_kit 와 동일 기준). cross-feature 공유 필요가 생기면 web_kit 승격.
- **상태 어휘 SSoT** — 신청/구매 칩·탭 어휘는 `domain/status-vocab.ts` 단일 매핑. 원천은 MDS 웹 spec (`web_user_purchases` 칩 6종 표 · `web_partner_applications` 탭 3종). 라벨/톤 변경은 spec 갱신과 동기화.
- **빌드 없음** — exports 가 TS 소스 직접 지정. 소비 앱 `next.config` 에 `transpilePackages: ["@minglit/web-kit"]` 필수.
- **UI 는 MDS 토큰만** — 색/radius/spacing 은 `@minglit/mds-tokens` 의 CSS 변수 참조 (Tailwind 4 `@theme` 매핑은 앱 측). 외부 UI 킷 금지.

## 관련

- [docs/architecture/web-client.md](../../../docs/architecture/web-client.md) — 레이어 구조 · 렌더링/데이터 전략 · 의존성 기준 (§5)
- [supabase/functions/auth-manifest.json](../../../supabase/functions/auth-manifest.json) — EF 인증/인가 SSoT
- [shared/packages/mds/tokens](../mds/tokens/) — `tokens.css` 생성물 / [minglit_kit](../minglit_kit/BLUEDOC.md) — 동결된 behavior reference

---
_Reviewed: 2026-06-07 (scaffold)_
