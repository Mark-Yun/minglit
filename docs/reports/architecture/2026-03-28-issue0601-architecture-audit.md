---
source_url: https://github.com/Mark-Yun/minglit/issues/601
captured_at: 2026-03-28
issue_number: 601
state: closed
labels: [audit-report]
author: Mark-Yun
title: "🏗️ 아키텍처 감사 — 2026-03-28"
---

# 🏗️ 아키텍처 감사 — 2026-03-28

> Issue #601 · closed · created 2026-03-28T07:12:41Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/601

## Body

## 🏗️ 아키텍처 감사 리포트 — 2026-03-28

### 발견 항목

| # | 카테고리 | 위반 | 파일 | 설명 |
|---|----------|------|------|------|
| 1 | Feature 격리 | Cross-import | `home_page.dart` → `auth_coordinator`, `event_coordinator` | app_user home 피처가 auth, event 피처를 직접 import (10건) |
| 2 | Feature 격리 | Cross-import | `event_coordinator.dart` → `ticket/ui/ticket_selection_sheet.dart` | event 피처가 ticket UI를 직접 import |
| 3 | Feature 격리 | Cross-import | `event_application_wizard_page.dart` → `home_coordinator`, `payment_success_screen` | admission이 home, payment를 직접 import |
| 4 | Feature 격리 | Cross-import | `search_page.dart` → `event_coordinator` | search가 event를 직접 import |
| 5 | Feature 격리 | Cross-import | `partner_detail_page.dart`, `partner_events_page.dart` → `home_coordinator` | partner가 home을 직접 import |
| 6 | Feature 격리 | Cross-import | `party_curation_page.dart` → `event_coordinator` | party가 event를 직접 import |
| 7 | Feature 격리 | Cross-import | `revenue_summary_card.dart` → `settlement_coordinator` | app_partner home이 settlement를 직접 import |
| 8 | Repository 패턴 | Supabase in UI | `staff_guard_wrapper.dart` | UI에서 supabaseClientProvider 직접 접근 (Fix #412 주석 있음) |
| 9 | Coordinator 패턴 | GoRouter in UI | `dev_user_switch_screen.dart` | GoRouter.of(context).go('/') 직접 호출 (개발 전용) |
| 10 | Coordinator 패턴 | GoRouter in UI | `notification_list_screen.dart` | context.push(trimmed) — 딥링크 동적 URL (의도적 가능성) |

### 아키텍처 건강도

- Feature 격리: 5/10 — app_user에서 12건의 cross-feature import. auth_coordinator, event_coordinator, home_coordinator가 여러 피처에서 직접 참조됨. 앱 레벨 coordinator 분리 권장.
- 패턴 준수: 8/10 — Repository 위반 1건(개발용), Coordinator 위반 2건(개발/딥링크). 프로덕션 UI는 패턴 준수.
- 문서 일치도: 8/10 — vectorize-party EF 누락, qr/ 피처 삭제 미반영, application/ 피처 미기재 → PR #598에서 수정 완료.

### 대형 파일 (500줄 이상)

| 파일 | 줄 수 | 권장 조치 |
|------|-------|----------|
| `apps/app_partner/.../event_application_manage_page.dart` | 595 | UI 분리 권장 (테이블 위젯 추출) |
| `apps/app_partner/.../event_action_card.dart` | 526 | 로직 분리 권장 (getEventPhase 등 이미 테스트 분리됨) |
| `apps/app_user/.../event_detail_content.dart` | 512 | 섹션별 위젯 추출 권장 |
| `apps/app_partner/.../settlement_page.dart` | 500 | 매출 카드 위젯 분리 권장 |
| `shared/.../design_catalog_page.dart` | 1141 | 개발 전용 — 우선순위 낮음 |

### 문서 최신화 (PR #598)

- `backend.md`: `vectorize-party` Edge Function 추가
- `client.md`: `application/` 피처 추가, 삭제된 `qr/` 피처 제거

### 기타

- 순환 의존성: 발견 없음
- Edge Function 코드 중복: dev 함수 3개에서만 createClient 직접 사용 (서비스 클라이언트 대신 유저 클라이언트 필요한 경우 — 의도적)

🤖 자동 생성 — audit-arch worker

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-03-28

🤖 **tpm-staff** 분석 완료.

**결과:**
- actionable 항목: 2건 → 이슈 #634 (app_user cross-import 10건), #635 (app_partner cross-import 1건) 생성. P2-medium + needs-dev.
- skip 항목: 8건
  - #8 staff_guard_wrapper: Fix #412 의도적 workaround
  - #9 dev_user_switch_screen: 개발 전용 화면
  - #10 notification_list_screen: 딥링크 동적 URL 의도적
  - 대형 파일 5건: P3 리팩토링, 출시 전 배제
- 기존 이슈 #509 (admission → payment cross-import)은 별도 진행 중

원본 리포트를 닫습니다.
