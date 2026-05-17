---
source_url: https://github.com/Mark-Yun/minglit/issues/545
captured_at: 2026-03-27
issue_number: 545
state: closed
labels: [P1-high, report-exec]
author: Mark-Yun
title: "⚠️ TPM Report — 2026-03-28: iOS deploy 지속 실패 + ci-failure 이슈 주간 45건"
---

# ⚠️ TPM Report — 2026-03-28: iOS deploy 지속 실패 + ci-failure 이슈 주간 45건

> Issue #545 · closed · created 2026-03-27T23:04:19Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/545

## Body

## 주간 운영 분석 (2026-03-21 ~ 2026-03-28)

### 이슈/PR 트렌드

| 지표 | 이번 주 | 지난 주 (#488) |
|------|---------|---------------|
| PR 머지 | 50건 | 48건 |
| ci-failure 이슈 | 45건 | 40건+ |
| 열린 이슈 | 15건 (P0:1, P1:3, P2:4, P3:7) | 24건 |

### 🔴 핵심 발견 1: iOS deploy 여전히 100% 실패

전주 #488에서 플래그했으나 **해결되지 않음**. 최근 10회 실행 전부 failure.

| 날짜 | 브랜치 | 결론 |
|------|--------|------|
| 3/27 18:08 | dev | failure |
| 3/27 17:32 | fix/issue-486 | failure |
| 3/27 17:26 | fix/issue-486 | failure |
| 3/27 17:05 | dev | failure |
| 3/27 16:59~16:40 | fix/issue-484 (3회) | failure |
| 3/27 16:23 | dev | failure |
| 3/27 16:18 | feat/523-checkin-tab | failure |
| 3/27 16:12 | dev | failure |

**영향**: iOS 앱 배포 완전 차단. 7월 출시 목표 대비 iOS 빌드/배포 파이프라인 검증이 불가능한 상태.

**필요 조치** (사람): Apple Developer 계정/인증서/프로비저닝 프로파일 점검. CI secrets 확인 필요.

### 🟡 핵심 발견 2: Daily Backend Simulation 실패

- 이슈 #542 (open)
- **Root cause**: `flutter test integration_test/` 명령이 integration/unit test를 단일 호출로 실행 → Flutter가 거부
- issue-worker가 수정 가능한 수준

### ✅ 안정화된 영역

| 워크플로우 | 성공률 | 비고 |
|-----------|--------|------|
| Hourly User Activity | 6/6 (100%) | 전주 불안정 → 안정화 |
| Deploy to Vercel | 4/4 (100%) | 안정 |
| CI (PR checks) | 2/2 (100%) | 안정 |
| Version Bump | 2/2 (100%) | 전주 실패 → 수정됨 |
| Auto Format PR | 3/3 (100%) | 안정 |

### 🔵 ci-failure 이슈 볼륨

주간 45건 자동 생성. 대부분 자동 모니터링 봇이 생성→자동 종료. **실질적 인프라 문제는 iOS deploy 1건**이며 나머지는 일시적 실패 후 자동 복구됨.

### 💡 제안

1. **iOS deploy**: 수동 조치 필요. Apple 인증서/프로비저닝 확인 후 테스트 실행. 해결 전까지 iOS deploy 워크플로우 비활성화 검토 (불필요한 ci-failure 이슈 생성 방지).
2. **ci-failure 이슈 노이즈**: iOS deploy 실패가 반복적으로 ci-failure 이슈를 생성. 워크플로우 비활성화 시 주간 ci-failure 이슈 수가 크게 감소할 것으로 예상.

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-03-28

## TPM Report #545 분석 결과

### 1. iOS deploy 100% 실패 → phantom run (실제 문제 아님)

#488 분석과 동일. `ios-deploy-reusable.yml`이 push 이벤트에 phantom run 생성.
- 실제 caller(`deploy-ios-user.yml`, `deploy-ios-partner.yml`)는 schedule로 **정상 실행 중**
- 근본 해결: #550 (composite action 전환)에서 처리 예정

### 2. Daily Backend Simulation 실패 → 수정 완료

- **원인**: `flutter test integration_test/` — Flutter 3.x에서 integration/unit test 단일 호출 금지
- **수정**: PR #551에서 개별 파일 순차 실행으로 전환 + partner 앱 graceful skip 처리
- **상태**: ✅ MERGED

### 3. ci-failure 이슈 45건 → iOS phantom run 노이즈

대부분 iOS deploy phantom failure가 생성하는 자동 이슈. #550 해결 시 대폭 감소 예상.
