---
source_url: https://github.com/Mark-Yun/minglit/issues/1509
captured_at: 2026-04-16
issue_number: 1509
state: closed
labels: [ci-failure, P0-critical, report-exec]
author: app/github-actions
title: "🚨 iOS Deploy Partner failed on dev"
---

# 🚨 iOS Deploy Partner failed on dev

> Issue #1509 · closed · created 2026-04-16T11:05:18Z · author @app/github-actions
> https://github.com/Mark-Yun/minglit/issues/1509

## Body

**Workflow**: iOS Deploy Partner
**Branch**: dev
**Commit**: f3521fee81bdc59c404598fb231a744daa777a26
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24506442351
**Triggered by**: N/A
**Actor**: Mark-Yun

**Job Results**:
  ❌ ios-deploy: failure

## Comments (2)

### Comment 1 — @github-actions on 2026-04-17

**Workflow**: iOS Deploy Partner
**Branch**: dev
**Commit**: b5e18a10f3d1022372b6a9689de97c4eec5b05bc
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24561282267
**Triggered by**: N/A
**Actor**: Mark-Yun

**Job Results**:
  ❌ ios-deploy: failure

### Comment 2 — @Mark-Yun on 2026-04-18

## 분석 완료 — #1484와 동일 원인 (App Store Connect 계약 만료)

### 실제 원인
\`\`\`
ERROR: [altool] A required agreement is missing or has expired. (403)
  iris-code: FORBIDDEN.REQUIRED_AGREEMENTS_MISSING_OR_EXPIRED
\`\`\`
App Store Connect 계약 상태 문제. Developer secrets / 인증서 / keychain 무관. CI 코드 수정으로 해결 불가능한 관리자 action 필요 이슈.

### 상태
- 마지막 성공: 2026-04-11
- 첫 실패: **2026-04-12**부터 연속 실패 (User보다 3일 먼저 — Partner 앱이 먼저 새 업로드 필요했을 가능성)
- **2026-04-18 관리자(@Mark-Yun)가 App Store Connect에서 agreement 업데이트 완료**

### 검증
다음 scheduled run (~10:48 UTC daily)에서 #1484와 함께 성공 시 자연 해소. 재발 시 재오픈.
