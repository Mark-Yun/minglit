# Minglit

Minglit 모노레포의 **프로젝트 전체 진입점**. 처음 온 에이전트는 여기서 주요 BLUEDOC 과 큰 설계 문서 위치를 잡고, 상세 정책은 각 문서로 이동한다.

## 이정표

| 항목 | 무엇 |
|---|---|
| [`docs/infra/bluedoc/BLUEDOC.md`](./docs/infra/bluedoc/BLUEDOC.md) | BLUEDOC 정의, 50 줄 제한, Reviewed freshness 규칙 |
| [`docs/infra/graphify/BLUEDOC.md`](./docs/infra/graphify/BLUEDOC.md) | 지식 그래프 사용/갱신 방식 (`graphify-out/`) |
| [`docs/infra/branch-strategy/BLUEDOC.md`](./docs/infra/branch-strategy/BLUEDOC.md) | dev-staging → dev → rc → main 브랜치 전략 |
| [`.github/BLUEDOC.md`](./.github/BLUEDOC.md) | GitHub Actions, PR gate, review setup, sync/deploy workflow |
| [`apps/BLUEDOC.md`](./apps/BLUEDOC.md) | Flutter 앱 2 개 + 랜딩 + MDS 진입점 |
| [`shared/packages/minglit_kit/BLUEDOC.md`](./shared/packages/minglit_kit/BLUEDOC.md) | 앱 공용 클라이언트 패키지 진입점 |
| [`supabase/BLUEDOC.md`](./supabase/BLUEDOC.md) | Supabase 백엔드 진입점 |
| [`docs/features/BLUEDOC.md`](./docs/features/BLUEDOC.md) | 제품 feature PRD/spec/CUJ 문서 |

## 핵심 방향

- **BLUEDOC 은 지도** — 정책과 상세 설명은 각 `architecture.md`, operations, QA 문서에 둔다.
- **클라이언트는 `apps/` + `minglit_kit`** — 앱 고유 로직과 공용 패키지 경계를 먼저 확인한다.
- **백엔드는 `supabase/` + `docs/architecture/backend.md`** — migration/function/test 위치와 설계 문서를 함께 본다.
- **큰 구조 질문은 graphify 우선** — `graphify-out/GRAPH_REPORT.md` 와 wiki/query 를 먼저 참고한다.

## 관련

- [README.md](./README.md) — 레포 기본 설명
- [docs/env-reference.md](./docs/env-reference.md) — `env-manifest.json` 기반 자동 생성 env reference
- [docs/architecture/](./docs/architecture/) — 결제, 검색/추천, 신뢰/인증, 이벤트 파이프라인 등 주요 설계 문서
- [docs/qa/automation-test-guide.md](./docs/qa/automation-test-guide.md) — 변경 유형별 테스트 기준
- [docs/operations/edge-functions.md](./docs/operations/edge-functions.md) — Edge Function 디버깅/운영

---
_Reviewed: 2026-06-03 12:58_
