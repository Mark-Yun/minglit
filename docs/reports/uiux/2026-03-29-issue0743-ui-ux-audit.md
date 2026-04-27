---
source_url: https://github.com/Mark-Yun/minglit/issues/743
captured_at: 2026-03-29
issue_number: 743
state: closed
labels: [P3-low, audit-report]
author: Mark-Yun
title: "🎨 UI/UX 감사 — 2026-03-29"
---

# 🎨 UI/UX 감사 — 2026-03-29

> Issue #743 · closed · created 2026-03-29T06:11:40Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/743

## Body

## 디자인 토큰 준수

### ✅ 직접 수정 완료

| PR | 내용 | 파일 수 | 건수 |
|----|------|---------|------|
| #730 | 배경색 계층구조(토스 패턴) + screenEdge 20→16 | 3 | 3 |
| #740 | 하드코딩 간격 → MinglitSpacing 토큰 교체 (settlement) | 4 | 11 |

### ⚠️ 하드코딩 폰트 크기 (app_partner, 6건)

직접 수정하지 않은 이유: `copyWith`로 의도적 오버라이드하는 케이스가 섞여 있어 context 확인 필요.

| 파일 | 라인 | 현재 값 | 권장 토큰 | 비고 |
|------|------|---------|----------|------|
| `ticket_list_item.dart` | L169 | `fontSize: 11` | `labelSmall` (11px) | bodySmall.copyWith → labelSmall.copyWith(fontWeight: normal) |
| `settlement_status_badge.dart` | L89 | `compact ? 11 : 13` | `labelSmall` / `bodySmall` | 조건부, TextStyle 직접 생성 |
| `event_action_card.dart` | L218 | `fontSize: 28` | 스케일 외 (24~32 사이) | displayLarge.copyWith — 신규 토큰 검토 필요 |
| `onboarding_step_guide.dart` | L35 | `fontSize: 40` | 스케일 외 | 이모지 전용, displayLarge.copyWith |
| `onboarding_step_guide.dart` | L401 | `fontSize: 24` | `headlineSmall` (24px) | 이모지 전용 TextStyle |
| `onboarding_step_guide.dart` | L413 | `fontSize: 10` | 스케일 외 (최소 11) | 접근성 우려 — 최소 11px 권장 |

### 🎨 스플래시 스크린 하드코딩 색상 (2건)

| 파일 | 라인 | 값 | 비고 |
|------|------|-----|------|
| `splash_screen.dart` | L41 | `Color(0xFF21FFFE)` | 시안 그림자 — 스플래시 전용 |
| `splash_screen.dart` | L166 | `Color(0xFF7B2FBE)` | 퍼플 그라디언트 — 스플래시 전용 |

스플래시 스크린 특수 연출이므로 우선순위 낮음. `MinglitColors.splashCyan` / `splashPurple` 토큰화 가능.

---

## 골든 이미지 시각 분석

- 골든 이미지 존재: `app_partner/test/goldens/` (이벤트 카드, settlement 빈 상태 등)
- 라이트/다크 모드 쌍 존재 ✓
- PR #730 (배경색 + screenEdge 변경) 머지 후 골든 이미지 업데이트 필요

---

## 골든 테스트 커버리지

| 항목 | 수치 |
|------|------|
| 전체 페이지/스크린 | 51 |
| 골든 테스트 보유 | 9 (17.6%) |
| **미커버 화면** | **47** |

주요 미커버 영역:
- `app_user`: 로그인, 결제, 파트너 상세, 티켓 QR, 매칭 투표, 이벤트 상세 등 13개
- `app_partner`: 홈, 정산, 파티 관리, 온보딩, 체크인, 인증 관리 등 34개

> 골든 테스트 확대는 별도 `needs-qa` 이슈로 분리 권장.

---

## 문서-코드 일치

| 항목 | 상태 |
|------|------|
| `01-foundation.md` screenEdge 값 | ⚠️ 20 → PR #730에서 16으로 업데이트 예정 |
| `01-foundation.md` surface 토큰 설명 | ⚠️ "카드/입력 필드 배경" → PR #730에서 계층구조 문서 추가 |
| 나머지 토큰 (color, spacing, radius, icon, shadow) | ✅ 일치 |

---

## 접근성

- `onboarding_step_guide.dart:413` — `fontSize: 10` 사용. WCAG 최소 권장(11px)보다 작음. 시인성 저하 우려.

---

## 버튼 일관성

✅ `ElevatedButton`, `TextButton`, `OutlinedButton` 모두 테마 스타일 적용 확인.
`minglit_theme.dart`에 3종 버튼 테마가 정의되어 있어 직접 사용해도 일관성 유지됨.

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-03-29

🤖 **tpm-staff** 분석 완료.

**결과:**
- actionable 항목: 0건 (신규 이슈 생성 불필요)
- skip 항목: 전체
  - 하드코딩 폰트 크기 6건 + 스플래시 색상 2건 + 접근성 1건 → **기존 이슈 #596에서 이미 동일 파일·라인 추적 중**
  - 골든 테스트 커버리지 확대 → P3 수준, 출시 전 우선순위 밖
  - 문서-코드 일치 → PR #730에서 처리 예정
  - 버튼 일관성 → 문제 없음 (✅)

스플래시 스크린 파일(`splash_screen.dart`)은 `apps/app_partner/`가 아닌 `shared/` 경로에 존재. 이미 #596에서 정확한 경로로 추적 중.

원본 리포트를 닫습니다.
