---
source_url: https://github.com/Mark-Yun/minglit/issues/941
captured_at: 2026-04-02
issue_number: 941
state: closed
labels: [P2-medium, audit-report, needs-tpm]
author: Mark-Yun
title: "🎨 UI/UX 감사 — 2026-04-02"
---

# 🎨 UI/UX 감사 — 2026-04-02

> Issue #941 · closed · created 2026-04-02T04:09:30Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/941

## Body

Scheduler: audit-uiux-gemini-1

### 1. 시각 분석 및 UX 품질 (Visual & UX)
- **[우려] 다크모드 대비/명도 불균형**:
  - 파트너 앱 홈의 요약 카드(`TodoSummaryChips`) 등이 라이트 모드 색상에 `alpha: 0.08`을 적용하고 있어, 다크모드에서 배경이 지나치게 밝게 보임 (눈부심 유발).
  - **제안**: 다크모드 전용 서피스 색상을 사용하거나 불투명도를 더 낮게 조절 필요.
- **[우려] 타이포그래피 무게감 불균형**:
  - `EventActionCard`에서 시간을 표시하는 `19:00` 텍스트가 `headlineMedium` (28px) + `fontWeight: w900`으로 설정되어 있어, 이벤트 제목에 비해 시각적으로 지나치게 무거움.
- **[관찰] 아이콘 플레이스홀더**:
  - `_GreetingSection`의 파트너 이름 옆 아이콘이 'X' 표시가 된 상자로 보임. 의도된 아바타 플레이스홀더인지, 아이콘 누락인지 확인 필요.

### 2. 디자인 토큰 준수 (Design Token Compliance)
- **하드코딩 불투명도(Alpha) 사용**:
  - `TodoSummaryChips.dart`: `alpha: 0.08` (권장: `MinglitOpacity.tintFill` 0.05)
  - `EventActionCard.dart`: `alpha: 0.1` (권장: `MinglitOpacity.tintFill` 0.05)
- **컴포넌트 내 하드코딩 스타일 (심각)**:
  - `SettlementStatusBadge.dart`:
    - 하드코딩 패딩 (`8, 12, 2, 4`) → `MinglitSpacing` 미사용
    - 하드코딩 곡률 (`borderRadius: 4`) → `MinglitRadius` 미사용
    - 하드코딩 폰트 크기 (`fontSize: 11, 13`) → `TextTheme` 미사용
- **폰트 크기 하드코딩**:
  - `staff_gate_screen.dart`, `design_catalog_page.dart` 등에서 `fontSize: 10` 직접 사용 중.

### 3. 골든 테스트 커버리지 (Test Coverage)
- **현황**: **심각한 부족**.
- **통계**: 양쪽 앱 합쳐 총 9개의 골든 테스트 파일만 존재.
- **영향**: 대부분의 화면이 시각적 회귀 테스트(Visual Regression Test) 보호를 받지 못하고 있음.
- **제안**: 주요 화면(신청 관리, 정산, 더보기 등)에 대한 골든 테스트 우선 보강 필요.

### 4. IA 및 문서 정합성
- **현황**: **양호**.
- `information-architecture.md` 및 `menu-structure.md`가 최신 `app_routes.dart`와 잘 일치함.

---
**TPM 후속 조치 제안**:
1. `SettlementStatusBadge` 등 하드코딩 스타일 컴포넌트의 토큰화 (`needs-dev`)
2. 다크모드 요약 카드 명도 조절 및 디자인 가이드 보완 (`needs-uiux` 또는 `needs-pm`)
3. 핵심 화면 골든 테스트 추가 계획 수립 (`needs-qa`)

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-04-04

🤖 TPM 분석 완료.

**결과:**
- actionable 항목: 2건 (#956, #957 - #947 리포트와 중복 항목 포함하여 통합 처리)
  - #956 SettlementStatusBadge 디자인 토큰 교체 (P3-low)
  - #957 TodoSummaryChips / EventActionCard alpha 토큰 교체 (P3-low)
- skip 항목: 3건
  - 다크모드 타이포그래피 무게감 (EventActionCard headlineMedium+w900) → Fix #596에서 의도적 변경
  - `_GreetingSection` 아이콘 플레이스홀더 → false positive
  - 골든 테스트 커버리지 → 아래 별도 처리 예정
- needs-qa 라우팅: 골든 테스트 9개 → 주요 화면 50+ 커버리지 부족은 현 출시 전 단계에서 P3. 이슈 생성 미룸.

원본 리포트를 닫습니다.
