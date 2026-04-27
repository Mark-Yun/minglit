---
source_url: https://github.com/Mark-Yun/minglit/issues/702
captured_at: 2026-03-28
issue_number: 702
state: closed
labels: [P1-high, report-exec]
author: Mark-Yun
title: "⚠️ TPM Report — 2026-03-29: iOS deploy 연속 실패 재발 (3주차)"
---

# ⚠️ TPM Report — 2026-03-29: iOS deploy 연속 실패 재발 (3주차)

> Issue #702 · closed · created 2026-03-28T17:22:29Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/702

## Body

## iOS deploy 워크플로우 연속 실패 — 3주 연속 미해결

### 현황
- `ios-deploy-reusable.yml` 가 2026-03-28 하루에만 **7회 연속 failure**
- 이전 report-exec #488 (3/27), #545 (3/28)에서 플래그했으나 **미해결 상태 지속**
- 로그 조회 불가 (`log not found`) — 실행 환경 자체에 문제 가능성

### 영향
- iOS 앱 배포 **완전 차단** 상태
- 7월 출시 목표 대비 iOS 빌드/배포 파이프라인 검증 불가
- 매 실행마다 ci-failure 이슈 자동 생성 → 노이즈 증가

### 필요 조치 (사람)
1. **Apple Developer 계정** 상태 점검 (만료/갱신)
2. **인증서/프로비저닝 프로파일** 유효성 확인
3. **CI secrets** (APPLE_CERTIFICATE, PROVISIONING_PROFILE 등) 업데이트
4. 해결 전까지 **워크플로우 비활성화 검토** — 불필요한 ci-failure 노이즈 차단

### 이력
| 날짜 | Report | 상태 |
|------|--------|------|
| 3/27 | #488 | closed (미해결) |
| 3/28 | #545 | closed (미해결) |
| 3/29 | 본 이슈 | **3주차 재에스컬레이션** |

> 3회 이상 반복 실패 → report-exec 에스컬레이션 기준 충족

## Comments (2)

### Comment 1 — @Mark-Yun on 2026-03-29

3주 연속 미해결. Apple 계정/인증서 확인 필요. 당장은 워크플로우 비활성화 검토.

### Comment 2 — @Mark-Yun on 2026-03-30

🤖 **tpm-exec-report** Root Cause 업데이트

이전 분석에서는 Apple 인증서/프로비저닝 문제로 추정했으나, **실제 root cause는 YAML 파싱 에러**입니다.

### Root Cause
- PR #749 (`fix(ci): convert iOS deploy reusable workflow to composite action`)에서 도입
- `.github/actions/ios-deploy/action.yml` L198-203: shell heredoc 콘텐츠가 YAML `run: |` 블록의 인덴트 레벨 밖에 위치
- GitHub Actions YAML 파서가 heredoc 콘텐츠를 YAML 매핑으로 해석 시도 → 파싱 실패
- 에러: `While scanning a simple key, could not find expected ':'` (Line 200)

### 수정 방향
- heredoc → `echo` + `>>` 방식으로 변환 (YAML 인덴트와 무관하게 동작)

### 대응
- needs-dev 이슈 생성 완료 (P0-critical)
- Apple 계정/인증서 점검은 불필요 (이 에러가 해결되면 다시 확인)
