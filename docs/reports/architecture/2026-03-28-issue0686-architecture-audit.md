---
source_url: https://github.com/Mark-Yun/minglit/issues/686
captured_at: 2026-03-28
issue_number: 686
state: closed
labels: [audit-report]
author: Mark-Yun
title: "🏗️ 아키텍처 감사 — 2026-03-29"
---

# 🏗️ 아키텍처 감사 — 2026-03-29

> Issue #686 · closed · created 2026-03-28T16:32:03Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/686

## Body

## 🏗️ 아키텍처 감사 리포트 — 2026-03-29

### 발견 항목

| # | 카테고리 | 위반 | 파일 | 설명 |
|---|----------|------|------|------|
| 1 | Feature 격리 | 크로스-피처 UI import | `event/admission/event_application_wizard_page.dart:7` | `payment/ui/payment_success_screen.dart` 직접 import — Coordinator를 통한 네비게이션으로 전환 필요 |
| 2 | Feature 격리 | 크로스-피처 UI import | `event/logic/event_coordinator.dart:3` | `ticket/ui/ticket_selection_sheet.dart` 직접 import — PR #571에서 이동 작업 했으나 import 잔존 |
| 3 | 문서-코드 불일치 | EF 분류 오류 | `docs/architecture/backend.md` | `vectorize-party`를 Edge Function으로 분류했으나 실제로는 `index.ts` 없는 라이브러리 모듈 → **PR #684에서 수정 완료** |

### 아키텍처 건강도

- Feature 격리: **8/10** — 크로스-피처 coordinator import 11건은 패턴 수준에서 허용 가능하나, UI 직접 import 2건은 수정 필요
- 패턴 준수: **10/10** — Repository 패턴(Supabase 직접 접근 0건), Coordinator 패턴(GoRouter 직접 사용 0건) 완벽 준수
- 문서 일치도: **9/10** — vectorize-party 분류 오류 1건 (PR #684에서 수정)

### 대형 파일 (500줄 이상, non-test, non-generated)

| 파일 | 줄 수 | 권장 조치 |
|------|-------|----------|
| `minglit_kit/.../dev/design_catalog_page.dart` | 1,253 | 탭별 파일 분리 (design-pattern-catalog plan.md 이슈 #1에서 처리 예정) |
| `app_partner/.../application/event_application_manage_page.dart` | 595 | 섹션별 위젯 추출 권장 |
| `app_partner/.../home/widgets/event_action_card.dart` | 526 | 카드 타입별 위젯 분리 권장 |
| `app_user/.../event/detail/event_detail_content.dart` | 512 | 탭 콘텐츠 위젯 추출 권장 |
| `app_partner/.../settlement/settlement_page.dart` | 500 | 대시보드/리스트 탭 분리 권장 |

### 긍정적 변화 (최근 7일)

- PR #582: app_partner 크로스-피처 import 해소 (refactor)
- PR #571: 티켓 선택을 EventCoordinator로 이동 (일부 잔존 import 있음)
- PR #643, #644, #645: 보안 수정 3건 (event-matching 인가, settlement EF 권한, PGMQ RLS)
- PR #647, #677: architecture 문서 최신화 2건

### 후속 조치

- [ ] 위반 #1: `event_application_wizard_page.dart` → payment success 화면을 Coordinator 네비게이션으로 전환
- [ ] 위반 #2: `event_coordinator.dart` → ticket_selection_sheet import 제거 (PR #571 후속)
- [ ] 대형 파일 분리는 P3-low 우선순위로 개별 이슈 생성 판단 필요

🤖 자동 생성 — audit-arch

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-03-28

🤖 **tpm-staff** 분석 완료.

**결과:**
- 위반 #1 (admission → payment cross-feature import): 기존 이슈 #509에서 커버 (P3-low)
- 위반 #2 (event_coordinator → ticket_selection_sheet import): 기존 이슈 #634에서 커버 (P2-medium, needs-dev)
- 위반 #3 (vectorize-party 문서 분류 오류): PR #684에서 수정 완료 → skip
- 대형 파일 5건: P3-low — 출시 전 배제 (프로젝트 디렉션)

**actionable 신규 이슈: 0건** — 모든 항목이 기존 이슈/PR로 커버됨.
원본 리포트를 닫습니다.
