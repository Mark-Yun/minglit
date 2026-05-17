# .github/

GitHub 통합 폴더 — CI/CD 워크플로우, composite actions, shell scripts, 의존성 자동화, 릴리스 노트 설정.

## 이정표

| 항목 | 무엇 |
|---|---|
| [`workflows/`](./workflows/BLUEDOC.md) | GitHub Actions 워크플로우 (`pr-gate`, `pr-setup`, `pr-review-setup`, `deploy`, `monitor`, `sync`, `triage`, `tool`, `shared` prefix) |
| [`actions/`](./actions/BLUEDOC.md) | 워크플로우가 `uses:` 로 호출하는 composite actions (deploy-flutter-app, deploy-nextjs-app, ios-deploy) |
| [`scripts/`](./scripts/BLUEDOC.md) | 워크플로우가 `bash` 로 실행하는 shell 헬퍼 (env 파일 생성, CUJ 실행 등) |
| [`dependabot.yml`](./dependabot.yml) | dependabot 의존성 자동 업데이트 설정 (npm + GitHub Actions 그룹화, weekly) |
| [`release.yml`](./release.yml) | GitHub Release notes 자동 생성 카테고리 (Features/Bug Fixes/Refactor/Docs) |

## 핵심 컨벤션

- **워크플로우는 9 prefix 중 하나** (pr-gate / pr-setup / pr-review-setup / deploy / monitor / sync / triage / tool / shared) — [`workflows/BLUEDOC.md`](./workflows/BLUEDOC.md) 참고.
- **재사용 가능한 step 묶음은 `actions/` composite 로 분리**, 단순 명령 묶음은 `scripts/` 로.
- **dependabot 은 patch/minor 자동 머지** (pr-review-setup 의 dependabot 분기), major 는 수동.

## 관련

- [CLAUDE.md](../CLAUDE.md) — PR Conventions, Branch Protection, Auto-Merge 흐름
- [BLUEDOC 컨벤션](../docs/infra/bluedoc/BLUEDOC.md)

---
_Reviewed: 2026-05-17 22:32_
