---
source_url: https://github.com/Mark-Yun/minglit/issues/1434
captured_at: 2026-04-13
issue_number: 1434
state: closed
labels: [ci-failure, P1-high, report-exec]
author: app/github-actions
title: "🚨 Android Deploy Partner failed on dev"
---

# 🚨 Android Deploy Partner failed on dev

> Issue #1434 · closed · created 2026-04-13T11:15:53Z · author @app/github-actions
> https://github.com/Mark-Yun/minglit/issues/1434

## Body

**Workflow**: Android Deploy Partner
**Branch**: dev
**Commit**: f08ffe863c2e9b56575b2ce7400f31617e03d96e
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24340401341
**Triggered by**: N/A
**Actor**: Mark-Yun

## Comments (11)

### Comment 1 — @Mark-Yun on 2026-04-14

🤖 **tpm-exec-report-claude-subagents**: P0-critical CI 실패 미라우팅 발견. `needs-swe` 라벨 부착합니다. Android Deploy Partner 실패 원인 조사 + 수정 필요.

### Comment 2 — @Mark-Yun on 2026-04-14

🤖 **needs-swe-sonnet-subagents-1** 작업 시작합니다.

### Comment 3 — @Mark-Yun on 2026-04-14

Scheduler: needs-swe-sonnet-subagents-1

## 진단 결과

**Root cause**: `JUSO_CONFIRM_KEY` GitHub Actions secret이 설정되어 있지 않음.

```
deploy / build — Validate JUSO key for partner:
  JUSO_CONFIRM_KEY:   ← 빈 값
  JUSO_CONFIRM_KEY is required for partner deploy.
  ##[error]Process completed with exit code 1.
```

`gh secret list` 결과에서도 `JUSO_CONFIRM_KEY` secret 자체가 존재하지 않음을 확인했습니다.

## 필요 조치

#1433과 동일한 원인입니다. `JUSO_CONFIRM_KEY` secret 추가 시 두 워크플로우 모두 해결됩니다.

`report-exec` 라벨로 변경합니다.

### Comment 4 — @github-actions on 2026-04-14

**Workflow**: Android Deploy Partner
**Branch**: dev
**Commit**: 98ec28e4dd67b149acf08ceb22e6c1a3936b1d0a
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24395281918
**Triggered by**: N/A
**Actor**: Mark-Yun

### Comment 5 — @Mark-Yun on 2026-04-15

## 원인

\`JUSO_CONFIRM_KEY\` GitHub Secret이 비어있거나 미설정.

```
JUSO_CONFIRM_KEY: 
JUSO_CONFIRM_KEY is required for partner deploy.
##[error]Process completed with exit code 1.
```

파트너 앱 빌드 시 주소 검색 API(행정안전부 도로명주소) 키가 필요한데 Secret이 없음.

## 수정

GitHub repo Settings → Secrets → `JUSO_CONFIRM_KEY` 값 설정 필요. 사람(Mark) 확인 필요.

### Comment 6 — @Mark-Yun on 2026-04-15

GitHub Secret `JUSO_CONFIRM_KEY` 등록 완료. 워크플로우 재실행함.

### Comment 7 — @Mark-Yun on 2026-04-15

## 후속 작업

### needs-qa
- 배포 워크플로우에서 필수 Secret 검증하는 테스트 케이스 추가
- `docs/qa/test-cases/` 또는 CI 문서에 배포 시 필요한 Secret 목록 명시 (JUSO_CONFIRM_KEY 등)

### needs-swe
- 워크플로우 재실행 결과 모니터링
- 통과 확인 후 이슈 닫기
- #1433 (iOS Deploy Partner) 동일 — 함께 확인

### Comment 8 — @Mark-Yun on 2026-04-15

🤖 **needs-qa-claude-1** 작업 시작합니다. (#1433과 동일 QA 태스크 — 함께 처리)

### Comment 9 — @Mark-Yun on 2026-04-15

🤖 **needs-qa-claude-1** QA 작업 완료.

PR #1460에서 #1433과 함께 처리. 동일 산출물 참고.

`needs-qa` 라벨 제거합니다.

### Comment 10 — @Mark-Yun on 2026-04-15

🤖 **needs-swe-sonnet-subagents-1** Android Partner 배포 ✅ 성공 확인 (run 24340401341). JUSO_CONFIRM_KEY 등록 후 정상 빌드/배포됨. needs-swe 작업 완료. needs-qa 결과 대기 중인 PR #1460 확인 필요.

### Comment 11 — @Mark-Yun on 2026-04-15

JUSO_CONFIRM_KEY 등록 + Android Deploy 성공 확인. 이슈 닫음.
