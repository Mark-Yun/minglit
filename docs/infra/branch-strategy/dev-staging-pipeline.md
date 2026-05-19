# Dev-Staging Pipeline

AI agent 와 feature/fix/chore PR 이 `dev-staging` 브랜치로 들어오는 진입점. merge queue 가 직렬 처리하고, `dev-staging-pr-gate` 가 가벼운 검증, 머지 후 `dev-staging-post-merge-sync` 가 version bump.

## 두 가지 workflow

1. **`dev-staging-pr-gate`** — PR 머지 전 (merge queue 가 각 PR rebase 후 실행)
2. **`dev-staging-post-merge-sync`** — PR 머지 직후 (version bump + tag)

## Merge Queue

GitHub merge queue 가 `dev-staging` 의 PR 을 직렬 처리:

```
[PR enqueue]
    ↓
[PR base 를 최신 dev-staging HEAD 로 rebase]
    ↓
[dev-staging-pr-gate 재실행 (rebased state)]
    ↓
[통과 시 squash merge to dev-staging]
    ↓
[dev-staging-post-merge-sync 자동 발동]
    ↓
[다음 PR 처리]
```

### 왜 merge queue

- Master-green 유지 (Uber Submit Queue: 99%+)
- Drift / conflict accumulation 회피
- AI agent 가 동시 다발 PR 작성해도 안전하게 직렬 처리
- "Update branch" 수동 작업 제거

### 결정해야 할 것

- 모드 (concurrent vs serial)
- queue stuck 시 escalation
- 도입 단계 (전체 vs 점진)

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

## `dev-staging-post-merge-sync`

PR 머지 직후 자동 발동.

```
1. bump-version.sh {PR번호}-dev-staging  # 8개 파일 version 일괄 업데이트
2. git commit -m "chore: bump version to v{ver}-dev-staging [skip ci]"
3. git tag v{ver}-dev-staging
4. git push (tag + commit)
```

Tag `v{ver}-dev-staging` 는 다음 단계의 `nightly-cut` workflow 가 query 해서 "가장 최근 dev-staging 의 coherent snapshot" 찾는 데 사용.

> **구현 디테일**: bump 커밋이 별도로 만들어지는 게 깔끔 vs squash 커밋에 inline 시키는 게 깔끔 — workflow 디자인 결정 (TBD).

## Error-Backoff

**Workflow infra 실패** (merge queue 다운, runner 다운, script 에러) → **P0 이슈** + on-call.

**Test 실패** (PR 단위) → queue 가 PR drop + 작성자 알림. 작성자 fix → re-queue.

### `expand-migrate-contract` false positive

destructive pattern 검출이 too aggressive 한 경우:
- 우선 bypass label 부여 + reviewer 확인
- 분기별 retrospective 에서 검출 룰 개선

## 결정해야 할 것

- merge queue 모드 (concurrent / serial)
- `expand-migrate-contract` 의 6-month-old schema 보관 위치
- `flag-registration` AST 도구 (analyzer / 자체 / Semgrep?)
- version bump commit 별도 vs inline

## 관련

- [dev-pipeline.md](./dev-pipeline.md) — dev-staging 의 snapshot 이 dev 로 어떻게 promote
- [test-strategy.md](./test-strategy.md) — 단계별 게이트 큰 그림
- [branch-flow.md](./branch-flow.md) — protection + tag

---
_Reviewed: 2026-05-19 09:47_
