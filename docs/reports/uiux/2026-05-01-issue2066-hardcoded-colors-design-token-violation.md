---
source_url: https://github.com/Mark-Yun/minglit/issues/2066
captured_at: 2026-05-01
issue_number: 2066
state: open
labels: [audit-report, needs-tpm]
author: audit-uiux-gemini
title: "[Audit] UI/UX: 하드코딩된 기본 Colors 값 사용 발견 (디자인 토큰 위반)"
---

# [Audit] UI/UX: 하드코딩된 기본 Colors 값 사용 발견 (디자인 토큰 위반)

> Issue #2066 · open · created 2026-05-01 · author @audit-uiux-gemini
> https://github.com/Mark-Yun/minglit/issues/2066

## Body

Scheduler: audit-uiux-gemini

## 이슈 내용
현재 Minglit 코드베이스를 스캔한 결과, 지정된 디자인 토큰(`MinglitColors`, `MinglitPartnerColors`) 대신 Flutter 기본 시스템 색상(`Colors.white`, `Colors.black`, `Colors.transparent`, `Colors.grey`)이 직접 하드코딩된 사례가 다수 발견되었습니다.

이는 다크모드 대응 및 전체적인 디자인 일관성을 해칠 수 있는 안티패턴이며, '디자인 토큰에 없는 값을 하드코딩하지 않는다'는 UI/UX 원칙에 위배됩니다.

### 주요 위반 파일
- `shared/packages/minglit_kit/lib/src/ui/widgets/party/event_card.dart` (Colors.white, Colors.black, Colors.grey, Colors.transparent 다수 사용)
- `apps/app_partner/lib/src/features/checkin/widgets/checkin_scanner_overlay.dart` (Colors.white, Colors.black, Colors.transparent 다수 사용)
- `shared/packages/minglit_kit/lib/src/utils/splash_screen.dart` (Colors.white)
- `apps/app_user/lib/src/features/ticket/ui/widgets/boarding_pass_card.dart` (Colors.black)
- `apps/app_user/lib/src/common/widgets/consent_detail_sheet.dart` (Colors.transparent)

## 기대 효과 (해결 방안)
- 위 위젯들에서 기본 시스템 색상 사용을 제거하고, 용도에 맞는 `MinglitColors` 또는 테마 기반의 토큰으로 교체해야 합니다.
- `MinglitColors.transparent` 등 이미 존재하는 토큰을 적극적으로 활용합니다.
- 토큰에 존재하지 않는 투명도나 특수 컬러가 필요하다면 토큰 정의를 확장해야 합니다.
