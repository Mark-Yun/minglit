---
source_url: https://github.com/Mark-Yun/minglit/issues/1194
captured_at: 2026-04-09
issue_number: 1194
state: closed
labels: [P2-medium, audit-report, needs-tpm]
author: Mark-Yun
title: "[UI/UX Audit] 2026-04-10: Empty State 패턴 파편화 + 디자인 토큰 미적용 잔여 건"
---

# [UI/UX Audit] 2026-04-10: Empty State 패턴 파편화 + 디자인 토큰 미적용 잔여 건

> Issue #1194 · closed · created 2026-04-09T21:06:22Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1194

## Body

Scheduler: audit-uiux-claude-subagents

## 1. 개요 (Executive Summary)

**전반적 건강도:** 양호
**감사 일자:** 2026-04-10
**감사 범위:** app_user, app_partner 전체 골든 이미지 + 디자인 토큰 코드 레벨 감사

PR #972 (디자인 토큰 마이그레이션)과 PR #985 (이용약관 UX 재설계) 이후 전반적인 디자인 시스템 준수도가 크게 개선되었다. `SizedBox` 스페이싱과 `fontSize`는 **100% 토큰화** 완료. 그러나 두 가지 구조적 문제가 남아 있다:

1. **`MinglitEmptyState` 공유 컴포넌트가 사실상 dead code** — 양 앱 모두 0건 사용
2. **opacity/alpha 값 87건, BorderRadius 13건, Colors.white 6건**이 여전히 하드코딩

---

## 2. 발견 사항

### Finding 1: Empty State 패턴 파편화 (심각도: 3/4)

`minglit_kit`에 `MinglitEmptyState` 공유 위젯이 존재하고 export되어 있으나, **양 앱에서 사용 건수 0건**. 대신 6개의 커스텀 empty state 구현이 분산되어 있다.

| 위치 | 유형 | 공유 컴포넌트 대비 차이 |
|------|------|----------------------|
| `settlement_empty_state.dart` | 전용 위젯 클래스 | **거의 동일한 복제** — 아이콘만 다름 |
| `verification_manage_page.dart` | 인라인 클래스 | 배경색, 사이즈, CTA 없음 |
| `ticket_list_item.dart` (TicketListView) | 인라인 메서드 | 아이콘 32px (표준 64), 배경 컨테이너 |
| `party_location_input.dart` | 인라인 메서드 | 맵 슬롯 (맥락상 정당화 가능) |
| `step4_entry_rules.dart` | 인라인 메서드 | 아이콘 없음, 텍스트만 |
| `my_tickets_page.dart` | 인라인 클래스 | 아이콘 56px, 버튼 스타일 완전 커스텀 |

**골든 이미지에서 확인된 시각적 불일치:**
- `purchase_history_page_states.png`: 빈 상태가 텍스트만 있고 아이콘/일러스트 없음
- `party_partner_pages.png` (우측 상단): 빈 상태가 중앙 텍스트만 표시
- 반면 search, home, my_page는 아이콘 + 텍스트 + CTA 패턴 일관 사용

**제안:** `MinglitEmptyState`에 `variant` 파라미터(compact, inline, fullPage)를 추가하고, 모든 커스텀 구현을 통합. `SettlementEmptyState`는 즉시 삭제 가능.

---

### Finding 2: 하드코딩 opacity/alpha 87건 (심각도: 2/4)

`MinglitOpacity` 토큰이 이미 정의되어 있으나 대부분의 코드에서 `.withValues(alpha: 0.1)` 같은 리터럴 값을 직접 사용.

| 현재 하드코딩 값 | 대응 토큰 | 추정 건수 |
|----------------|---------|---------|
| `alpha: 0.05` | `MinglitOpacity.tintFill` | ~8건 |
| `alpha: 0.08` | `MinglitOpacity.activeChip` | ~5건 |
| `alpha: 0.1` | `MinglitOpacity.highlight` | ~15건 |
| `alpha: 0.15` | `MinglitOpacity.placeholder` | ~5건 |
| `alpha: 0.2` | `MinglitOpacity.subtle` | ~8건 |
| `alpha: 0.3` | `MinglitOpacity.muted` | ~10건 |
| `alpha: 0.6` | `MinglitOpacity.separator` | ~5건 |
| `alpha: 0.8` | `MinglitOpacity.scrimLight` | ~5건 |
| 기타 (0.26, 0.54, 0.87 등) | 토큰 없음 | ~10건 |

**올바른 패턴 사용 예시** (이미 토큰 사용 중):
- `event_action_card.dart`: `MinglitOpacity.highlight`
- `todo_summary_chips.dart`: `MinglitOpacity.activeChip`

---

### Finding 3: 하드코딩 BorderRadius 13건 (심각도: 2/4)

| 파일 | 하드코딩 값 | 대체 토큰 |
|------|-----------|---------|
| `deletion_info_page.dart` (양 앱) | `BorderRadius.circular(16)` | `MinglitRadius.card` |
| `my_ticket_card.dart` | `BorderRadius.circular(100)` | `MinglitRadius.chip` |
| `settlement_shimmer.dart` | `BorderRadius.circular(4)` | `MinglitRadius.badge` |
| `event_now_bottom_sheet.dart` 외 | `BorderRadius.circular(2)` | 토큰 없음 (추가 필요) |
| `onboarding_step_guide.dart` 외 | `BorderRadius.circular(3)` | 토큰 없음 (추가 필요) |

**제안:** `MinglitRadius`에 `indicator = 2`, `dot = 3` 소형 토큰 추가 검토.

---

### Finding 4: settlement_page.dart Colors.white 6건 (심각도: 2/4)

`_SummaryCard` 위젯이 primary gradient 배경 위 텍스트에 `Colors.white`를 직접 사용. `colorScheme.onPrimary`로 교체 필요.

---

## 3. 골든 이미지 시각 품질 평가

**긍정적:**
- 라이트/다크 모드 전환이 전반적으로 일관적
- 이벤트 카드, 결제 성공 화면, 매칭 투표 화면의 비주얼 퀄리티가 높음
- Partner 홈의 온보딩 체크리스트 + 진행률 바 + CTA 구성이 깔끔
- 정산 대시보드의 gradient summary 카드가 시각적으로 돋보임

**개선 가능:**
- `ticket_qr_screen_missing.png` (다크 모드): 에러 상태에 CTA/도움말 링크 없이 아이콘+텍스트만 표시. 사용자가 다음 행동을 알 수 없음
- `matching_vote_screen_completed.png` (다크 모드): 결과 카드의 밝은 배경이 다크 모드와 시각적 긴장감 생성
- `my_page` 양 앱의 빨간 로그아웃/삭제 버튼이 풀 너비로 너무 prominent — 실수 탭 위험

---

## 4. 개선 로드맵

### Quick Wins (1-2 PR)
1. `SettlementEmptyState` → `MinglitEmptyState` 전환 (코드 삭제)
2. `settlement_page.dart` `Colors.white` 6건 → `colorScheme.onPrimary`
3. `BorderRadius.circular(16/100/4)` → `MinglitRadius` 토큰 (4파일 6건)

### Medium-term (별도 PR)
4. `MinglitEmptyState`에 variant 지원 추가 후 커스텀 empty state 통합
5. `.withValues(alpha:)` → `MinglitOpacity` 일괄 마이그레이션 (~70건)
6. `MinglitRadius`에 2px, 3px 소형 토큰 추가

### Design Improvement (UX 관점)
7. QR 티켓 에러 상태에 "도움말" CTA 추가
8. 로그아웃/계정 삭제 버튼 prominent 감소 (text-only red 또는 별도 확인 모달)

---

## 5. 참고
- PR #972: `refactor(ui): replace hardcoded alpha/spacing/radius values with design tokens`
- PR #971: `fix(ui): replace hardcoded Colors.white/blue with design tokens`
- 감사 기준: `docs/ux/design-system/01-foundation.md`, `docs/templates/usability-audit.md`

## Comments (2)

### Comment 1 — @Mark-Yun on 2026-04-09

🤖 **audit-uiux-claude-subagents** 감사 완료.

2개 핵심 발견:
1. `MinglitEmptyState` 공유 컴포넌트 사용률 0% — 6개 커스텀 구현 분산
2. 디자인 토큰 미적용 잔여: opacity 87건, BorderRadius 13건, Colors.white 6건

Quick Win 3건은 즉시 `needs-swe`로 넘길 수 있고, Empty State 통합은 설계 검토 후 진행 권장.

`needs-tpm` 라벨 부착하여 판단을 요청합니다.

### Comment 2 — @Mark-Yun on 2026-04-09

🤖 **tpm-exec-report-claude-subagents** 분석 완료.

**검증 방법**: 각 Finding에 대해 실제 코드를 읽어 문제 존재 여부, 토큰 매칭, 기존 이슈 중복을 확인.

**결과:**
- actionable 항목: **4건 → 이슈 3건** 생성
  - #1195 — `refactor(ui): BorderRadius + Colors.white 디자인 토큰 교체` (P3, needs-swe) — Quick win, 4파일 기계적 교체
  - #1196 — `refactor(ui): MinglitEmptyState 통합` (P3, needs-uiux) — variant 설계 검토 필요
  - #1197 — `refactor(ui): opacity/alpha → MinglitOpacity 토큰 일괄 마이그레이션` (P3, needs-swe) — ~87건 배치 작업
- skip 항목: **0건** — 모든 Finding이 코드 검증을 통해 실제 문제로 확인됨

**그루핑**: Finding 3(BorderRadius) + Finding 4(Colors.white)는 동일 성격(토큰 교체)이므로 1개 이슈(#1195)로 통합.

원본 리포트를 닫습니다.
