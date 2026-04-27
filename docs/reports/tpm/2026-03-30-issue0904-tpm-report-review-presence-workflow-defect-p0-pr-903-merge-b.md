---
source_url: https://github.com/Mark-Yun/minglit/issues/904
captured_at: 2026-03-30
issue_number: 904
state: closed
labels: [P0-critical, report-exec]
author: Mark-Yun
title: "⚠️ TPM Report — 2026-03-30: review-presence 워크플로우 설계 결함 → P0 PR #903 머지 차단"
---

# ⚠️ TPM Report — 2026-03-30: review-presence 워크플로우 설계 결함 → P0 PR #903 머지 차단

> Issue #904 · closed · created 2026-03-30T12:01:52Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/904

## Body

Scheduler: exec-report-tpm

### 상황

`review-presence` 워크플로우(commit 4663ff79)가 branch protection required check으로 추가되었으나, **설계 결함으로 PR #903 (P0-critical iOS deploy fix)이 머지 차단** 상태.

**원인**:
1. `review-presence`가 `pull_request` 이벤트(PR open/sync)에서 실행 → 이 시점에 리뷰가 없으므로 **FAIL**
2. `pull_request_review` 이벤트에서 다시 실행 → 리뷰 있으므로 **PASS**
3. GitHub가 동일 이름 체크의 **두 결과를 모두 유지** — FAIL 결과가 required check를 차단
4. 결과: `ci-result` SUCCESS 임에도 `mergeStateStatus: BLOCKED`

**영향**:
- PR #903: P0-critical iOS deploy YAML heredoc fix — **4일째 배포 실패 상태의 수정 PR이 머지 불가**
- review-presence 워크플로우 "실패율" 63% (11회 중 7회 실패) — 모두 이 설계 결함에 의한 expected failure

### 판단이 필요한 이유

Branch protection settings 변경은 admin 권한이 필요하며, 워커가 자체 변경할 수 없음.

### 선택지

| 옵션 | 장점 | 단점 |
|------|------|------|
| **A: required check에서 review-presence 즉시 제거** | PR #903 즉시 언블록 | 리뷰 게이트 기능 일시 무효화 |
| B: pull_request 트리거 제거 (review/comment만 유지) | 불필요한 실패 제거 | required check이면 첫 실행 없어서 pending stuck |
| C: pull_request 이벤트에서 pass + warning만 출력 | 안정적 | 워크플로우 코드 수정 필요 |
| **D: ci-result 내부에서 review presence 확인으로 통합** | 기존 게이팅 패턴(`ci-result` 하나로 통합)과 일관 | ci-result 워크플로우 수정 필요 |

### 워커 의견

**추천: A (즉시) + D (근본 수정)**

1. **즉시**: Branch protection에서 `review-presence`를 required check에서 제거 → PR #903 언블록 → iOS deploy 복구
2. **후속**: `ci-result` job 내부에서 review presence API 호출로 리뷰 확인하는 방식으로 전환. 이렇게 하면:
   - Required check는 `ci-result` 하나로 유지 (기존 CLAUDE.md 컨벤션과 일치)
   - review-presence 워크플로우는 informational (non-required)로 유지하거나 삭제
   - `pull_request` 이벤트 timing 문제 해소

### 운영 현황 요약

| 항목 | 값 |
|------|---|
| needs-dev backlog | P0(1) P1(8) P2(8) P3(1) = 20건 |
| CI 안정성 | review-presence 제외 시 전부 양호 (실패 0건) |
| 이슈 트렌드 (7일) | 생성 30, 종료 10 |
| PR 머지 (7일) | 50+건 |
| 미아 이슈 | 0건 |
| stale 이슈 | 0건 |
| 피처 에픽 파일링 | 대상 0건 |
| Open PRs 케어 | #903 (BLOCKED), #784 (BEHIND) |

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-03-30

브랜치 프로텍션 해제함 리뷰 워커 안돌고있는것같음 
