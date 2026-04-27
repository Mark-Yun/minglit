---
source_url: https://github.com/Mark-Yun/minglit/issues/767
captured_at: 2026-03-29
issue_number: 767
state: closed
labels: [P0-critical, report-exec, needs-tpm]
author: Mark-Yun
title: "⚠️ TPM Report — 2026-03-29: dev 브랜치 보호 규칙 변경으로 전체 PR 머지 차단"
---

# ⚠️ TPM Report — 2026-03-29: dev 브랜치 보호 규칙 변경으로 전체 PR 머지 차단

> Issue #767 · closed · created 2026-03-29T13:28:25Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/767

## Body

### 상황

dev 브랜치 보호 규칙에서 `required_approving_review_count`가 **1**로 설정되어 있습니다.
CLAUDE.md에는 "Approvals 불필요 (0개). self-merge 가능"으로 명시되어 있어 **설정과 문서가 불일치**합니다.

현재 열린 PR 5개(#748, #756, #757, #758, #766) 모두 `REVIEW_REQUIRED`로 auto-merge가 차단된 상태입니다.
CodeRabbit의 `COMMENTED` 리뷰는 approval로 인정되지 않습니다.

또한 `dismiss_stale_reviews: true`로 설정되어 있어, 브랜치 업데이트 시 기존 approval도 무효화됩니다.

### 판단이 필요한 이유

브랜치 보호 규칙은 repo admin 권한이 필요하며, 워커가 자체 변경할 수 없습니다.

### 선택지

| 옵션 | 장점 | 단점 |
|------|------|------|
| A. `required_approving_review_count`를 0으로 변경 | CLAUDE.md와 일치, self-merge 복구, AI worker 자율 운영 | 리뷰 없이 머지 가능 |
| B. CLAUDE.md를 업데이트하여 1개 승인 필요로 변경 | 코드 리뷰 강제, 품질 게이트 강화 | AI worker PR이 수동 승인 필요, 처리 속도 저하 |
| C. CodeRabbit을 APPROVE 리뷰로 변경 | 자동 리뷰 + 자동 승인 | CodeRabbit 설정 변경 필요 |

### 워커 의견

**옵션 A 권장**. 현재 출시 전 개발 단계에서 AI worker의 자율 운영이 중요합니다. 5개 PR이 이미 적체되어 있고, 이 상태가 지속되면 개발 속도가 크게 저하됩니다. 옵션 C도 대안이 될 수 있습니다.

### 영향받는 PR
- #748 `feat(minglit_kit): MinglitEmptyState + MinglitErrorState 위젯`
- #756 `feat(golden): render tree dump으로 자동 UI 간격 분석 지원`
- #757 `feat(my_tickets): MyTicketsPage + MyTicketCard UI 구현`
- #758 `feat(home): EventNowBarState 상태 머신 + Controller`
- #766 `fix(worker): PR 케어 — 이슈번호 없는 브랜치 fallback 추가`

## Comments (3)

### Comment 1 — @Mark-Yun on 2026-03-29

/needs-tpm approval 0으로 되돌림

### Comment 2 — @Mark-Yun on 2026-03-29

🤖 **issue-worker** 상태 업데이트

현재 **13개 열린 PR**이 모두 `BLOCKED` 상태입니다.
`required_approving_review_count=1` + `dismiss_stale_reviews=true` 조합으로, 브랜치 업데이트 시 기존 approval도 무효화되어 auto-merge가 불가능합니다.

영향받는 PR: #748, #756, #757, #758, #766, #769, #770, #773, #774, #775, #777, #779

`required_approving_review_count`를 0으로 변경하면 즉시 해소됩니다.

### Comment 3 — @Mark-Yun on 2026-03-29

🤖 **issue-worker** DONE

`required_approving_review_count`가 0으로 복원 확인. 현재 13개 열린 PR의 CI가 재실행 중이며, 통과 시 auto-merge가 진행됩니다.
