# Dev Soak Status Model

`dev-rc-cut-gate` 는 테스트를 직접 실행하는 workflow 가 아니라, dev HEAD 가 RC cut source 로 충분히 안정적인지 판정하는 evaluator 다. 판정의 source-of-truth 는 GitHub Issue 가 아니라 **commit status context** 와 workflow run history 다. Issue 는 사람이 보는 incident/audit surface 로만 사용한다.

## Source Of Truth

| 데이터 | 역할 | SSOT 여부 |
|--------|------|-----------|
| Commit status | soak failure/pass marker. `dev-rc-cut-gate` 가 직접 판정에 사용 | yes |
| Workflow run history | monitor 가 실제로 충분히 돌았는지 확인 | yes |
| GitHub Issue | 로그, 담당, 원인, 후속 조치 기록 | no |
| GitHub label | 사람이 보는 분류/필터 | no |

SHA, PR number, run id, version 은 label 로 만들지 않는다. Label 은 repo-wide category 로만 유지한다.

## Status Write API

Workflow 와 AI agent 는 commit status context 를 직접 하드코딩하지 않고 stage별 status write workflow 를 사용한다.

| Workflow | 공개 범위 | 역할 |
|----------|----------|------|
| `shared-set-commit-status` | internal reusable | `sha`, `context`, `state`, `description`, `target_url` 를 받아 GitHub commit status 를 작성 |
| `set-dev-soak-status` | public API (`workflow_call` + `workflow_dispatch`) | `signal` 을 `dev-soak/*` context 로 매핑한 뒤 `shared-set-commit-status` 호출 |
| `set-rc-soak-status` | public API (`workflow_call` + `workflow_dispatch`) | `signal` 을 `rc-soak/*` context 로 매핑한 뒤 `shared-set-commit-status` 호출 |

외부 consumer 는 `shared-set-commit-status` 를 직접 호출하지 않는다. 공통 writer 는 context 를 검증하지 않는 low-level primitive 이므로, 사람이 직접 쓰면 stage/signal naming 을 우회할 수 있다.

### `set-dev-soak-status`

입력:

| Input | 값 |
|-------|----|
| `signal` | `backend-simulator` \| `real-device` \| `app-ai-review` |
| `state` | `failure` \| `success` \| `pending` |
| `sha` | status 를 붙일 commit SHA |
| `target_url` | workflow run, artifact, screenshot, AI review 결과 URL |
| `description` | status 설명 (GitHub UI 에 노출) |

Signal mapping:

| Signal | Context |
|--------|---------|
| `backend-simulator` | `dev-soak/backend-simulator` |
| `real-device` | `dev-soak/real-device` |
| `app-ai-review` | `dev-soak/app-ai-review` |

사용 예:

```bash
gh workflow run set-dev-soak-status.yml \
  -f signal=app-ai-review \
  -f state=failure \
  -f sha=<dev-commit-sha> \
  -f description="settings screen layout regression"
```

### `set-rc-soak-status`

RC soak 는 dev soak 와 signal set 이 달라질 수 있으므로 별도 entry workflow 로 둔다.

초기 signal mapping:

| Signal | Context |
|--------|---------|
| `backend-simulator` | `rc-soak/backend-simulator` |
| `real-device` | `rc-soak/real-device` |
| `dogfooding` | `rc-soak/dogfooding` |

`rc-main-cut-gate` 는 나중에 `rc-soak/*` status 와 RC run history 를 읽어 `rc-main-cut-pass` 를 판정한다.

## Commit Status Contexts

| Context | 작성자 | 실패 시점 | 성공 시점 | 의미 |
|---------|--------|-----------|-----------|------|
| `dev-soak/backend-simulator` | `set-dev-soak-status` via `monitor-event-flow-*` / `dev-rc-cut-gate` | event-flow simulator 실패 즉시 `failure` | `dev-rc-cut-gate` 가 24h run history 를 확인한 뒤 `success` | backend/event-flow soak signal |
| `dev-soak/real-device` | `set-dev-soak-status` via real-device workflow / `dev-rc-cut-gate` | Firebase Test Lab 또는 실디바이스 smoke 실패 즉시 `failure` | `dev-rc-cut-gate` 가 required run/signal 을 확인한 뒤 `success` | 실제 디바이스 안정성 signal |
| `dev-soak/app-ai-review` | `set-dev-soak-status` via AI agent / `dev-rc-cut-gate` | AI/human 앱 소킹 중 blocker 발견 즉시 `failure` | `dev-rc-cut-gate` 가 AI review pass signal 을 확인한 뒤 `success` | screenshot/UX/manual-ish app soak signal |
| `dev-rc-cut-pass` | `dev-rc-cut-gate` | 작성하지 않음 | 모든 dev soak 조건 통과 시 `success` | RC cut source marker |

실패 status 는 발견 즉시 찍는다. 성공 status 는 각 monitor 가 매번 찍지 않고, cut 직전 evaluator 인 `dev-rc-cut-gate` 가 검증 완료 후 찍는다.

## Labels

Issue label 은 분류용이다. Gate 판정에는 사용하지 않는다.

| Label | 용도 |
|-------|------|
| `release-blocker` | release 관련 blocker incident |
| `dev-soak` | dev soak window 에서 발견 |
| `backend-simulator` | event-flow/backend simulator 계열 |
| `real-device` | Firebase Test Lab/실디바이스 계열 |
| `app-soak` | AI/human 앱 소킹 계열 |
| `P0-critical`, `P1-high` | 우선순위 |

금지: `candidate-sha-*`, `commit-*`, `run-*`, `pr-*` 같은 동적 label.

## Soak Window

기본 정책은 **latest `origin/dev` HEAD 만 평가**한다.

1. `candidate_sha = origin/dev HEAD`
2. `candidate_since = candidate_sha` 가 dev 에 들어온 시각
3. `now - candidate_since >= 24h`
4. candidate 이후 dev 에 새 commit 이 들어오면 candidate 와 soak clock 은 reset

여러 candidate 를 동시에 추적하지 않는다. Snapshot model 이므로 최신 dev HEAD 만 RC source 후보가 된다.

## Run History Verification

`dev-rc-cut-gate` 는 GitHub Actions run history 로 "soak 이 실제로 돌았는지" 검증한다.

| Signal | 최소 조건 |
|--------|-----------|
| `monitor-event-flow-distributed` | `candidate_since` 이후 `success` run >= 250 |
| legacy `monitor-event-flow-hourly/daily` | 수동 smoke 전용. gate run requirement 에서 제외 |
| real-device smoke | candidate 기준 required run/signal success >= 1 (workflow 이름 TBD) |
| app AI review | AI agent 가 candidate 기준 pass signal 제공 (workflow/status 입력 방식 TBD) |

예시 조회:

```bash
gh run list \
  --workflow monitor-event-flow-distributed.yml \
  --branch dev \
  --created ">=2026-05-24T00:00:00Z" \
  --json databaseId,status,conclusion,createdAt,headSha
```

Scheduled workflow 의 `headSha` 는 실행 시점의 `dev` HEAD 다. 따라서 run 의 `headSha` 가 candidate 와 다르면 latest candidate 가 바뀐 것으로 보고 그 run 은 현재 candidate 의 soak 증거로 쓰지 않는다.

## Failure Recording

`shared-notify` 는 실패를 발견한 workflow 의 공통 issue/log recorder 로 확장한다. Commit status 는 `set-dev-soak-status` 를 통해 기록한다.

필요 입력:

| Input | 예시 | 용도 |
|-------|------|------|
| `stage` | `dev-soak` | issue 제목/metadata |
| `signal` | `backend-simulator` | status context suffix |
| `severity` | `P1-high` | label/제목 |
| `blocks_rc_cut` | `true` | commit status failure 작성 여부 |
| `commit_sha` | `${{ github.sha }}` | status target |

실패 시 동작:

1. `set-dev-soak-status` 를 호출해 status context `dev-soak/{signal}` 을 `failure` 로 설정
2. Issue 생성/갱신 (`release-blocker`, `dev-soak`, signal label, severity label)
3. Issue body 에 workflow/run/commit/PR 정보와 failed log tail 을 첨부

Issue body 에는 machine-readable metadata 를 남긴다. 단, gate 판정은 이 metadata 를 SSOT 로 사용하지 않는다.

```md
<!-- minglit-release-signal
stage: dev-soak
signal: backend-simulator
workflow: monitor-event-flow-distributed
branch: dev
commit: abc123...
run_id: 263...
severity: P1-high
blocks_rc_cut: true
-->
```

## `dev-rc-cut-gate` Evaluation

`dev-rc-cut-gate` 는 schedule 또는 manual dispatch 로 동작한다. `push to dev` 직후 즉시 pass 를 찍지 않는다.

평가 순서:

1. `candidate_sha = origin/dev HEAD`
2. candidate age 가 24h 이상인지 확인
3. required monitor run history 가 candidate 기준으로 충분한지 확인
4. candidate 의 최신 commit status 중 아래 context 가 `failure` 인지 확인:
   - `dev-soak/backend-simulator`
   - `dev-soak/real-device`
   - `dev-soak/app-ai-review`
5. 모두 통과하면 각 `dev-soak/*` status 를 `success` 로 찍고 `dev-rc-cut-pass` 를 `success` 로 찍는다

실패 또는 미충족 시 `dev-rc-cut-pass` 는 쓰지 않는다.

## Permissions

Commit status 를 직접 관리하는 actor 는 GitHub App token 을 사용한다.

| Actor | 필요 권한 |
|-------|-----------|
| `shared-notify` / monitor workflows | Commit statuses: read/write, Issues: read/write |
| AI agent status writer | Commit statuses: read/write, Issues: read/write |
| `dev-rc-cut-gate` | Commit statuses: read/write, Actions: read, Contents: read |

Human 은 로컬에서 release bot token 을 사용하지 않는다. AI agent 가 app soak failure/pass 를 기록할 때도 같은 status context naming 을 따라야 한다.

---
_Reviewed: 2026-05-24 13:05_
