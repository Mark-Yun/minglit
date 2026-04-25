---
source_url: https://github.com/Mark-Yun/minglit/issues/798
captured_at: 2026-03-29
issue_number: 798
state: closed
labels: [P3-low, audit-report]
author: Mark-Yun
title: "🎨 UI/UX 감사 — 2026-03-30"
---

# 🎨 UI/UX 감사 — 2026-03-30

> Issue #798 · closed · created 2026-03-29T20:52:44Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/798

## Body

## 🎨 UI/UX 감사 리포트 — 2026-03-30

### 감사 범위
- 와이어프레임 리뷰: partner-terms-privacy (#794)
- 골든 이미지 시각 분석 (app_partner, app_user 신규 goldens)
- 디자인 토큰 준수 스캔 (apps/, shared/)
- 골든 테스트 커버리지

---

## 1. 와이어프레임 리뷰 (partner-terms-privacy)

**결과: 승인 (수정 5건 + 콘텐츠 갭 1건)**

이슈 #794에서 상세 리뷰 완료. 요약:
- 파트너 브랜드 토큰 정합성 우수
- 타이포그래피/레이아웃 디자인 시스템 준수
- S1-S5 수정 사항은 구현 시 반영 (needs-arch #795에 인계)
- C1 privacy 테이블 누락 → needs-pm #796 생성

**직접 수정**: `shared/web/theme/tokens.ts` radius 불일치 → PR #797

---

## 2. 골든 이미지 시각 분석

신규 골든 20개 검토 (app_partner 17개, app_user 3개).

| 골든 | 상태 | 비고 |
|------|------|------|
| partner_home_page_empty | ✅ | 온보딩 단계 레이아웃 깔끔, 프로그레스 바/체크리스트 일관적 |
| partner_home_page_with_data | ✅ | 요약 카드 3개 + 이벤트 카드 + CTA 구조 정상 |
| event_card_scheduled / full | ✅ | 카드 헤더 영역 정상. 본문 빈 영역은 테스트 데이터 미포함으로 판단 |
| closing_soon_single_dark | ⚠️ | 다크모드 배경이 진한 빨간색 — 긴급성 표현 의도로 보이나, 일반 다크모드 (`#0F0F0F`) 대비 매우 이질적. 의도된 디자인인지 확인 필요 |
| settlement_empty_state_* | ✅ | 빈 상태 아이콘+텍스트 중앙 정렬 정상 |
| party_list_page_* | ✅ | 빈 상태/데이터 있는 상태 모두 정상 |
| app_user home/my_page | ✅ | 탭 구조, 빈 상태 레이아웃 정상 |

**시각 이슈 0건** (closing_soon_dark 색상은 의도 확인 수준, 이슈 생성 불필요)

---

## 3. 디자인 토큰 준수

### 하드코딩 색상: 0건 ✅
이전 감사 대비 개선 — `Color(0x...)` 패턴 완전 제거됨.

### 하드코딩 폰트 크기: 6건

| 파일 | 라인 | 값 | 판단 |
|------|------|-----|------|
| `app_user/.../my_tickets_page.dart` | L128 | `fontSize: 16` | **수정 필요** → `titleMedium` 사용 |
| `app_partner/.../onboarding_step_guide.dart` | L35 | `fontSize: 40` | 이모지 표시용 — 허용 |
| `app_partner/.../onboarding_step_guide.dart` | L401 | `fontSize: 24` | 이모지 표시용 — 허용 |
| `app_partner/.../onboarding_step_guide.dart` | L413 | `fontSize: 10` | **수정 필요** → `labelSmall (11)` 최소 |
| `app_partner/.../event_action_card.dart` | L218 | `fontSize: 28` | **수정 필요** → TextTheme 슬롯 없음, 커스텀 사이즈. `headlineSmall (24)` 또는 `displayLarge (32)` 선택 필요 |
| `app_partner/.../ticket_list_item.dart` | L169 | `fontSize: 11` | **수정 필요** → `labelSmall` 사용 |

**수정 필요 4건** (이모지용 2건 제외)

### 하드코딩 간격: 0건 ✅
전 감사 대비 개선 — 모든 SizedBox/EdgeInsets가 `MinglitSpacing.*` 토큰 사용.

### 비표준 버튼 스타일: 19건
대부분 padding/shape 커스텀 (허용 범위). 색상 하드코딩 포함 주요 건:
- `app_partner/.../partner_welcome_page.dart:112` — `MinglitColors.primary` 직접 참조 (theme.colorScheme.primary 대신)
- `app_partner/.../partner_apply_page.dart:175` — 동일 패턴

---

## 4. 골든 테스트 커버리지

| 앱 | 전체 페이지 | 골든 테스트 | 커버리지 |
|----|-----------|-----------|---------|
| app_user | 17 | 3 | 17.6% |
| app_partner | 35 | 6 | 17.1% |
| **합계** | **52** | **9** | **17.3%** |

전 감사(#743)와 동일. 커버리지 확대는 QA 영역 — needs-qa 이슈 권장.

---

## 5. 직접 수정 사항

| 항목 | PR | 상태 |
|------|-----|------|
| `tokens.ts` radius 불일치 (button 16→12, card 24→16) | #797 | CI 대기 |

---

## 6. 후속 조치

| 항목 | 라벨 | 이슈 |
|------|------|------|
| partner-terms-privacy 기술 설계 | needs-arch | #795 |
| privacy 테이블 행사 운영 누락 확인 | needs-pm | #796 |
| 하드코딩 폰트 4건 수정 | audit-report → tpm 판단 | 본 이슈 |
| 골든 테스트 커버리지 확대 | audit-report → tpm 판단 | 본 이슈 |

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-03-30

🤖 **tpm-staff** 분석 완료.

**결과:**
- actionable 항목: 1건 → #862 생성 (하드코딩 fontSize 1건, P3)
- skip 항목: 5건
  - 하드코딩 폰트 3건: PR #819에서 이미 수정됨
  - MinglitColors.primary 직접 참조 2건: 실제로는 디자인 토큰 사용이므로 문제 아님
  - 골든 테스트 커버리지: QA 영역, 현재 우선순위에서 제외

원본 리포트를 닫습니다.
