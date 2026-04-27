---
source_url: https://github.com/Mark-Yun/minglit/issues/1433
captured_at: 2026-04-13
issue_number: 1433
state: closed
labels: [ci-failure, P0-critical, report-exec]
author: app/github-actions
title: "🚨 iOS Deploy Partner failed on dev"
---

# 🚨 iOS Deploy Partner failed on dev

> Issue #1433 · closed · created 2026-04-13T11:14:26Z · author @app/github-actions
> https://github.com/Mark-Yun/minglit/issues/1433

## Body

**Workflow**: iOS Deploy Partner
**Branch**: dev
**Commit**: f08ffe863c2e9b56575b2ce7400f31617e03d96e
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24340304424
**Triggered by**: N/A
**Actor**: Mark-Yun

**Job Results**:
  ❌ ios-deploy: failure

## Comments (13)

### Comment 1 — @Mark-Yun on 2026-04-14

🤖 **tpm-exec-report-claude-subagents**: P0-critical CI 실패 미라우팅 발견. `needs-swe` 라벨 부착합니다. iOS Deploy Partner 실패 원인 조사 + 수정 필요.

### Comment 2 — @Mark-Yun on 2026-04-14

🤖 **needs-swe-sonnet-subagents-1** 작업 시작합니다.

### Comment 3 — @Mark-Yun on 2026-04-14

Scheduler: needs-swe-sonnet-subagents-1

## 진단 결과

**Root cause**: `JUSO_CONFIRM_KEY` GitHub Actions secret이 설정되어 있지 않음.

```
ios-deploy:
  JUSO_CONFIRM_KEY:   ← 빈 값
  JUSO_CONFIRM_KEY is required for partner deploy.
  ##[error]Process completed with exit code 1.
```

`gh secret list` 결과에서도 `JUSO_CONFIRM_KEY` secret 자체가 존재하지 않음을 확인했습니다.

## 필요 조치

GitHub Actions secret에 `JUSO_CONFIRM_KEY` 를 추가해야 합니다:
- 경로: GitHub → Settings → Secrets and variables → Actions → New repository secret
- Name: `JUSO_CONFIRM_KEY`
- Value: 한국 도로명주소 개발자센터 (juso.go.kr)에서 발급한 Confirm Key

수정 후 workflow를 재실행하면 정상 빌드됩니다.

`report-exec` 라벨로 변경합니다.

### Comment 4 — @github-actions on 2026-04-14

**Workflow**: iOS Deploy Partner
**Branch**: dev
**Commit**: 98ec28e4dd67b149acf08ceb22e6c1a3936b1d0a
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24395165776
**Triggered by**: N/A
**Actor**: Mark-Yun

**Job Results**:
  ❌ ios-deploy: failure

### Comment 5 — @Mark-Yun on 2026-04-15

동일 원인: `JUSO_CONFIRM_KEY` Secret 미설정. #1434 에서 등록 완료. 워크플로우 재실행함.

### Comment 6 — @Mark-Yun on 2026-04-15

## 후속 작업

### needs-qa
- #1434 와 동일: 배포 Secret 검증 테스트 케이스 추가

### needs-swe
- 워크플로우 재실행 결과 모니터링 (JUSO_CONFIRM_KEY 등록 완료)
- 통과 확인 후 이슈 닫기

### Comment 7 — @github-actions on 2026-04-15

**Workflow**: iOS Deploy Partner
**Branch**: dev
**Commit**: f08ffe863c2e9b56575b2ce7400f31617e03d96e
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24340304424
**Triggered by**: N/A
**Actor**: Mark-Yun

**Job Results**:
  ❌ ios-deploy: failure

### Comment 8 — @Mark-Yun on 2026-04-15

🤖 **needs-qa-claude-1** 작업 시작합니다.

### Comment 9 — @Mark-Yun on 2026-04-15

🤖 **needs-qa-claude-1** QA 작업 완료.

## 산출물

- PR #1460: 배포 파이프라인 Secret 검증 테스트 케이스 추가
  - `docs/qa/test-cases/ci-deploy-tests.md` — 4개 워크플로우 필수 Secret 매트릭스 + 19건 검증 시나리오
  - `docs/qa/test-strategy.md` — §8.1 CI/CD 섹션 추가

## 식별된 개선 제안 (needs-swe)

1. `JUSO_CONFIRM_KEY`가 reusable workflow에서 `required: false`이나 partner 빌드 시 실질 필수 → `required: true`로 변경 권장
2. Apple 인증서/프로비저닝 만료 모니터링 워크플로우 부재
3. User 앱에서 JUSO API 사용 여부 확인 필요

`needs-qa` 라벨 제거합니다. `needs-swe`는 워크플로우 재실행 모니터링 + 위 개선 사항 처리를 위해 유지.

### Comment 10 — @Mark-Yun on 2026-04-15

Scheduler: needs-swe-sonnet-subagents-1

## 상태 업데이트

**Android Partner** (이슈 #1434): ✅ 성공 (JUSO_CONFIRM_KEY 등록 후 재실행, run 24340401341)

**iOS Partner** (이 이슈): ❌ 새로운 에러 발생 — Apple Developer Program 동의 만료

```
A required agreement is missing or has expired.
FORBIDDEN.REQUIRED_AGREEMENTS_MISSING_OR_EXPIRED (403)
```

## 조치 필요 (사람)

JUSO_CONFIRM_KEY 문제는 해결됐지만, IPA 업로드 단계에서 Apple 동의서 미서명 에러가 발생합니다.

1. https://developer.apple.com/account 또는 https://appstoreconnect.apple.com 접속
2. 팝업으로 표시되는 새 약관/계약서 확인 및 서명
3. 이후 iOS Partner Deploy 워크플로우 재실행

이 이슈는 Mark가 직접 처리해야 합니다.

### Comment 11 — @github-actions on 2026-04-15

**Workflow**: iOS Deploy Partner
**Branch**: dev
**Commit**: 8a0f10796feefb5482ea1d98d04bc5baec42a73e
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24450558402
**Triggered by**: N/A
**Actor**: Mark-Yun

**Job Results**:
  ❌ ios-deploy: failure

### Comment 12 — @Mark-Yun on 2026-04-15

## 업데이트

JUSO_CONFIRM_KEY는 해결됨 (빌드 통과). iOS 실패는 **별도 원인**:

```
Error: A required agreement is missing or has expired.
code=FORBIDDEN.REQUIRED_AGREEMENTS_MISSING_OR_EXPIRED
```

**Apple Developer 계약 갱신 필요.** App Store Connect → Agreements → 새 약관 동의 필요.

코드/CI 문제 아님 → `report-exec` (사람 확인).

### Comment 13 — @github-actions on 2026-04-15

**Workflow**: iOS Deploy Partner
**Branch**: dev
**Commit**: 863b9f91d3930e1472667ba3e20a441255a66dd7
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24453899334
**Triggered by**: N/A
**Actor**: Mark-Yun

**Job Results**:
  ❌ ios-deploy: failure
