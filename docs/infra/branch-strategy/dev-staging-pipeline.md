# Dev-Staging Pipeline

AI agent 와 feature/fix/chore PR 이 `dev-staging` 브랜치로 들어오는 진입점. 일반 PR + auto-merge 로 처리하고, `dev-staging-pr-gate` 가 가벼운 검증을 담당한다. source version bump 와 `v*-dev-staging` tag 는 PR 머지마다 만들지 않고, 하루 1회 `dev-staging-dev-cut` 이 promote 할 snapshot 에만 만든다.

## 세 가지 workflow

1. **`dev-staging-pr-gate`** — PR 머지 전
2. **`post-merge`** — PR 머지 후 dev-staging follow-up (auto-merge PR branch update + MDS triage)
3. **`dev-staging-dev-cut`** — daily cut 시점 (direct version bump commit + tag + dev promotion PR)

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
[daily dev-staging-dev-cut 이 최신 dev-staging snapshot 선별]
```

### 왜 merge queue 를 보류하나

- 현재 PR 동시성/충돌 빈도 데이터를 먼저 본다
- 운영 복잡도를 낮추고 기존 GitHub auto-merge 흐름을 재사용한다
- 필요해지면 `dev-staging` 에만 merge queue 를 후속 도입한다

### 운영 기준

- branch update 자동화는 `post-merge` 가 `sync-pr-branches` 를 `base_ref=dev-staging` 으로 호출한다.
- merge queue 도입 기준은 동시 PR 수, conflict 빈도, stale 재실행 비용을 보고 별도 판단한다.

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

## `dev-staging-dev-cut`

하루 1회 KST 02:00에 실행된다. `tag_name` 입력이 있으면 기존 `v*-dev-staging` tag 를 promote 하고, 입력이 없으면 현재 `origin/dev-staging` HEAD 에 직접 version bump commit 을 만들고 그 commit 에 tag 를 찍은 뒤 동일 SHA 를 dev 로 promote 한다.

```
1. open `cut/dev-staging-dev/*` PR 이 있으면 중복 cut 방지를 위해 skip
2. `origin/dev-staging` HEAD 가 이미 `dev` 에 포함되어 있으면 skip
3. HEAD 에 기존 `vYY.MM.DD+BUILD-dev-staging` tag 가 있으면 재사용
4. tag 가 없으면 KST 날짜로 versionName `YY.MM.DD-dev-staging` 계산
5. build number `YYMMDDNN` 계산 (`NN` = 같은 날짜 snapshot sequence)
6. release bot 이 protected `dev-staging` 에 version bump commit 을 fast-forward push
7. 같은 commit 에 tag `vYY.MM.DD+YYMMDDNN-dev-staging` 생성
8. tag SHA 에서 `cut/dev-staging-dev/YYYY-MM-DD-{sha8}` branch 생성
9. dev promotion PR 생성 + auto-merge(merge commit, snapshot ancestry 보존)
```

Protected `dev-staging` 직접 push 는 human 금지다. 예외는 `minglit-release-bot` 이 `dev-staging-dev-cut` 안에서 version bump commit 을 fast-forward push 하는 경우뿐이다. push 가 거부되면 dev-staging 이 cut 중 변경된 것이므로 새 HEAD 기준으로 다음 run 에서 다시 계산한다.

Tag `vYY.MM.DD+{build}-dev-staging` 는 dev promotion PR, deploy metadata, RC/main artifact version 이 같은 coherent snapshot 을 가리키게 하는 anchor 다.

> **구현 결정**: source PR 번호와 version-bump PR 번호는 build number 로 쓰지 않는다. PR 번호는 생성 순서라 merge/promote 순서를 보장하지 않는다. build number 는 promote 된 snapshot 의 KST 날짜 + sequence (`YYMMDDNN`) 로 계산한다.

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
