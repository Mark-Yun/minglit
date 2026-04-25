---
source_url: https://github.com/Mark-Yun/minglit/issues/925
captured_at: 2026-04-01
issue_number: 925
state: closed
labels: [P2-medium, audit-report, needs-tpm]
author: Mark-Yun
title: "🎨 UI/UX 감사 — 2026-04-01"
---

# 🎨 UI/UX 감사 — 2026-04-01

> Issue #925 · closed · created 2026-04-01T04:27:44Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/925

## Body

Scheduler: audit-uiux

### 1. 디자인 토큰 준수 및 시각 품질 (Visual Quality)

**발견 항목:**
- [Medium] **하드코딩 색상**: `apps/app_user/lib/src/features/home/widgets/event_now_multi_stack.dart:251`에서 `Colors.white` 사용. `MinglitColors.background`로 교체 필요.
- [Medium] **비표준 색상**: `apps/app_partner/lib/src/features/settlement/settlement_detail_page.dart:257`에서 `Colors.blue` 사용. 디자인 토큰(Indigo 계열)으로 통일 필요.
- [Low] **아이콘 사이즈**: `onboarding_step_guide.dart:37`에서 `MinglitIconSize.xxlarge` (40px) 사용 중이나 문서 누락 (PR #924로 해결).

### 2. 골든 테스트 커버리지 (Golden Test Coverage)

**상태: 위기 (Critical)**
- 전체 화면: 52개
- 골든 테스트 적용: 10개 (커버리지 약 19%)
- **미적용 핵심 화면**:
  - `event_detail_page.dart` (User)
  - `partner_home_page.dart` (Partner)
  - `settlement_page.dart` (Partner)

**제안:**
- 주요 CUJ(Customer Usage Journey) 상의 화면들에 대해 우선적으로 골든 테스트 추가 필요.

### 3. 정량 분석 시스템 (Render Tree Analysis)

**상태: 미흡**
- 모든 골든 테스트에서 `.render.txt` (Render Tree Dump)가 생성되지 않고 있음.
- 수치 기반의 간격/패딩 검사가 불가능하여 육안 검사에만 의존 중.

**제안:**
- `shared/packages/minglit_kit`의 골든 테스트 헬퍼를 수정하여 렌더 트리 덤프 기능 추가.

### 4. 문서-코드 일치 (Docs-Code Sync)

- `MinglitIconSize.xxlarge` (40px) 토큰이 코드에는 있으나 `docs/ux/design-system/01-foundation.md`에 누락된 것을 발견하여 수정 완료 (PR #924).

## Comments (2)

### Comment 1 — @Mark-Yun on 2026-04-04

🤖 **needs-tpm-claude-1** 작업 시작.
- 작업: #925 UI/UX 감사 리포트 분석 및 코드 검증

### Comment 2 — @Mark-Yun on 2026-04-04

🤖 **needs-tpm-claude-1** [DONE]

**결과:**
- actionable 항목: 2건 → 이슈 #951 생성 (하드코딩 Colors.white / Colors.blue 교체)
- skip 항목:
  - 골든 테스트 커버리지 비율: 이미 #574에서 추적 중
  - 아이콘 사이즈 문서 누락: PR #924에서 해결됨
  - 렌더 트리 덤프: 구체적 파일:라인 없는 enhancement 제안 → skip
  - Docs-Code 일치: PR #924에서 해결됨

원본 리포트를 닫습니다.
