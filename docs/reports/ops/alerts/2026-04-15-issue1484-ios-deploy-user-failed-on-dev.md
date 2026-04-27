---
source_url: https://github.com/Mark-Yun/minglit/issues/1484
captured_at: 2026-04-15
issue_number: 1484
state: closed
labels: [ci-failure, P0-critical, report-exec]
author: app/github-actions
title: "🚨 iOS Deploy User failed on dev"
---

# 🚨 iOS Deploy User failed on dev

> Issue #1484 · closed · created 2026-04-15T12:22:00Z · author @app/github-actions
> https://github.com/Mark-Yun/minglit/issues/1484

## Body

**Workflow**: iOS Deploy User
**Branch**: dev
**Commit**: 863b9f91d3930e1472667ba3e20a441255a66dd7
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24453895631
**Triggered by**: N/A
**Actor**: Mark-Yun

**Job Results**:
  ❌ ios-deploy: failure

## Comments (4)

### Comment 1 — @Mark-Yun on 2026-04-16

🤖 **tpm-exec-report-claude-subagents** — #1433 (iOS Deploy Partner)과 동일 패턴. GitHub Secrets 설정 대기 중. report-exec 부착.

### Comment 2 — @github-actions on 2026-04-16

**Workflow**: iOS Deploy User
**Branch**: dev
**Commit**: f3521fee81bdc59c404598fb231a744daa777a26
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24506413991
**Triggered by**: N/A
**Actor**: Mark-Yun

**Job Results**:
  ❌ ios-deploy: failure

### Comment 3 — @github-actions on 2026-04-17

**Workflow**: iOS Deploy User
**Branch**: dev
**Commit**: b5e18a10f3d1022372b6a9689de97c4eec5b05bc
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24561229605
**Triggered by**: N/A
**Actor**: Mark-Yun

**Job Results**:
  ❌ ios-deploy: failure

### Comment 4 — @Mark-Yun on 2026-04-18

## 분석 완료 — Apple Developer secrets 아닌 App Store Connect 계약 만료 문제

### 실제 원인
\`\`\`
ERROR: [altool] A required agreement is missing or has expired. (403)
  iris-code: FORBIDDEN.REQUIRED_AGREEMENTS_MISSING_OR_EXPIRED
  links: see = \"/business\"
\`\`\`
App Store Connect의 **Paid/Free Apps Agreement 만료 또는 미서명**. Developer secrets / 인증서 / keychain은 모두 정상 동작 (altool 호출 자체는 통과, 서버가 403 반환).

### 상태
- 마지막 성공: 2026-04-14
- 첫 실패: **2026-04-15**부터 연속 실패
- **2026-04-18 관리자(@Mark-Yun)가 App Store Connect에서 agreement 업데이트 완료**

### 검증
다음 scheduled run (~10:47 UTC daily)에서 성공 시 자연 해소. 이슈는 선제적으로 close — 재발 시 재오픈.

동일 원인으로 #1509 (iOS Deploy Partner)도 함께 해소될 것으로 예상.

### 원래 TPM 리포트의 추정 보정
본 이슈를 포함했던 #1543 (이미 close)의 \"iOS deploy 2건은 동일 원인(Apple secrets)\" 추정은 **오진**. Apple secrets/인증서가 아니라 **App Store Connect 계약 상태** 문제였음. 향후 iOS deploy 403 발생 시 에러 메시지의 \`iris-code\` 필드를 먼저 확인 권장.
