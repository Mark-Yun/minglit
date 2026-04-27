---
source_url: https://github.com/Mark-Yun/minglit/issues/772
captured_at: 2026-03-29
issue_number: 772
state: closed
labels: [P3-low, audit-report]
author: Mark-Yun
title: "🏗️ 아키텍처 감사 — 2026-03-29"
---

# 🏗️ 아키텍처 감사 — 2026-03-29

> Issue #772 · closed · created 2026-03-29T13:33:51Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/772

## Body

## 🏗️ 아키텍처 감사 리포트 — 2026-03-29

### 발견 항목

| # | 카테고리 | 위반 | 파일 | 설명 |
|---|----------|------|------|------|
| 1 | Repository 패턴 위반 | **HIGH** | `apps/app_partner/lib/src/features/application/event_application_manage_page.dart:237,291,337` | UI에서 `ref.read(supabaseClientProvider)` 직접 호출하여 Edge Function 실행. Repository 레이어를 우회함. |
| 2 | Cross-feature import | **HIGH** | `apps/app_user/lib/src/features/event/admission/event_application_wizard_page.dart:7` | event 피처에서 `payment/ui/payment_success_screen.dart` 직접 import (UI→UI 크로스 피처) |
| 3 | Cross-feature import | **HIGH** | `apps/app_user/lib/src/features/event/logic/event_coordinator.dart:3` | Coordinator에서 `ticket/ui/ticket_selection_sheet.dart` import (다른 피처 UI 직접 참조) |
| 4 | Coordinator 패턴 위반 | **MED** | `apps/app_partner/lib/src/features/home/partner_home_page.dart:153,258,261` | UI에서 `ApplicationListRoute().go(context)`, `CheckinRoute().go(context)` 직접 호출. Coordinator를 거치지 않음. |
| 5 | Coordinator 패턴 위반 | **MED** | `apps/app_partner/lib/src/features/more/more_page.dart:143` | UI에서 `PartnerApplyRoute().go(context)` 직접 호출 |
| 6 | Coordinator 패턴 위반 | **MED** | `apps/app_partner/lib/src/features/onboarding/partner_apply_status_page.dart:143` | UI에서 `PartnerApplyRoute().go(context)` 직접 호출 |
| 7 | Cross-feature import | **MED** | `apps/app_partner/lib/src/features/home/widgets/revenue_summary_card.dart:1` | home 위젯에서 `settlement/settlement_coordinator.dart` import |
| 8 | Edge Function observability | **MED** | 18개 EF (partner-manage-*, user-*, dev-* 등) | `withHandler` 미사용 — Axiom 로깅/Sentry 에러 캡처 누락 |
| 9 | Cross-feature import | **LOW** | `apps/app_user/lib/src/features/home/home_page.dart:3-4` | home에서 `auth/logic/auth_coordinator.dart`, `event/logic/event_coordinator.dart` import |
| 10 | Cross-feature import | **LOW** | `apps/app_user/lib/src/features/partner/detail/partner_events_page.dart:1` | partner에서 `home/logic/home_coordinator.dart` import |

### 아키텍처 건강도

- Feature 격리: **6/10** — app_user에서 coordinator 공유가 빈번, app_partner에서 repository 패턴 위반 1건
- 패턴 준수: **6/10** — app_partner에 GoRouter 직접 호출 3건, Supabase 직접 접근 1건
- 문서 일치도: **7/10** → PR #771에서 수정 중 (verification_comments 삭제, verification_status 축소, my_tickets 추가)

### 대형 파일 (500줄 이상)

| 파일 | 줄 수 | 권장 조치 |
|------|-------|----------|
| `shared/packages/minglit_kit/lib/src/features/dev/design_catalog_page.dart` | 1,253 | dev-only이므로 낮은 우선순위. 섹션별 분리 가능. |
| `apps/app_partner/lib/src/features/application/event_application_manage_page.dart` | 595 | **분리 필요** + Repository 패턴 위반 수정 필요 (발견항목 #1) |
| `shared/packages/minglit_kit/lib/src/data/repositories/event_repository_queries.dart` | 586 | 쿼리 그룹별 추가 분리 검토 |
| `apps/app_partner/lib/src/features/home/widgets/event_action_card.dart` | 526 | 위젯 분리 (sub-widget 추출) |
| `apps/app_user/lib/src/features/event/detail/event_detail_content.dart` | 512 | 섹션별 위젯 분리 |
| `apps/app_partner/lib/src/features/settlement/settlement_page.dart` | 500 | 경계선 — 모니터링 |

### 긍정적 변화 (최근 7일)

- `MinglitBadge` 공유 위젯 추가 (#755) — 디자인 토큰 일관성 강화
- `MyTicketsController` + Provider (#746) — Feature-first 구조 준수
- 디자인 토큰 치환 다수 (#724, #730, #740, #751) — 하드코딩 색상 제거
- `StatusBadge` 위젯 추출 (#734, #741) — 재사용 가능한 공통 컴포넌트
- PGMQ RLS 정책 추가 (#migration 20260328000001) — 보안 강화
- `MatchingVoteScreen` → `MatchingVoteContent` 리팩토링 (#735) — 관심사 분리

### 후속 조치

| 항목 | 대응 |
|------|------|
| 발견항목 #1 (Repository 위반) | TPM → needs-dev 이슈 생성 (P2) |
| 발견항목 #2-3 (Cross-feature UI import) | TPM → needs-dev 이슈 생성 (P2) |
| 발견항목 #4-6 (Coordinator 위반) | TPM → needs-dev 이슈 생성 (P3) |
| 발견항목 #8 (EF withHandler) | TPM → needs-dev 이슈 생성 (P3) |
| 문서 최신화 | PR #771 (auto-merge 대기 중) |
| needs-arch #759 (CI/DI 암호화) | 아키텍처 결정 코멘트 완료 — TPM 검토 후 needs-dev 전환 |

🤖 자동 생성 — TPM이 검토 후 needs-dev 이슈 생성 예정

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-03-30

🤖 **tpm-staff** DONE — TPM 분석 완료.

**결과:**
- 발견항목 10건 중:
  - **수정 완료 5건**: #1 (PR #768), #3 (PR #783), #5, #7 — 이미 수정됨
  - **기존 이슈 1건**: #2 → 이슈 #509 (open)
  - **actionable 1건**: #4, #6 → 이슈 #845 생성 (P3-low, Coordinator 패턴 위반)
  - **skip 3건**: #8 (EF withHandler, P3 출시 후), #9-#10 (LOW, home coordinator 공유는 현 구조상 불가피)

원본 리포트를 닫습니다.
