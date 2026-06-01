# MDS Audit Report - 2026-05-31

> 주간 MDS 정합성 audit runbook + 결과 로그. `FRESH_DOC` cycle 트리거로 agent 가 실행하고, 발견 사항마다 GitHub Issue 를 파일링한다.

## Agent Contract

이 문서를 실행하는 agent 는 다음을 완료해야 한다.

1. 입력 수집 명령을 실행하고 결과를 evidence 로 남긴다.
2. finding 을 `spec-collision`, `spec-missing`, `impl-missing`, `cuj-gap`, `render-gap` 중 하나로 분류한다.
3. 각 finding 마다 신규 또는 기존 GitHub Issue 1건에 연결한다. 같은 root cause 가 아니면 묶지 않는다.
4. 연결한 issue 번호를 Action Items 에 기록한다.
5. 해결되었거나 중복된 기존 issue 는 `Resolved / Superseded` 섹션으로 이동한다.
6. 마지막에 실행한 명령, 실패한 명령, 잔여 리스크를 Verification 에 기록한다.

## Scope

본 리포트는 `apps/mds/docs` 를 기준으로 다음 정합성을 점검한다.

| Area | 질문 |
|---|---|
| Spec collision | 같은 화면/컴포넌트의 spec 과 live code 가 서로 다른 UI, route, state, token 을 말하는가? |
| Spec missing | Flutter 구현은 존재하지만 대응하는 MDS screen/component spec 이 없는가? |
| Implementation missing | MDS spec 은 존재하지만 Flutter 구현 또는 route/surface 가 없는가? |
| CUJ gap | 핵심 사용자 여정이 PRD/spec/CUJ 문서나 integration test 로 추적되지 않는가? |
| Render gap | `public/specs/<screen>/index.html` 이 있지만 state PNG 또는 emulator render coverage 가 비어 있는가? |

## Weekly AI Job

### Step 1. Inputs

```bash
gh issue list --state open --label report-exec --limit 100 --json number,title,labels,url,updatedAt > /tmp/mds_report_exec.json
gh issue list --state open --search "mds OR spec in:title,body repo:Mark-Yun/minglit" --limit 100 --json number,title,labels,url,updatedAt > /tmp/mds_search.json
dart run scripts/mds_render_coverage.dart --json > /tmp/mds_render_coverage.json
dart run scripts/cuj_coverage.dart --json > /tmp/cuj_coverage.json
find apps/mds/docs/public/specs -maxdepth 2 -name index.html | sort > /tmp/mds_specs.txt
sed -n '1,280p' apps/mds/docs/src/lib/flow-data.ts > /tmp/mds_flow_data.txt
rg -n "path:|TypedGoRoute|GoRoute|RouteData" apps/app_user/lib/src/routing/app_routes.dart apps/app_partner/lib/src/routing/app_routes.dart > /tmp/mds_routes.txt
rg -n "TBD|stub|단독 route 없음|MinglitAvatarImage|CircleAvatar|TODO|Implementation follow-up" apps/mds/docs/public/specs apps/app_user/lib apps/app_partner/lib
```

### Step 2. Classify Findings

| Class | Filing rule |
|---|---|
| `spec-collision` | Spec 과 live code 가 서로 다른 route/state/token/component 를 주장 |
| `spec-missing` | Live Flutter surface 또는 widget 이 있는데 MDS spec 없음 |
| `impl-missing` | MDS spec 이 있는데 route/widget/provider 구현 없음 |
| `cuj-gap` | 핵심 CUJ 가 docs/features 또는 integration test 로 추적되지 않음 |
| `render-gap` | state PNG 또는 emulator render 가 없어 시각 비교 불가 |

### Step 3. File Issues

각 finding 마다 GitHub Issue 1건을 연결한다. 먼저 기존 open issue 를 찾고, 없을 때만 새 이슈를 만든다. 신규 생성 또는 기존 issue 연결 없이 리포트에 finding 을 남기지 않는다.

```bash
gh issue list \
  --state open \
  --search "\"<screen-or-component>\" \"<class>\" repo:Mark-Yun/minglit" \
  --json number,title,labels,url
```

기존 issue 가 있으면 중복 생성하지 않고 Action Items 에 기존 번호와 최신 evidence 를 기록한다. 기존 issue 의 범위가 너무 넓으면 새 이슈를 만들고 body 에 related issue 를 명시한다.

```bash
gh issue create \
  --title "[mds-audit/<class>] <screen-or-component> - <summary>" \
  --label "report-exec" \
  --body "<evidence + expected + suggested action>"
```

Label rule:

| Case | Labels |
|---|---|
| Spec 수정 / 사람 판단 필요 | `report-exec` |
| Spec 과 code 중 source of truth 판단 필요 | `report-exec`, `needs-arch` |
| 아키텍처·공통 contract 판단 필요 | `report-exec`, `needs-arch` |
| 구현만 남은 후속 작업 | `needs-swe` |
| CUJ/문서 작성 작업 | `docs` + 필요한 owner label |

Spec 수정은 인간이 판단해야 하므로 audit job 은 `needs-swe` 를 붙이지 않는다. `needs-swe` 는 별도 구현 이슈를 만들 때만 사용한다.

Issue body 는 아래 구조를 사용한다.

```md
## Finding
<무엇이 불일치/누락인지 한 단락>

## Evidence
- Spec: <path 또는 URL>
- Code: <path>
- Coverage: <명령 출력 요약>

## Expected
<spec/code/CUJ 중 어느 쪽이 source of truth 인지와 기대 상태>

## Suggested Action
<작업자가 바로 시작할 수 있는 구체 action>

## Report
Generated from apps/mds/docs/reports/audit-report.md
```

### Step 4. Update This Report

- Summary count 갱신
- Action Items 에 issue 번호 기록
- 이미 해결된 항목은 `Resolved / superseded` 로 이동
- 중복으로 확인된 항목은 `Resolved / Superseded` 로 이동하고 canonical issue 를 적는다
- 검증 명령과 잔여 리스크 기록

### Step 5. Do Not Fix Inline

이 job 의 목적은 audit + filing 이다. 작은 문구 수정처럼 audit 수행 중 바로 고칠 수 있어 보여도, 같은 PR 에 섞지 않는다. 예외는 본 리포트/FRESH_DOC 자체의 오탈자와 stale issue 번호 정리뿐이다.

## Summary

| Severity | Count | Issues |
|---|---:|---|
| P0 - Critical | 0 | - |
| P1 - Defect / Gap | 2 | #2412, #2404 |
| P2 - Improvement | 4 | #2399, #2407, #2409, #2421 |
| P3 - Low | 2 | #2913, #2917 |

## Action Items

### P1 - Defect / Gap

- [ ] **#2412** `spec-missing` `TicketSelectionSheet` - 결제 진입 gate sheet 구현은 있으나 MDS spec 부재. **Action**: live code 기준으로 screen/sheet spec 추가.
- [ ] **#2404** `spec-collision` `event_application_review_page` - spec 은 widget TBD 로 표기하지만 실제 구현 완료. **Action**: 구현 기준으로 spec stale 영역 갱신.

### P2 - Improvement

- [ ] **#2399** `spec-collision` `blocked_partners/my_page/home_page/event_detail` - spec 은 `CircleAvatar`, code 는 `MinglitAvatarImage`. **Action**: MDS component contract 로 spec 정렬.
- [ ] **#2407** `spec-collision` `components.ts visualSpec` - `MinglitButton` 외 legacy HTML visualSpec 정리 필요. **Action**: 컴포넌트 manifest 와 실제 spec surface 정합성 정리.
- [ ] **#2409** `spec-collision` `event_detail_page` - 참가 현황 caption 과 gauge 의미가 충돌. **Action**: 티켓 판매/참여 인원 semantics 를 분리.
- [ ] **#2421** `spec-collision` `partner AppBar info_outline` - 여러 spec 의 "모든 화면" claim 과 실제 적용 범위 불일치. **Action**: 적용 범위와 예외 surface 정리.

### P3 - Low / Infra

- [ ] **#2913** `render-gap` MDS render coverage summary - 20 screens + incomplete states. **Action**: 주간 report 에 coverage delta 반영.
- [ ] **#2917** `render-gap` state PNG capture workflow - 실제 state PNG 자동화 workflow 부재. **Action**: render automation 구현 후 report evidence 로 사용.

## Current Notes

- `event_matching_results_screen` spec 정렬은 PR #2918 로 merge 완료.
- 구현은 #2919 에서 처리한다. 핵심 요구: full contact reveal, single/multi card 분기, 연락처 저장 CTA, loading reveal motion.
- CUJ 문서화는 #2920 에서 처리한다. 핵심 경로: 결과 보기, 연락처 저장, no-match CTA.

## Resolved / Superseded

- #2411 `spec-collision` `event_matching_results_screen` - PR #2918 에서 spec 정렬 완료. 구현 후속은 #2919, CUJ 후속은 #2920 으로 분리.

## Verification

최근 실행:

```bash
npm run lint
git diff --check
curl -I http://localhost:3003/specs/event_matching_results_screen/index.html
```

결과:

- `npm run lint`: pass, 기존 warning 1건 (`src/lib/flow-data.ts:216 _app unused`)
- `git diff --check`: pass
- local spec URL: `200 OK`
