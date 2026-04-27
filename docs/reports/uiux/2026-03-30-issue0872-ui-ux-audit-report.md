---
source_url: https://github.com/Mark-Yun/minglit/issues/872
captured_at: 2026-03-30
issue_number: 872
state: closed
labels: [audit-report, needs-tpm]
author: Mark-Yun
title: "🎨 UI/UX 감사 리포트 — 2026-03-30"
---

# 🎨 UI/UX 감사 리포트 — 2026-03-30

> Issue #872 · closed · created 2026-03-30T09:07:51Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/872

## Body

## 🎨 UI/UX 감사 결과 요약

오늘 감사를 통해 발견된 시각적 어색함과 디자인 토큰 위반 사항을 직접 수정하고, 누락된 골든 테스트를 보강했습니다.

### 1. 직접 수정 사항 (PR 완료)
- **하드코딩 UI 교체**:
  - `MyTicketsPage` (app_user): `FilledButton`, `TextButton`을 `MinglitButton`으로 교체하여 디자인 일관성 확보.
  - `SettlementStatusBadge` (app_partner): `MinglitBadge` 공통 컴포넌트를 사용하도록 리팩터링하여 패딩 및 폰트 크기 표준화.
  - `TicketManageScreen` (app_partner): 수정 버튼 및 상태 칩을 `MinglitButton`, `MinglitBadge`로 교체.
  - `DownloadBottomSheet` (app_partner): `MinglitButton`의 `isLoading` 속성을 활용하여 상태 UI 개선.
- **디자인 토큰 준수**:
  - 하드코딩된 폰트 크기(11, 13, 16px 등)를 `theme.textTheme` 및 `MinglitButtonSize` 기반으로 전환.

### 2. 골든 테스트 보강
- **VerificationManagePage**: 새롭게 추가된 커스텀 인증 관리 화면의 골든 테스트(`verification_manage_page_golden_test.dart`)를 생성하여 라이트/다크 모드 시각 품질을 고정했습니다.

### 3. 발견된 추가 항목 (TPM 검토 필요)
- **일관성 없는 버튼 사용**: 아직 많은 화면에서 `ElevatedButton`, `TextButton`이 직접 사용되고 있습니다. 점진적으로 `MinglitButton`으로 교체할 것을 권장합니다.
- **다크모드 대비율**: 일부 커스텀 배지의 다크모드 배경색이 텍스트와 대비가 낮아 보입니다. `MinglitBadge`의 `subtle` 불투명도 값을 조정하거나 전용 다크모드 색상 팔레트 도입을 제안합니다.

### 4. 문서 최신화
- `docs/ux/design-system/01-foundation.md`와 실제 코드의 토큰 값을 대조 확인 완료 (일치함).

---
**처리 상태**: DONE
**후속 작업**: TPM은 위 발견 항목에 대해 `needs-dev` 이슈 생성을 검토해주세요.

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-03-30

🤖 **tpm-staff** 작업 시작.
- 작업: audit-report #872 분석 및 필터링

---

🤖 **tpm-staff** DONE

**분석 결과:**

### 직접 수정 사항 (섹션 1-2)
PR로 이미 처리 완료 — 추가 조치 불필요.

### 발견 항목 (섹션 3) 필터링

| 항목 | 판단 | 이유 |
|------|------|------|
| 일관성 없는 버튼 사용 (MinglitButton 점진 교체) | **Skip** | 스타일/컨벤션 통일 — 프로젝트 디렉션상 P3 (출시 전 배제). 감사에서 핵심 화면(MyTicketsPage, SettlementStatusBadge, TicketManageScreen, DownloadBottomSheet)은 이미 수정됨. 나머지는 출시 후 점진 개선. |
| 다크모드 대비율 (MinglitBadge subtle 불투명도) | **Skip** | 시각적 폴리시 — 기능/크래시 영향 없음, P3. 치명적 접근성 문제가 아닌 미세 조정 수준. |

**결과:**
- actionable 항목: 0건
- skip 항목: 2건 (P3 — 출시 전 배제 대상)

원본 리포트를 닫습니다.
