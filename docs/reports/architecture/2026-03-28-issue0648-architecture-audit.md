---
source_url: https://github.com/Mark-Yun/minglit/issues/648
captured_at: 2026-03-28
issue_number: 648
state: closed
labels: [audit-report]
author: Mark-Yun
title: "🏗️ 아키텍처 감사 — 2026-03-28"
---

# 🏗️ 아키텍처 감사 — 2026-03-28

> Issue #648 · closed · created 2026-03-28T10:13:12Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/648

## Body

## 🏗️ 아키텍처 감사 리포트 — 2026-03-28

### 발견 항목
| # | 카테고리 | 위반 | 파일 | 설명 |
|---|----------|------|------|------|
| 1 | Repository 패턴 | Supabase in UI | `app_partner/.../application/event_application_manage_page.dart` (L237, 291, 337) | UI 레이어에서 `supabaseClientProvider` 직접 접근 — Repository로 분리 필요 |
| 2 | Feature 격리 | Cross-import | `app_user/.../home/home_page.dart` | `auth`, `event` feature 직접 import |
| 3 | Feature 격리 | Cross-import | `app_user/.../home/my_page.dart` | `auth` feature 직접 import |
| 4 | Feature 격리 | Cross-import | `app_user/.../party/party_curation_page.dart` | `event` feature 직접 import |
| 5 | Feature 격리 | Cross-import | `app_user/.../search/search_page.dart` | `event` feature 직접 import |
| 6 | Feature 격리 | Cross-import | `app_user/.../partner/partner_events_page.dart`, `partner_detail_page.dart` | `home` feature 직접 import |
| 7 | Feature 격리 | Cross-import | `app_user/.../event/event_admission_controller.dart`, `event_detail_page.dart` | `auth` feature 직접 import |
| 8 | Feature 격리 | Cross-import | `app_user/.../event/event_application_wizard_page.dart` | `home`, `payment` feature 직접 import |
| 9 | Feature 격리 | Cross-import | `app_user/.../event/event_coordinator.dart` | `ticket` feature 직접 import |
| 10 | Feature 격리 | Cross-import | `app_partner/.../home/revenue_summary_card.dart` | `settlement` feature 직접 import |

### 아키텍처 건강도
- Feature 격리: **5/10** — app_user에서 12건, app_partner에서 1건의 cross-feature import. `home`/`event`/`auth` 간 coupling이 심함
- 패턴 준수: **8/10** — Coordinator 패턴 잘 지켜짐 (0건), Repository 위반 1개 파일
- 문서 일치도: **8/10** — backend.md에 최근 migration 반영 누락 4건 → PR #647에서 수정

### 대형 파일 (500줄 이상)
| 파일 | 줄 수 | 권장 조치 |
|------|-------|----------|
| `minglit_kit/.../dev/design_catalog_page.dart` | 1141 | 탭별 위젯 분리 필요 (1000줄 초과) |
| `app_partner/.../application/event_application_manage_page.dart` | 595 | Repository 패턴 위반 수정과 함께 분리 권장 |
| `app_partner/.../home/widgets/event_action_card.dart` | 526 | 분리 권장 |
| `app_user/.../event/detail/event_detail_content.dart` | 512 | 분리 권장 |
| `app_partner/.../settlement/settlement_page.dart` | 500 | 경계선 — 모니터링 |

### Edge Function 유틸 표준화
- `dev-mock-portone`: `_shared/` 모듈 미사용 — 표준화 권장
- `backend-simulator`, `dev-seed`, `health`, `github-stats-sync`: `Deno.env.get`으로 직접 env 접근 — `_shared/supabase_client.ts` 사용 권장

### 문서 최신화
- PR #647: backend.md 업데이트 (enum, 컬럼, RPC 함수 반영)

🤖 자동 생성 — audit-arch worker

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-03-28

🤖 **tpm-staff** 분석 완료.

**결과:**
- actionable 항목: 1건 → #653 생성 (Supabase-in-UI Repository 분리, P2)
- skip 항목: 9건
  - Cross-feature imports (항목 2~10): P3 리팩토링 — 출시 전 배제. 기능에 영향 없고 coordinator 패턴으로 부분 완화됨
  - 대형 파일 (design_catalog_page 1141줄, event_action_card 526줄): P3 스타일 — 출시 전 배제
  - Edge Function 유틸 표준화: P3 — 기능 동작에 영향 없음
  - 문서 최신화: PR #647에서 이미 수정 중

원본 리포트를 닫습니다.
