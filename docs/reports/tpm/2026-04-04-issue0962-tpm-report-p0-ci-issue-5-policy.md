---
source_url: https://github.com/Mark-Yun/minglit/issues/962
captured_at: 2026-04-04
issue_number: 962
state: closed
labels: [report-exec]
author: Mark-Yun
title: "⚠️ TPM Report — 2026-04-04: P0 CI 이슈 5건 트리아지 + 에픽 정리 + 환불 정책 리마인더"
---

# ⚠️ TPM Report — 2026-04-04: P0 CI 이슈 5건 트리아지 + 에픽 정리 + 환불 정책 리마인더

> Issue #962 · closed · created 2026-04-04T04:26:49Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/962

## Body

Scheduler: tpm-exec-report

## Executive Summary

**7월 출시 D-88**. 지난 주 account-deletion/signup-consent 에픽 대부분 완료 (30+ PR 머지). 이번 주는 docs/테스트 커버리지로 전환. **P0 CI 인프라 이슈 5건이 3/30부터 5일째 열려 있어 트리아지 필요.**

## 1. 🔴 P0 CI-Failure 이슈 트리아지 (사람 판단 필요)

5건 모두 3/30 발생. 일부는 이미 수정 PR이 머지되어 **닫을 수 있는 상태**로 추정.

| # | 이슈 | 판단 | 근거 |
|---|------|------|------|
| #916 | Daily Backend Simulation | **ACTIVE** | 4/3까지 계속 실패 코멘트. #950(adb 인프라)과 동일 원인 |
| #914 | Deploy Supabase Migrations | **닫기 가능** | #897(deno.json 누락) 수정 후 코멘트 없음 = 재발 없음 |
| #906 | Seed Dev | **확인 필요** | 3/31 이후 코멘트 없음. 해결됐을 가능성 높음 |
| #899 | iOS Deploy Partner | **닫기 가능** | #901(YAML heredoc 에러) 수정 후 활동 없음 |
| #898 | iOS Deploy User | **닫기 가능** | 동일 |

**권고**: #914, #899, #898 닫기. #906 최근 실행 확인 후 닫기. #916은 #950과 합쳐서 인프라 결정.

## 2. 🟡 Open PR 현황 (3건)

| PR | 상태 | 필요 조치 |
|----|------|----------|
| #942 (golden tests) | CI 실패 | #953(P1 needs-dev) 수정 필요 |
| #937 (dependabot flutter-deps) | CI 실패 + BEHIND | #959(P1 needs-dev) 선행 필요 |
| #784 (dependabot CI actions) | BEHIND → **브랜치 업데이트 완료** | CI 재실행 대기 |

## 3. 🟢 에픽 정리

| 에픽 | 판단 |
|------|------|
| #876 account-deletion | 서브이슈 대부분 완료. **닫을 수 있는지 확인 필요** |
| #875 signup-consent | 동일 |
| #846 partner-terms-privacy | #847(마지막 서브이슈) 이미 닫힘. **에픽 닫기 가능** |

## 4. ⏳ 사람 판단 대기 이슈

| # | 제목 | 대기 기간 | 필요 판단 |
|---|------|----------|----------|
| #765 | 환불 정책 약관-코드 불일치 | **6일** (3/29~) | 법률 검토 완료. Mark가 최종 정책 확정 → needs-dev로 코드+약관 수정 |
| #950 | CUJ 테스트 5일 연속 adb 실패 | 5일 | GitHub Actions 런너 인프라. 워크플로우 수정 or 비활성화 |

**#765는 법적 리스크(전자상거래법 위반 가능성)로 우선 확정 권고.**

## 5. 이번 주 dev-worker 우선순위

1. **#959** (P1, bug) — PR #937 블로커. google_sign_in 7.x / flutter_local_notifications 21.x breaking API 마이그레이션
2. **#953** (P1, bug) — PR #942 블로커. golden test LateInitializationError
3. **#954** (P1, enhancement) — app_user 골든 테스트 추가
4. **#955** (P2) — minglit_kit Repository 유닛 테스트
5. **#951** (P2) — 하드코딩 색상 디자인 토큰 교체

## 6. 이번 사이클 자체 조치

- ✅ PR #784 브랜치 업데이트 완료
- ✅ 모든 열린 이슈 우선순위 라벨 확인 완료 (미라벨 0건)
- ✅ #847 상태 확인 → 이미 닫힘 (에픽 #846 닫기 가능)

## Comments (4)

### Comment 1 — @Mark-Yun on 2026-04-04

🤖 TPM Cycle 3 업데이트:

**신규 조치:**
- 버그 리포트 4건 트리아지: #964(P1), #965(P1), #966(P2→needs-uiux), #970(P1)
- 중복 PR 5건 발견 → 정리 코멘트 (#963, #967, #968)
- #973 P0→P2 다운그레이드
- PR #969 브랜치 업데이트 완료

**신규 report-exec:** #974 — 중복 PR 반복 패턴 에스컬레이션

### Comment 2 — @Mark-Yun on 2026-04-05

🤖 **tpm-exec-report-claude-subagents** 리마인드: 이 report-exec 이슈가 **2일 이상 대기 중**입니다 (생성: 04-04).

사람 판단이 필요한 항목입니다. 확인 부탁드립니다.

### Comment 3 — @Mark-Yun on 2026-04-06

🤖 **tpm-exec-report-claude-subagents** 리마인드 — 이 이슈가 4일째 열려있습니다. 사람 판단이 필요한 항목입니다. 확인 부탁드립니다.

### Comment 4 — @Mark-Yun on 2026-04-08

🤖 **needs-tpm-claude-1** — 5일 경과. 리포트에서 언급된 P0 CI 이슈들(#916, #914 등)은 이미 모두 닫힘. CI 현재 건강 (최근 30 runs 실패 0건).

리포트가 더 이상 유효하지 않으므로 닫습니다.
