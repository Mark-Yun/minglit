# Agent Conventions

## Project Entry

작업 시작 시 루트 [BLUEDOC.md](BLUEDOC.md)를 먼저 읽고, 작업 영역의 가장 가까운 `BLUEDOC.md`를 따라간다.

BLUEDOC은 폴더의 진입점과 이정표다. 상세 정책, 아키텍처, 빌드/테스트 명령은 BLUEDOC이 링크한 원문 문서를 기준으로 삼고, AGENTS.md에 중복해서 유지하지 않는다.

## Core Maps

항상 먼저 확인할 핵심 지도:

| 문서 | 용도 |
|------|------|
| [docs/infra/bluedoc/BLUEDOC.md](docs/infra/bluedoc/BLUEDOC.md) | BLUEDOC 정의, 50줄 제한, freshness 규칙 |
| [docs/infra/graphify/BLUEDOC.md](docs/infra/graphify/BLUEDOC.md) | graphify 지식 그래프 사용/자동 갱신 |
| [docs/infra/branch-strategy/BLUEDOC.md](docs/infra/branch-strategy/BLUEDOC.md) | 브랜치/릴리즈/Ruleset/release bot 정책 |
| [.github/BLUEDOC.md](.github/BLUEDOC.md) | GitHub Actions, PR gate, review setup, sync/deploy workflow |
| [apps/BLUEDOC.md](apps/BLUEDOC.md) | Flutter 앱/랜딩/MDS 진입점 |
| [shared/packages/minglit_kit/BLUEDOC.md](shared/packages/minglit_kit/BLUEDOC.md) | 공용 클라이언트 패키지 |
| [supabase/BLUEDOC.md](supabase/BLUEDOC.md) | Supabase backend, migrations, Edge Functions |
| [docs/features/BLUEDOC.md](docs/features/BLUEDOC.md) | 제품 feature PRD/spec/CUJ 문서 |

## Graphify

- 아키텍처/코드베이스 질문 전에는 `graphify-out/GRAPH_REPORT.md`의 god node와 community 구조를 먼저 확인한다.
- cross-module 관계 질문은 가능하면 `graphify query`, `graphify path`, `graphify explain`을 우선 사용한다.
- `graphify-out/` 갱신은 `.github/workflows/sync-graphify.yml`가 담당한다. 코드/문서 수정 후에도 로컬에서 수동 `graphify update .`를 돌리지 않고, graph 산출물을 커밋하지 않는다.

## Branch / PR

- 일반 작업 PR base는 `dev-staging`이다. 세부 정책은 [branch-strategy](docs/infra/branch-strategy/BLUEDOC.md)와 [.github](.github/BLUEDOC.md)를 따른다.
- PR 생성 후 auto-merge를 켜고, 머지될 때까지 CI/리뷰/branch 상태를 확인한다.
- protected branch 직접 push, Ruleset bypass, release bot 권한은 branch strategy 원문 문서를 따른다. `--admin` bypass는 사용자가 명시적으로 요청한 경우에만 사용한다.

## Implementation Rules

- 버그 수정은 원인 분석을 우선하고, 가능하면 재현 테스트를 추가한다.
- 새 migration은 `supabase/BLUEDOC.md`와 backend 문서를 따른다. dev/main에 머지된 migration은 수정하지 않고 새 migration으로 보정한다.
- Flutter 앱(app_user/app_partner)은 **동결** 상태다 ([web-mvp-pivot](docs/architecture/web-mvp-pivot.md)) — 신규 기능 개발/배포 금지. 예외적으로 빌드가 필요하면 debug/dev 환경을 기본으로 하고, 상세 명령과 Java 버전은 앱 BLUEDOC과 기존 build 문서를 따른다.
- 변경 후 필요한 테스트는 [docs/qa/automation-test-guide.md](docs/qa/automation-test-guide.md)와 각 영역 BLUEDOC 기준으로 선택한다.
