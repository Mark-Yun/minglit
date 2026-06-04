# mds/docs

Minglit Design System 의 **시각 SSOT + 문서 사이트**. 화면 spec, 컴포넌트 spec, 토큰/아이콘 카탈로그를 Next.js 로 제공한다.

## 이정표

| 항목 | 무엇 |
|---|---|
| [`src/app/`](./src/app/) | Next.js route pages (`/`, `/tokens`, `/components`, `/screens`, `/icons`, `/flows`) |
| [`src/lib/components.ts`](./src/lib/components.ts) | MDS 컴포넌트 manifest SSOT |
| [`src/components/specs/`](./src/components/specs/) | 컴포넌트별 inline visual playground |
| [`public/specs/BLUEDOC.md`](./public/specs/BLUEDOC.md) | 화면 spec source HTML + generated MD/PNG |
| [`reports/BLUEDOC.md`](./reports/BLUEDOC.md) | MDS 정합성 audit report + weekly FRESH_DOC job |
| [`scripts/render-spec-mockups.js`](./scripts/render-spec-mockups.js) | 화면 spec PNG + index.md 생성 |
| [`scripts/sync-icons-data.mjs`](./scripts/sync-icons-data.mjs) | icon manifest 를 docs 데이터로 동기화 |
| [`package.json`](./package.json) | dev/build/lint 및 token/icon sync 명령 |

## 핵심 컨벤션

- **Spec-first** — Flutter 구현은 `apps/mds/docs` 의 화면/컴포넌트 spec 을 따른다.
- **런타임 검증은 mock app 중심** — emulator render catalog 가 실제 Flutter 화면 캡처를 담당한다.
- **토큰 SSOT 는 `shared/packages/mds/tokens/`** — docs 는 generated CSS 를 `public/tokens.css` 로 sync 한다.
- **아이콘 SSOT 는 `shared/packages/mds/icons/`** — docs 의 React icon copy/data 는 sync script 로 갱신한다.
- **화면 spec source 는 `public/specs/<screen>/index.html`** — screen 변경은 여기만 직접 수정한다.
- **`index.md` / `state_*.png` / `blueprint*.png` 는 자동 산출물** — `render-spec-mockups.js` / `sync-mds-mockups.yml` 이 HTML 에서 재생성한다.

## 자주 쓰는 명령

```bash
# repo root 에서
npm install --package-lock=false --cache .npm-cache
npm run dev --workspace=apps/mds/docs      # http://localhost:3003
npm run lint --workspace=apps/mds/docs
npm run build --workspace=apps/mds/docs

# apps/mds/docs 에서
npm run dev      # http://localhost:3003
npm run tokens:sync && npm run icons:sync && npm run icons:sync-data
```

## 관련

- [`../../BLUEDOC.md`](../../BLUEDOC.md) — 앱 영역 진입점
- [`../../../shared/packages/mds/core/lib/mds.dart`](../../../shared/packages/mds/core/lib/mds.dart) — Flutter MDS barrel
- [`../../../shared/packages/mds/tokens/README.md`](../../../shared/packages/mds/tokens/README.md) — token codegen
- [`../../../shared/packages/mds/icons/README.md`](../../../shared/packages/mds/icons/README.md) — icon codegen
- [`../../../scripts/mds_render_coverage.dart`](../../../scripts/mds_render_coverage.dart) — MDS spec ↔ emulator render coverage

---
_Reviewed: 2026-06-04 21:20_
