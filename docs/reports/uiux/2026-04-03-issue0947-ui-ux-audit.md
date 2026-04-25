---
source_url: https://github.com/Mark-Yun/minglit/issues/947
captured_at: 2026-04-03
issue_number: 947
state: closed
labels: [audit-report, needs-tpm]
author: Mark-Yun
title: "🎨 UI/UX 감사 — 2026-04-03"
---

# 🎨 UI/UX 감사 — 2026-04-03

> Issue #947 · closed · created 2026-04-03T04:13:04Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/947

## Body

Scheduler: audit-uiux-gemini-1

### 화면 시각 품질
- **골든 이미지 부재**: 주요 화면 50개 이상(app_user 20+, app_partner 30+)에 대해 골든 테스트가 없습니다. 출시 전 시각적 회귀 방지를 위해 보강이 필요합니다.
- **간격 불균형**: `event_now_bottom_sheet.dart` 등 일부 화면에서 하드코딩된 간격(2px, 4px)이 사용되어 디자인 시스템과의 일관성이 떨어집니다.

### 디자인 토큰 준수
| 파일 | 라인 | 문제 | 수정 방향 |
|------|------|------|----------|
| `apps/app_partner/lib/src/features/settlement/widgets/settlement_status_badge.dart` | L81, L89 | 하드코딩된 패딩/폰트 크기 | `MinglitSpacing`, `TextTheme.labelSmall` 사용 |
| `apps/app_user/lib/src/features/home/widgets/event_now_bottom_sheet.dart` | L664, L820 | 하드코딩된 간격 (4, 2) | `MinglitSpacing.xsmall`, `xxsmall` 사용 |

### 접근성
- **명시적 폰트 크기**: `SettlementStatusBadge`에서 11px, 13px을 하드코딩 중입니다. 시스템 폰트 설정 대응을 위해 `TextTheme` 사용을 권장합니다.

### 긍정적 변화
- `app_partner` 홈 화면 위젯들이 전반적으로 `MinglitSpacing`을 잘 준수하고 있어 레이아웃이 안정적입니다.

### 후속 조치 제안
- **needs-dev**: `SettlementStatusBadge` 및 `event_now_bottom_sheet.dart` 토큰 적용.
- **needs-qa**: 미작성된 주요 화면(50+)에 대한 골든 테스트 추가 계획 수립.

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-04-04

🤖 TPM 분석 완료.

**결과:**
- actionable 항목: 2건
  - #956 SettlementStatusBadge 디자인 토큰 교체 (P3-low)
  - #957 TodoSummaryChips / EventActionCard alpha 토큰 교체 (P3-low)
- skip 항목: 3건
  - `event_now_bottom_sheet.dart` L664/820 소간격 하드코딩 → style convention, 기능 영향 없음
  - EventActionCard `headlineMedium+w900` → Fix #596에서 의도적으로 변경된 값
  - `_GreetingSection` 아이콘 이슈 → false positive (코드에 👋 emoji만 존재, icon box 없음)
- 골든 테스트 커버리지 부족 → #941과 동일 이슈, needs-qa 라우팅 예정

원본 리포트를 닫습니다.
