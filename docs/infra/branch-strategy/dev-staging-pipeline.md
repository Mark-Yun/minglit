# Dev-Staging Pipeline

AI agent 와 feature/fix/chore PR 이 `dev-staging` 브랜치로 들어오는 진입점. 일반 PR + auto-merge 로 처리하고, `dev-staging-pr-gate` 가 가벼운 검증, 머지 후 `dev-staging-dev-cut-gate` 가 version-bump PR 을 생성한다.

## 두 가지 workflow

1. **`dev-staging-pr-gate`** — PR 머지 전
2. **`dev-staging-dev-cut-gate`** — PR 머지 직후 (version-bump PR 생성, merge 후 tag)

## PR + Auto-Merge

초기 모델에서는 merge queue 를 쓰지 않는다. PR 은 `dev-staging-pr-gate` 통과 후 auto-merge 로 squash merge 된다. base drift 는 strict status checks 와 자동 branch update 로 처리한다.

```
[PR open]
    ↓
[dev-staging-pr-gate]
    ↓
[auto-merge 대기]
    ↓
[base drift 발생 시 branch update 후 gate 재실행]
    ↓
[통과 시 squash merge to dev-staging]
    ↓
[dev-staging-dev-cut-gate 자동 발동]
```

### 왜 merge queue 를 보류하나

- 현재 PR 동시성/충돌 빈도 데이터를 먼저 본다
- 운영 복잡도를 낮추고 기존 GitHub auto-merge 흐름을 재사용한다
- 필요해지면 `dev-staging` 에만 merge queue 를 후속 도입한다

### 결정해야 할 것

- branch update 자동화 방식 (`gh api update-branch` vs 기존 sync-pr-branches 재사용)
- merge queue 도입 기준 (동시 PR 수, conflict 빈도, stale 재실행 비용)

## `dev-staging-pr-gate`

빠른 PR 게이트. 10분 안에 끝나는 검사만.

| Check | 도구 | 비고 |
|-------|------|------|
| `test-flutter-apps` | Flutter test (matrix: app_user, app_partner) | unit + widget test |
| `lint-landing-user` | npm lint + build | |
| `lint-landing-partner` | npm lint + build | |
| `test-supabase` | pgTAP | DB function test |
| `test-edge-functions` | Deno test | EF unit test |
| `check-migration-versions` | shell script | duplicate / gap 검사 |
| **`expand-migrate-contract`** | shell + 패턴 매칭 (Safety Net) | destructive op 탐지 |
| **`flag-registration-check`** | AST 분석 (Safety Net) | 새 코드 path 가 flag SDK 참조 |
| `gitleaks` | secret scanning | |
| CodeRabbit | AI review | 최대 30분 대기 |

### Safety Net: `expand-migrate-contract`

**정책**: 6개월 backward compat (6 mobile releases). DB schema 만 검증 (Option C — API contract test 는 TBD).

| 탐지 | Bypass |
|------|--------|
| `DROP COLUMN`, `DROP TABLE`, `ALTER COLUMN TYPE` 등 destructive SQL pattern | `-- migration-phase: contract` 주석 + 라벨 `migration-contract-justified` + min-version 변경 확인 + 별도 reviewer |

**구현**: `supabase/migrations/*.sql` 파일 grep + AST. 초기엔 정규식 기반 (false positive 가능 → bypass label 자주 쓰임 → 점진 개선).

**현재 상태**: TODO — CI script 작성 + destructive pattern list + 6-month-old client schema 어디 보관할지.

### Safety Net: `flag-registration-check`

새 코드 path 가 flag SDK 를 reference 하지 않으면 PR fail.

| 영역 | 검출 패턴 |
|------|----------|
| Backend (EF) | 새 request handler 가 `Statsig.checkGate` or `RemoteConfig.getValue` 미참조 |
| Mobile (Flutter) | 새 화면/feature widget 같음 (mobile SDK) |
| Web (landing) | 새 endpoint 같음 |

| Bypass | 조건 |
|--------|------|
| `// no-flag: reason` 주석 + 라벨 `unflagged-justified` + 별도 reviewer | infra / security / bug-fix 에 한정 |

**현재 상태**: TODO — AST 검출 로직 + 예외 라벨 운영 룰 + 분기별 우회 통계.

## `dev-staging-dev-cut-gate`

PR 머지 직후 자동 발동. 운영 복구용으로 `workflow_dispatch` 도 제공하며, 수동 실행 시 version 을 찍을 snapshot SHA 를 입력할 수 있다.

```
1. KST 기준 날짜로 versionName 계산: `YY.MM.DD-dev-staging`
2. 기존 open `version-bump/dev-staging/*` PR 이 있으면 stale 로 close
3. 임시 version bump branch 생성 후 PR 생성
4. 생성된 version-bump PR 번호를 build number 로 사용해 branch commit amend
5. `dev-staging-pr-gate` 통과 시 auto-merge
6. merge commit 에 tag `vYY.MM.DD+{version-bump PR#}-dev-staging` 생성
```

Protected `dev-staging` 에 직접 bump commit 을 push 하지 않는다. release bot 은 version-bump branch push, PR 생성/auto-merge, tag push 에만 사용한다.

Tag `vYY.MM.DD+{build}-dev-staging` 는 다음 단계의 `dev-staging-dev-cut` workflow 가 query 해서 "가장 최근 dev-staging 의 coherent snapshot" 찾는 데 사용.

> **구현 결정**: source PR 번호는 build number 로 쓰지 않는다. GitHub PR 번호는 생성 순서라 merge 순서를 보장하지 않기 때문이다. version-bump PR 번호만 build number 로 사용한다.

## Error-Backoff

**Workflow infra 실패** (runner 다운, script 에러, release bot push 실패) → **P0 이슈** + on-call.

**Test 실패** (PR 단위) → auto-merge 보류 + 작성자 알림. 작성자 fix → re-run.

### `expand-migrate-contract` false positive

destructive pattern 검출이 too aggressive 한 경우:
- 우선 bypass label 부여 + reviewer 확인
- 분기별 retrospective 에서 검출 룰 개선

## 결정해야 할 것

- branch update 자동화 방식
- `expand-migrate-contract` 의 6-month-old schema 보관 위치
- `flag-registration` AST 도구 (analyzer / 자체 / Semgrep?)
- dev-staging version bump retry/backoff 정책

## 관련

- [dev-pipeline.md](./dev-pipeline.md) — dev-staging 의 snapshot 이 dev 로 어떻게 promote
- [test-strategy.md](./test-strategy.md) — 단계별 게이트 큰 그림
- [branch-flow.md](./branch-flow.md) — protection + tag

---
_Reviewed: 2026-05-23 16:18_
