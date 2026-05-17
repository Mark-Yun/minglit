# Features

사용자에게 노출되는 product capability 단위의 spec 모음. 도메인 기준으로 8개 카테고리로 분류한다.

## 정의

feature = `app_user` 또는 `app_partner` 의 UI 흐름에 대응하는 product capability. 대부분 user / partner 양면을 가지므로 spec 안에 두 측면 모두 기술.

feature 가 아닌 것:
- 디자인 시스템 / UI 폴리시 → `docs/ux/`
- 아키텍처 / 인프라 / 마이그레이션 → `docs/architecture/`, `docs/infra/`

## 카테고리 (MDS flow 기반)

| 카테고리 | 도메인 |
|----------|--------|
| [event/](./event/) | 이벤트 자체 (CRUD, 정책) |
| [event-operation/](./event-operation/) | 이벤트 진행 중 (체크인, 매칭, 결과) |
| [ticket/](./ticket/) | 티켓 (구매, 보유, 이력) |
| [discovery/](./discovery/) | 탐색 (검색, 태그, 신뢰) |
| [account/](./account/) | 계정 (가입, 동의, 프라이버시) |
| [notification/](./notification/) | 알림 |
| [settlement/](./settlement/) | 정산 (partner-only) |
| [admin/](./admin/) | 관리자 운영 도구 |

## Feature 폴더 파일

| 파일 | 작성 | 내용 |
|------|------|------|
| `prd.md` | 사람 (PM) | product overview — Summary / Motivation / Goals / Principles / User Journey / KPIs / Legal Basis |
| `spec.md` | 사람 (architect/PM) | testable CUJ 명세 — CUJs 표 / FR / NFR / Edge Cases / Open Questions / (참고) 화면 구성 |
| `mds_specs.md` | 워크플로우 derived | 이 feature 가 사용하는 MDS 화면 목록 + index.md 본문 |
| `spec_walk_flows.md` | 워크플로우 derived | 이 feature 를 cover 하는 spec-walker flow 목록 |

PRD 는 "왜/무엇을", spec.md 는 "테스트 가능한 단위" 로 분리. 한 feature 에 양면(user/partner) 있으면 PRD 에 Scenario 로 양쪽 다 적고, spec.md CUJ 에 actor (user/partner) 명시.

**개발적인 내용은 docs/features/ 에 두지 않는다** — DB schema 는 migration 파일, Provider/Repository 이름은 코드, 라우트 path 는 코드. 문서에는 product behavior 와 product data 정의(consent_key 같은)까지만.

UX 디자인의 SSoT 는 MDS spec (`apps/mds/docs/public/specs/`). feature 폴더의 `mds_specs.md` 는 derived view. `ui-ux-design.md` 와 `wireframe.html` 은 사용하지 않는다 (Mark 가 MDS HTML 에 작성, 워크플로우가 feature 로 grouping).

### CUJ ID 컨벤션

| 형식 | 의미 | 예 |
|------|------|-----|
| `<scenario>-<cuj>` | PRD User Journey 의 Scenario 번호 + 해당 시나리오 내 CUJ 번호 | `1-1`, `1-2`, `2-3` |

- PRD 에서 `### Scenario 1: ... (CUJ 1-x)` 로 prefix 명시 → spec.md CUJ ID 와 양방향 트레이스.
- 한 PRD Scenario 가 다수 CUJ 로 분해됨. CUJ 는 한 줄 시나리오, 테스트 가능 단위.

### CUJ ↔ 테스트 파일 매핑

`apps/app_user/integration_test/cuj/<category>/<feature>_test.dart` (또는 `apps/app_partner/integration_test/cuj/...`) — feature 하나당 파일 하나, CUJ 다수가 한 파일에 `cujGroup(...)` 블록으로 공존. 폴더명 dash → 파일명 underscore (예: `signup-consent` → `signup_consent_test.dart`). 실 에뮬레이터/디바이스 위 mock 기반 행위 검증.

### spec.md 5섹션 골격

```markdown
## CUJs
| ID | Priority | CUJ Name | Details | FR | NFR |

## Functional Requirements
- FR-N: ...

## Non-Functional Requirements
- NFR-N: ... (측정 환경 명시 — 예 "에뮬레이터 baseline, p50")

## Edge Cases
| CUJ ID | 케이스 | 기대 동작 |

## Open Questions
- [ ] ...
```

NFR 은 측정 가능해야 함 — "빨라야 함" 금지, "200ms p50 / 에뮬레이터" 처럼 환경+분산 명시.

**메타데이터 파이프라인**
1. Mark 가 `apps/mds/docs/public/specs/<screen>/index.html` 에 `<meta name="features" content="cat1/name1, cat2/name2">` 추가
2. `render-spec-mockups.js` 가 index.md 자동 생성 (feature 태그 포함)
3. 후속 워크플로우가 index.md 를 스캔 → feature 별로 grouping → `mds_specs.md` 생성
4. spec-walker flow 의 frontmatter `feature: <cat>/<name>` → 동일 패턴으로 `spec_walk_flows.md` 생성

## 카테고리 폴더

각 카테고리 폴더에 `BLUEDOC.md` + `FEATURE_REPORT.md` + `FRESH_DOC` 3종. inspection 절차는 [FEATURE_REPORT_TEMPLATE.md](./FEATURE_REPORT_TEMPLATE.md).

## 관련

- [BLUEDOC](../infra/bluedoc/BLUEDOC.md), [FRESH_DOC](../infra/fresh-doc/BLUEDOC.md), [spec-walker](../spec-walker/BLUEDOC.md)
- [MDS flow](../../apps/mds/docs/src/lib/flow-data.ts) — 카테고리 매핑 근거
