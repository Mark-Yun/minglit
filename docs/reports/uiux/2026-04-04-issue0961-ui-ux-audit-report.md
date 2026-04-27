---
source_url: https://github.com/Mark-Yun/minglit/issues/961
captured_at: 2026-04-04
issue_number: 961
state: closed
labels: [P3-low, audit-report]
author: Mark-Yun
title: "🔍 UI/UX Audit Report — 2026-04-04"
---

# 🔍 UI/UX Audit Report — 2026-04-04

> Issue #961 · closed · created 2026-04-04T04:14:03Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/961

## Body

Scheduler: audit-uiux

## UI/UX 감사 리포트 — 2026-04-04

### 감사 범위
- 골든 이미지 시각 품질 리뷰 (app_user 6장, app_partner 14장, minglit_kit 5장)
- 하드코딩 디자인 토큰 코드 스캔 (apps/, shared/)
- 라이트/다크 모드 비교 검토

### 1. 골든 이미지 시각 품질 — ✅ 양호

모든 화면에서 구조적 레이아웃, 간격 균일성, 다크모드 대비가 양호함.
- 라이트/다크 모드 전환 일관적
- 빈 상태 화면 적절히 구성됨
- 카드/리스트/버튼 스타일 화면 간 일관적
- **출시 수준으로 판단**: 현재 골든 이미지 기준으로 시각적 어색함 없음

### 2. 하드코딩 토큰 — 신규 발견 (기존 이슈 미포함분)

#### 2-1. `Colors.white` 6건 — settlement_page.dart

| 파일 | 라인 | 코드 | 수정 방향 |
|------|------|------|----------|
| `apps/app_partner/lib/src/features/settlement/settlement_page.dart` | L185 | `Colors.white.withValues(alpha: 0.8)` | `colorScheme.onPrimary.withValues(alpha: 0.8)` |
| 동일 | L192 | `Colors.white` | `colorScheme.onPrimary` |
| 동일 | L204 | `Colors.white.withValues(alpha: 0.7)` | `colorScheme.onPrimary.withValues(alpha: 0.7)` |
| 동일 | L210 | `Colors.white` | `colorScheme.onPrimary` |
| 동일 | L223 | `Colors.white.withValues(alpha: 0.7)` | `colorScheme.onPrimary.withValues(alpha: 0.7)` |
| 동일 | L229 | `Colors.white` | `colorScheme.onPrimary` |

**맥락**: gradient 배경 위 매출 요약 카드의 텍스트 색상. 기능적으로 문제 없으나 다크모드에서 onPrimary가 의미적으로 정확.
**참고**: #951에서 event_now_multi_stack.dart + settlement_detail_page.dart만 커버됨. 이 6건은 미포함.

#### 2-2. 하드코딩 BorderRadius — 토큰 미사용 3건

| 파일 | 라인 | 현재 | 토큰 |
|------|------|------|------|
| `apps/app_user/lib/src/features/my_tickets/ui/my_ticket_card.dart` | L281 | `BorderRadius.circular(100)` | `MinglitRadius.chip` |
| `apps/app_user/lib/src/features/account_deletion/ui/deletion_info_page.dart` | L39, L86 | `BorderRadius.circular(16)` | `MinglitRadius.card` |
| `apps/app_partner/lib/src/features/account_deletion/ui/deletion_info_page.dart` | L39, L86 | `BorderRadius.circular(16)` | `MinglitRadius.card` |

**참고**: `BorderRadius.circular(2)`, `circular(3)` 등 진행바/인디케이터용 초소형 radius는 별도 토큰이 없어 현상 유지 권장.

### 3. 기존 이슈 현황

| 이슈 | 제목 | 상태 |
|------|------|------|
| #951 | Colors.white, Colors.blue 토큰 교체 | needs-dev |
| #956 | SettlementStatusBadge 하드코딩 스타일 교체 | needs-dev |
| #957 | TodoSummaryChips/EventActionCard alpha 교체 | needs-dev |

### 4. PR 케어 현황

| PR | 제목 | 상태 |
|----|------|------|
| #926 | docs: UI/UX 문서 최신화 (v7) | ✅ MERGED (이번 사이클에서 conflict 해결) |
| #942 | test: party create wizard goldens | ❌ HARD BLOCK — LateInitializationError (#953 needs-dev) |

### 권장 조치

1. **#951 범위 확장** 또는 **별도 이슈 생성**: settlement_page.dart `Colors.white` 6건 추가
2. **P3-low**: my_ticket_card, deletion_info_page BorderRadius 토큰화 (3건)
3. **#953 해결 필요**: PR #942 머지를 위해 LocationMap appKey 초기화 이슈 해결 필요 (P1)

### DONE

골든 이미지 기준 시각 품질 이상 없음. 하드코딩 토큰 신규 9건 발견 (모두 P3).

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-04-04

🤖 audit-uiux: DONE. PR #963에서 발견된 모든 항목 수정 완료.
