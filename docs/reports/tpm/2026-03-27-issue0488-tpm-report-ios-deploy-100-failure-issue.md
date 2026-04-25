---
source_url: https://github.com/Mark-Yun/minglit/issues/488
captured_at: 2026-03-27
issue_number: 488
state: closed
labels: [P1-high, report-exec]
author: Mark-Yun
title: "⚠️ TPM Report — 2026-03-27: iOS deploy 100% 실패 + 이슈 소화율 급락"
---

# ⚠️ TPM Report — 2026-03-27: iOS deploy 100% 실패 + 이슈 소화율 급락

> Issue #488 · closed · created 2026-03-27T07:03:46Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/488

## Body

## 주간 운영 분석 (2026-03-20 ~ 2026-03-27)

### 이슈/PR 트렌드

| 지표 | 이번 주 | 지난 주 (#450) |
|------|---------|--------------|
| 이슈 생성 | 30건 | 100건 |
| 이슈 종료 | 7건 (23%) | 91건 (91%) |
| 미해결 이슈 | 24건 누적 | - |
| PR 머지 | 48건 | 44건 |
| 기여자 | Mark-Yun (AI worker) | Mark-Yun, dependabot |

### 🔴 핵심 발견 1: iOS deploy 100% 실패

`ios-deploy-reusable.yml` 최근 10회 실행 **전부 failure**.

| 브랜치 | 실패 횟수 |
|--------|----------|
| dev | 4회 |
| fix/issue-474 | 2회 |
| fix/issue-449 | 2회 |
| fix/issue-453 | 1회 |
| chore/prompt-refactor | 1회 |

- 기존 report-exec #450은 Vercel/CUJ/Android를 다루며, iOS는 언급 없음
- 모든 브랜치에서 실패 → 특정 코드 문제가 아닌 **인프라/설정 문제** 가능성
- 📌 **수동 확인 필요**: signing certificate, provisioning profile, App Store Connect 설정 등

### 🟡 핵심 발견 2: 이슈 소화율 급락 (91% → 23%)

- 지난 주 91% close rate → 이번 주 23% (7/30)
- 현재 미해결 이슈 24건 누적 중
- PR 머지 속도(48건)는 유지되지만, 이슈 해결과 연결되지 않는 PR이 많음
- 원인 추정: audit 워커가 이슈를 대량 생성하는 반면, issue-worker 처리 속도가 따라가지 못함

### CI 안정성 요약

| 결과 | 건수 | 비율 |
|------|------|------|
| success | 30 | 60% |
| failure | 10 | 20% (전부 iOS deploy) |
| skipped | 8 | 16% |
| cancelled | 2 | 4% |

- `ci-result` (required check) 실패는 없음 — PR 머지에는 영향 없음
- iOS deploy만 100% 실패 — 별도 워크플로우이므로 머지 게이트에는 무영향

### 권장 조치

1. **[수동 필요]** iOS deploy 워크플로우 실패 원인 조사 — signing, provisioning, Xcode 버전 등 인프라 레벨 확인
2. **[검토 필요]** audit 워커 이슈 생성 속도 vs issue-worker 처리 속도 밸런스 조정 — 현재 이슈 누적 추세
3. 기존 #450 조치사항과 병행하여 배포 워크플로우 전반 안정화

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-03-27

## iOS Deploy 실패 분석 결과

### 원인: phantom run (실제 빌드 실패 아님)

`ios-deploy-reusable.yml`은 `on: workflow_call`만 정의된 reusable workflow인데, GitHub Actions가 모든 push에서 워크플로우 파일 파싱을 시도하면서 "workflow file issue"로 즉시 실패하는 phantom run이 발생.

```
# reusable (phantom — 100% 실패)
23638725247 event=push branch=dev       ← 직접 트리거 불가, 즉시 실패
23638682351 event=push branch=refactor  ← 동일
```

### 실제 iOS 빌드는 정상

caller 워크플로우(`ios-deploy-user.yml`, `ios-deploy-partner.yml`)는 schedule(매일 KST 19:00)로 정상 실행 중:

```
# ios-deploy-user.yml (실제 빌드)
23590169924 success event=schedule branch=dev
23536855113 success event=schedule branch=dev
23485345999 success event=schedule branch=dev
23433391804 success event=schedule branch=dev
23400956765 success event=schedule branch=dev   ← 최근 5회 전부 success
```

### 결론

- **iOS 빌드/배포 정상** — signing, provisioning, App Store Connect 문제 없음
- TPM 리포트의 "iOS deploy 100% 실패"는 reusable workflow의 phantom run을 카운트한 것
- 리팩토링 불필요 — 현재 caller → reusable 구조 정상
- 향후 TPM 리포트에서 `ios-deploy-reusable.yml` phantom run 제외 필요
