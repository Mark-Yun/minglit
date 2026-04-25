---
source_url: https://github.com/Mark-Yun/minglit/issues/750
captured_at: 2026-03-29
issue_number: 750
state: closed
labels: [audit-report]
author: Mark-Yun
title: "🎨 UI/UX 감사 — 2026-03-29"
---

# 🎨 UI/UX 감사 — 2026-03-29

> Issue #750 · closed · created 2026-03-29T12:39:38Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/750

## Body

## 🎨 UI/UX 감사 리포트 — 2026-03-29

🤖 **audit-uiux** 작업 시작.
- 작업: 정기 UI/UX 감사 (골든 이미지 시각 분석 + 디자인 토큰 준수 + 문서-코드 일치)

---

## 1. 골든 이미지 시각 분석

### 🔴 Critical: ClosingSoonEventsCard 다크모드 가독성 저하

| 파일 | 라인 | 문제 | 심각도 |
|------|------|------|--------|
| `apps/app_partner/lib/src/features/home/widgets/closing_soon_events_card.dart` | L26 | 다크모드에서 `errorContainer.withValues(alpha: 0.3)` 배경이 어두운 마룬색으로 렌더링되어 텍스트(`textSecondary=#AAAAAA`)와 대비 부족 | Critical |
| 동일 파일 | L67-81 | 이벤트 제목/날짜 텍스트가 `bodyMedium`/`onSurfaceVariant` 기본값 사용 → 다크모드 errorContainer 배경에서 가독 불가 | Critical |

**원인**: 라이트 모드에서는 연한 핑크 배경 + 어두운 텍스트로 대비 충분하나, 다크모드에서 Material3 `errorContainer`가 어두운 마룬/갈색으로 자동 생성되면서 `#AAAAAA` 텍스트와 대비 비율 미달.

**수정 방향**: 텍스트에 `colorScheme.onErrorContainer` 사용하여 Material3 색상 페어링 활용.

### ✅ 양호한 화면들

- **EventCard** (light/dark): 레이아웃 깔끔, 좌우 정렬 일관적, 다크모드 대비 충분
- **Settlement 빈 상태**: 중앙 정렬 아이콘+텍스트 구성 깔끔, light/dark 모두 양호
- **UpcomingEvents 카드**: 카드 간격 균일, 라운딩 일관적, dark 대비 양호
- **Partner Home (empty/data)**: 온보딩 스텝, 진행바, CTA 버튼 배치 완성도 높음
- **Party List**: 카드 리스트 일관적, 상태 뱃지 가독성 양호

---

## 2. 골든 테스트 커버리지

| 앱 | 전체 페이지 | 골든 테스트 보유 | 미보유 | 커버리지 |
|----|-----------|---------------|--------|---------|
| app_partner | 35 | 2 | 33 | 5.7% |
| app_user | 16 | 3 | 13 | 18.8% |
| **합계** | **51** | **5** | **46** | **9.8%** |

> 위젯 레벨 골든 테스트 4개 추가 존재 (EventCard, ClosingSoonEventsCard, SettlementEmptyState, UpcomingEventsCard)

---

## 3. 디자인 토큰 준수 감사

### High Priority (7건) — 정확한 토큰 대응 존재

| 파일 | 라인 | 하드코딩 값 | 교체 대상 |
|------|------|----------|---------|
| `settlement_card.dart` | L24 | `EdgeInsets(horizontal:16, vertical:12)` | `MinglitSpacing.medium` / `.sm` |
| `settlement_shimmer.dart` | L66 | `EdgeInsets(horizontal:16, vertical:14)` | `MinglitSpacing.medium` |
| `bank_account_page.dart` | L118 | `EdgeInsets(vertical:4)` | `MinglitSpacing.xsmall` |
| `settlement_detail_page.dart` | L208 | `EdgeInsets(vertical:4)` | `MinglitSpacing.xsmall` |
| `settlement_detail_page.dart` | L250 | `EdgeInsets(vertical:6)` | `MinglitSpacing.xsmall2` |
| `app_permission_settings_screen.dart` | L156 | `EdgeInsets.all(16)` | `MinglitSpacing.medium` |
| `minglit_key_value_row.dart` | L35 | `EdgeInsets(vertical:4)` | `MinglitSpacing.xsmall` |

### Medium Priority (15건) — fontSize, BorderRadius 토큰 교체

| 파일 | 라인 | 문제 | 교체 대상 |
|------|------|------|---------|
| `ticket_list_item.dart` | L169 | `fontSize: 11` | `labelSmall` |
| `onboarding_step_guide.dart` | L401 | `fontSize: 24` | `headlineSmall` |
| `settlement_status_badge.dart` | L89 | `fontSize: compact ? 11 : 13` | `labelSmall` / `bodySmall` |
| `closing_soon_events_card.dart` | L56 | `BorderRadius.circular(8)` | `MinglitRadius.small` |
| `closing_soon_events_card.dart` | L120 | `BorderRadius.circular(12)` | `MinglitRadius.button` |
| `partner_home_page.dart` | L61 | `BorderRadius.circular(10)` | `MinglitRadius.small` 또는 `.button` |
| `party_list_item.dart` | L247 | `BorderRadius.circular(100)` | `MinglitRadius.chip` |
| `party_list_item.dart` | L211 | `MinglitSpacing.xxsmall` as radius | `MinglitRadius` 네임스페이스 사용 |
| `partner_application_list_page.dart` | L185 | `MinglitSpacing.xxsmall` as radius | `MinglitRadius` 네임스페이스 사용 |
| `create_verification_page.dart` | L170 | `MinglitSpacing.small` as radius | `MinglitRadius.small` |
| `settlement_status_badge.dart` | L84 | `BorderRadius.circular(4)` | `MinglitRadius.small` 또는 micro 토큰 |
| `app_permission_settings_screen.dart` | L269 | `BorderRadius.circular(12)` | `MinglitRadius.input` |
| `minglit_skeleton.dart` | L65 | `BorderRadius.circular(8)` | `MinglitRadius.small` |
| `minglit_login_screen.dart` | L254 | `BorderRadius.circular(8)` | `MinglitRadius.small` |
| `bug_reporter_wrapper.dart` | L201 | `BorderRadius.circular(8)` | `MinglitRadius.small` |

### Token Namespace 오용 (3건)
`BorderRadius.circular(MinglitSpacing.xxx)` → `MinglitRadius` 토큰 사용 필요

### 누락 토큰 제안
- `MinglitRadius.micro` (4px) — 작은 뱃지/태그용
- Micro fontSize 상수 (10px) — 칩 라벨, 작은 어노테이션용

---

## 4. 문서-코드 일치

### 토큰 값: ✅ 100% 일치
모든 색상, 간격, 라운딩, 아이콘, 애니메이션, 불투명도 토큰 값이 문서와 코드에서 동일.

### 라인 번호 참조: ⚠️ 드리프트 발생

| 문서 섹션 | 문서 기재 | 실제 코드 | 차이 |
|----------|---------|---------|------|
| Typography | `minglit_theme.dart:62-106` | `:77-154` | ~50줄 off |
| Spacing | `:62-89` | `:62-112` | 시맨틱 토큰 라인 미포함 |
| Border Radius | `:92-104` | `:115-130` | ~23줄 off |
| Icon Size | `:107-122` | `:133-148` | ~26줄 off |

---

## 5. 접근성

- Light mode 텍스트 대비: ✅ `textPrimary` 16.8:1, `textSecondary` 7.1:1
- Dark mode 텍스트 대비: ✅ `textPrimary` 19.3:1, `textSecondary` 8.9:1
- **ClosingSoonEventsCard 다크모드**: ❌ errorContainer 배경 위 텍스트 대비 미달
- `success` (#22C55E) / `warning` (#F59E0B): ⚠️ 흰 배경 위 단독 텍스트 사용 시 대비 부족 (기존 알려진 이슈)

---

## 조치 계획

| 항목 | 액션 |
|------|------|
| ClosingSoonEventsCard 다크모드 | **직접 수정 PR** (Critical) |
| 하드코딩 디자인 토큰 (High+Medium) | **직접 수정 PR** |
| 문서 라인 번호 드리프트 | **직접 수정 PR** |
| 골든 테스트 커버리지 9.8% | `audit-report` → TPM 판단 (대규모 작업) |
| `MinglitRadius.micro` 토큰 추가 | `audit-report` → TPM 판단 |

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-03-29

🤖 **audit-uiux** DONE
- 결과: 정기 UI/UX 감사 완료. Critical 다크모드 이슈 1건 + 하드코딩 토큰 15건 직접 수정
- PR: #751 (하드코딩 디자인 토큰 교체 + ClosingSoonEventsCard 다크모드 대비 수정)
- 후속: 골든 테스트 커버리지 확충 (9.8% → 목표 50%+)은 TPM 판단 필요
