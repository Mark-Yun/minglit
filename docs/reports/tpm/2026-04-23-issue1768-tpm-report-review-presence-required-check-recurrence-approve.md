---
source_url: https://github.com/Mark-Yun/minglit/issues/1768
captured_at: 2026-04-23
issue_number: 1768
state: open
labels: [report-exec]
author: Mark-Yun
title: "⚠️ TPM Report — 2026-04-23: review-presence required check 재발, approved PR 머지 블록"
---

# ⚠️ TPM Report — 2026-04-23: review-presence required check 재발, approved PR 머지 블록

> Issue #1768 · open · created 2026-04-23T04:24:51Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1768

## Body

Scheduler: needs-tpm-claude-1

## 현상

Branch protection required check `review-presence`가 **여전히 활성화되어 있음** (`ci-result` + `review-presence`) — 하지만 CLAUDE.md에는 "Required check: `ci-result`" 하나만 명시되어 있어 실제 브랜치 프로텍션과 문서가 괴리.

이 때문에 approved PR이 `mergeStateStatus: BLOCKED`로 고착되는 운영 드래그가 재발 중:

- #1767, #1764: 오늘 발견, 승인된 상태에서 4+시간 block → TPM이 failed check-run을 `gh run rerun`으로 직접 복구 후 머지
- #1766: 같은 원인 + 다른 테스트 pending 중, review-presence는 복구됨

## 근본 원인

`review-presence` 워크플로우의 구조적 결함. 2026-03-30 #904 에서 동일 이슈 보고 → Mark가 브랜치 프로텍션 일시 해제 → 이후 재활성화되었으나 워크플로우는 미수정 상태.

**메커니즘**:
1. PR `opened` 이벤트 → review 없으므로 `review-presence` FAIL (예상된 동작)
2. Reviewer approve → `pull_request_review` 이벤트로 다시 실행 → SUCCESS
3. GitHub branch protection이 첫 FAILURE check-run을 계속 require 차단 사유로 유지
4. 수동 `gh run rerun <failed-run-id>` 로만 해소됨

최근 7일 `review-presence` 워크플로우 failure율: 6/94 ≈ 6%. 전부 이 구조적 결함에 의한 expected failure.

## 영향

- Approve된 PR이 평균 수 시간 추가 대기 (워커가 재실행 인지하기 전까지)
- 여러 워커가 라벨을 잘못 재추가하는 2차 드래그 발생 (어제 #1767 에서 worker 간 needs-review 라벨 ping-pong 4회 확인)
- CLAUDE.md 문서와 실제 gating 정책 불일치 — 신규 워커 온보딩 혼선

## 선택지

#904에서 제시했던 옵션과 동일, 추가 옵션 포함:

| 옵션 | 장점 | 단점 |
|------|------|------|
| A: Branch protection에서 `review-presence` 즉시 제거 (#904 방식 반복) | 즉시 언블록 | 리뷰 게이트가 `ci-result` 내부 CodeRabbit만 남아 인적 리뷰 미강제. 또 같은 상황 재발 우려 |
| **B: `ci-result` job 내부에 review-presence 로직 통합** | Required check 1개 유지 (CLAUDE.md 일치), 문서·실제 일치 | `ci-result` 워크플로우 수정 필요 (sonnet 1~2h) |
| C: `review-presence` 워크플로우에서 `pull_request.opened` 시점엔 `core.warning` 후 exit 0 | 최소 변경 | 신규 PR이 승인 전에도 pass 상태가 되는 시간 창 발생 |
| D: 현상 수용 + TPM/SWE 워커 루틴에 "approve된 BLOCKED PR에 `gh run rerun` 실행" 단계 추가 | 개발 리소스 불필요 | 근본 해결 아님, 운영 비용 지속 |

## 워커 의견

**추천: B (근본 수정)**.

`review-presence.yml` 의 check 로직 (formalReviews 또는 reviewer completion comment 검사)을 `ci-result.yml` 의 한 step으로 이식하고, `review-presence` 워크플로우는 삭제하거나 informational로 강등. 이후 branch protection에서 `review-presence` required 제거 (Admin 권한 필요).

**즉시 조치**: 현재 BLOCKED 상태의 approved PR이 또 있으면 TPM이 주기적으로 `gh run rerun` 실행. (오늘 #1767, #1766, #1764 에 대해 조치 완료 → #1767, #1764 머지됨)

## 질문

- Mark, 옵션 B로 진행해도 될지 판단 부탁드립니다. 진행한다면 `needs-swe` 이슈 생성하겠습니다.
- 단기적으로 `review-presence`를 required에서 제외할지? (#904 처럼 일시 해제) — 오늘처럼 승인된 PR이 쌓이는 걸 방지하기 위함.


## Comments (1)

### Comment 1 — @Mark-Yun on 2026-04-24

🤖 **tpm-exec-report-claude-subagents** 후속 증빙 (2026-04-24):

이슈 제기 후에도 동일 문제 재발:

**사례**: PR #1815 (fix(#1803): More screen SafeArea) — 5회 APPROVED + ci-result SUCCESS + 이후 review-presence 5회 SUCCESS 임에도 PR이 BLOCKED 상태 지속. 원인은 2026-04-23 21:26에 `pull_request` 이벤트로 실행된 초기 review-presence run (ID 24859699733)이 FAILURE로 고착되어 branch protection이 풀리지 않음.

**조치**: TPM이 `gh run rerun 24859699733`으로 수동 복구. 재실행 SUCCESS → mergeState BLOCKED → UNKNOWN으로 해제. 이게 #1768에서 언급한 "TPM이 failed check-run을 수동 rerun으로 직접 복구" 패턴의 4번째 재발.

**누적 운영 드래그**: 03-30 (#904) → 04-23 (#1767/#1764/#1766) → 04-24 (#1815). 한 달 이내 최소 5 PR이 이 구조적 이슈로 수시간~하루 지연. AI worker 사이클이 이 패턴에 시간을 소모.

**요청**: #1768 선택지 중 옵션 B (ci-result job 내부에 review-presence 로직 통합)를 채택하면 required check 1개로 통일되어 root cause 제거. Mark의 결정 부탁드립니다.
