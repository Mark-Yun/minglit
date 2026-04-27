---
source_url: https://github.com/Mark-Yun/minglit/issues/725
captured_at: 2026-03-29
issue_number: 725
state: closed
labels: [audit-report]
author: Mark-Yun
title: "🎨 UI/UX 감사 — 2026-03-29"
---

# 🎨 UI/UX 감사 — 2026-03-29

> Issue #725 · closed · created 2026-03-29T02:33:41Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/725

## Body

## 감사 범위
`apps/`, `shared/packages/minglit_kit/lib/src/` (`.g.dart`, `.freezed.dart`, 테마 정의 파일 제외)

## 1. 디자인 토큰 준수

### A. 하드코딩 색상 (14건 → 3건 수정, 11건 → 2건 잔여)

| 파일 | 건수 | 상태 |
|------|------|------|
| `todo_summary_chips.dart` | 7 | ✅ PR #724 수정 |
| `settlement_shimmer.dart` | 4 | ✅ PR #724 수정 |
| `checkin_placeholder_page.dart` | 1 | ✅ PR #724 수정 |
| `splash_screen.dart` | 2 | ⚪ 스플래시 고유 브랜드 이펙트 — 허용 |

### B. 하드코딩 폰트 크기 (5건)

| 파일:라인 | 값 | 분석 |
|-----------|-----|------|
| `event_action_card.dart:218` | 28px | 히어로 넘버. TextTheme에 28px 슬롯 없음 (24 headlineSmall, 32 displayLarge). 신규 토큰 검토 필요. |
| `onboarding_step_guide.dart:401` | 24px | 이모지 크기 — 텍스트 스타일이 아닌 아이콘 크기 맥락. 허용. |
| `onboarding_step_guide.dart:413` | 10px | labelSmall(11px) 미만. 접근성 최소 크기 경계. |
| `settlement_status_badge.dart:89` | 11/13px | compact=11(labelSmall), 13(bodySmall). TextTheme 사용 권장. |
| `ticket_list_item.dart:169` | 11px | bodySmall에서 11px 오버라이드. labelSmall 사용 권장. |

### C. 하드코딩 간격
거의 모든 코드가 `MinglitSpacing` 토큰 사용 중. 위반 없음.

### D. 비표준 버튼 (20+건)
`ElevatedButton`, `TextButton`, `OutlinedButton` 직접 사용. 테마가 적용되므로 시각적 문제는 없으나, 공통 래퍼(`MinglitBottomCta` 등) 활용 확대 권장.

## 2. Golden Test 커버리지

| 항목 | 수 |
|------|-----|
| 전체 page/screen | 51 |
| golden test 있음 | 9 (17.6%) |
| golden test 없음 | 42 |

주요 미커버 화면: login, payment, partner_detail, event_detail, party_create, settlement, checkin 등.

## 3. 골든 이미지 시각 분석

| 화면 | 라이트 | 다크 | 비고 |
|------|--------|------|------|
| Event Card | ✅ 브랜드 퍼플 적용 | ✅ 적절한 surface 색상 | 카드-배경 경계 다크모드에서 미세 |
| Upcoming Events | ✅ 카드 라운딩 일관 | ✅ 다크 서피스 적용 | 정상 |
| Settlement Empty | ✅ 센터 정렬 | ✅ 다크 적응 | 정상 |
| Settlement Action | ✅ 브랜드 퍼플 CTA | ✅ 다크에서도 퍼플 유지 | 정상 |

## 4. 문서-코드 일치

`docs/ux/design-system/01-foundation.md` ↔ `minglit_design_tokens.dart`: **일치**.
모든 13개 섹션(Colors, Typography, Spacing, Radius, IconSize, Shadow, Borders, Decorations, TextStyles, Opacity, PartnerColors, Animation) 정상.

## 5. needs-uiux 이슈 처리

| 이슈 | 제목 | 처리 |
|------|------|------|
| #652 | UI/UX 개선 제안 | P1 수정 완료 (PR #724). needs-uiux 제거. |
| #651 | 배경색 계층구조 + screenEdge | UX 평가 코멘트 완료. report-exec 라벨 추가 (사람 판단 필요). |

## 6. 신규 위반 없음

마지막 감사(PR #720) 이후 앱 코드 변경 없음 (버전 bump만). 신규 위반 발생하지 않음.

## PR

| PR | 내용 | 상태 |
|-----|------|------|
| #724 | 하드코딩 색상 → 토큰 교체 (3파일 14건) | auto-merge 대기 |

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-03-29

🤖 TPM 분석 완료.

**결과:**
- actionable 항목: **0건** (신규 이슈 불필요)
- skip 항목: **전체**

**Skip 사유:**

| 섹션 | 항목 | 사유 |
|------|------|------|
| 1A. 하드코딩 색상 | 14건 | ✅ PR #724에서 수정 완료 (splash 2건은 브랜드 이펙트 허용) |
| 1B. 하드코딩 폰트 크기 | 5건 | 기존 이슈 #596에서 추적 중 (OPEN). 중복 방지 |
| 1C. 하드코딩 간격 | 0건 | 위반 없음 |
| 1D. 비표준 버튼 | 20+건 | 스타일/컨벤션 통일 — P3, 출시 전 배제 대상 |
| 2. Golden Test 커버리지 | 17.6% | 단순 수치. 구체적 갭이 아니므로 스킵 |
| 3. 골든 이미지 시각 분석 | 4건 | 전부 정상 |
| 4. 문서-코드 일치 | 13섹션 | 전부 일치 |
| 5. needs-uiux 처리 | 2건 | audit-uiux가 이미 처리 완료 |
| 6. 신규 위반 | 0건 | 마지막 감사 이후 앱 코드 변경 없음 |

원본 리포트를 닫습니다.
