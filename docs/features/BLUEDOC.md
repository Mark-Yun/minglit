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
| `spec.md` | 사람 (architect/PM) | feature 의 단일 진실 소스. 양면이면 user-side / partner-side 섹션 분리 |
| `mds_specs.md` | 워크플로우 derived | 이 feature 가 사용하는 MDS 화면 목록 + index.md 본문 |
| `spec_walk_flows.md` | 워크플로우 derived | 이 feature 를 cover 하는 spec-walker flow 목록 |

UX 디자인의 SSoT 는 MDS spec (`apps/mds/docs/public/specs/`). feature 폴더의 `mds_specs.md` 는 derived view. `ui-ux-design.md` 와 `wireframe.html` 은 사용하지 않는다 (Mark 가 MDS HTML 에 작성, 워크플로우가 feature 로 grouping).

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
