# public/specs

MDS 화면 spec 의 **source HTML + 자동 산출물 디렉터리**. Flutter 화면/상태/동작의 시각 SSOT 는 각 `<screen>/index.html` 이다.

## 이정표

| 항목 | 무엇 |
|---|---|
| [`_template.html`](./_template.html) | 새 화면 spec 작성용 canonical template |
| [`_authoring.html`](./_authoring.html) | spec 작성 상세 가이드 |
| [`_spec.css`](./_spec.css) | spec 공통 CSS / state mini-table / blueprint 스타일 |
| [`<screen>/index.html`](./event_detail_page/index.html) | 화면별 spec source. 직접 수정 대상 |
| [`ticket_selection_sheet/index.html`](./ticket_selection_sheet/index.html) | 이벤트 상세 하단 티켓 선택 시트 화면 spec |
| [`<screen>/index.md`](./event_detail_page/index.md) | HTML 에서 생성되는 markdown 산출물 |
| [`<screen>/state_*.png`](./event_detail_page/state_1.png) | HTML 에서 생성되는 state screenshot 산출물 |
| [`<screen>/blueprint*.png`](./event_detail_page/blueprint_1.png) | HTML 에서 생성되는 blueprint screenshot 산출물 |

## 핵심 컨벤션

- **직접 수정은 `<screen>/index.html` 만** — `index.md`, `state_*.png`, `blueprint*.png` 는 자동 산출물이다.
- **새 spec / 큰 개편은 `_template.html` 구조를 따른다** — Header → Overview → History → Layout → States → Global Behavior → Reference.
- **States 는 template mini-table 형식** — `table.ref.state-mini` + `thead` + mockup `rowspan=6` + 조건/사용자 액션/에지케이스/컴포넌트/토큰/노트 6행.
- **경로는 `<screen>/index.html`** — legacy `<screen>.html` flat path 를 새로 만들지 않는다.
- **코드와 다르면 먼저 source of truth 를 판정** — 구현이 live 이고 spec 이 stale 이면 HTML spec 을 갱신하고 History row 에 issue/PR 맥락을 남긴다.
- **토큰은 Minglit 이름으로 명시** — 색/간격/radius/opacity/icon/motion 은 `MinglitColors.*`, `MinglitSpacing.*`, `MinglitRadius.*`, `MinglitOpacity.*`, `MinglitIconSize.*`, `MinglitAnimation.*` 기준으로 적는다.
- **컴포넌트는 MDS 우선** — avatar/progress/button/sheet 등은 기존 Minglit 컴포넌트가 있으면 spec 의 Components 행과 Reference 에 실제 컴포넌트명을 남긴다.

## 생성 흐름

- `scripts/render-spec-mockups.js` 가 `index.html` 을 읽어 `index.md` 와 PNG를 생성한다.
- `.github/workflows/sync-mds-mockups.yml` 이 post-merge 에서 산출물을 갱신/커밋한다.
- 로컬에서 산출물을 만든 경우, 사용자가 명시하지 않으면 커밋하지 않는다.

## 관련

- [`../../BLUEDOC.md`](../../BLUEDOC.md) — MDS docs 진입점
- [`../../scripts/render-spec-mockups.js`](../../scripts/render-spec-mockups.js) — HTML → MD/PNG 생성
- [`../../src/app/screens/page.tsx`](../../src/app/screens/page.tsx) — `/screens` route index
- [`../../src/lib/flow-data.ts`](../../src/lib/flow-data.ts) — route/spec 매핑

---
_Reviewed: 2026-06-01 15:11_
