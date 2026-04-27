---
source_url: https://github.com/Mark-Yun/minglit/issues/536
captured_at: 2026-03-27
issue_number: 536
state: closed
labels: [audit-report]
author: Mark-Yun
title: "🏗️ 아키텍처 감사 — 2026-03-28"
---

# 🏗️ 아키텍처 감사 — 2026-03-28

> Issue #536 · closed · created 2026-03-27T15:09:08Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/536

## Body

## 🏗️ 아키텍처 감사 리포트 — 2026-03-28

### 발견 항목
| # | 카테고리 | 위반 | 파일 | 설명 |
|---|----------|------|------|------|
| 1 | Feature 격리 | Cross-feature UI import | `app_user/.../event/detail/event_detail_page.dart:9` | `ticket/ui/ticket_selection_sheet.dart` 직접 import (UI → UI) |
| 2 | Feature 격리 | Cross-feature UI import | `app_user/.../event/admission/event_application_wizard_page.dart:7` | `payment/ui/payment_success_screen.dart` 직접 import (UI → UI) |
| 3 | Feature 격리 | Cross-feature logic import | `app_partner/.../qr/qr_scanner_screen.dart` | `checkin/checkin_controller.dart` import (feature → feature) |
| 4 | Feature 격리 | Cross-feature logic import | `app_partner/.../verification/create/create_verification_controller.dart` | `party/party_providers.dart` import (feature → feature) |
| 5 | 문서 불일치 | EF 목록 오류 | `docs/architecture/backend.md` | `vectorize-party`가 독립 EF로 등재됐으나 실제로는 헬퍼 모듈 (index.ts 없음) — PR #535에서 수정 |
| 6 | 문서 불일치 | EF 누락 | `docs/architecture/backend.md` | `partner-approve-application`, `partner-reject-application` 미등재 — PR #535에서 수정 |
| 7 | 문서 불일치 | 크론잡 잔재 | `docs/architecture/backend.md` | `backend-simulation` 크론잡이 migration에서 삭제됐으나 문서에 잔존 — PR #535에서 수정 |

### 아키텍처 건강도
- Feature 격리: 7/10 — app_user에 UI-to-UI 크로스 import 2건, app_partner에 logic 크로스 import 2건. Coordinator 경유 import는 적절히 사용 중.
- 패턴 준수: 9/10 — Repository 패턴 위반 0건, Coordinator 패턴 (GoRouter 직접 사용) 위반 0건. UI에서 Supabase 직접 접근 0건.
- 문서 일치도: 8/10 — EF 목록 3건 불일치 (PR #535에서 수정). 테이블/피처 목록은 정확.

### 대형 파일 (500줄 이상, 생성 파일 제외)
| 파일 | 줄 수 | 권장 조치 |
|------|-------|----------|
| `apps/app_user/lib/src/features/event/detail/event_detail_content.dart` | 512 | 위젯 분리 권장 |
| `apps/app_partner/lib/src/features/settlement/settlement_page.dart` | 500 | 대시보드/목록 분리 권장 |

### 문서 업데이트
PR #535 에서 `backend.md`, `search-and-recommendation.md` 최신화 완료.

### 미위반 항목
- ✅ Repository 패턴: UI 레이어에서 Supabase 직접 접근 0건
- ✅ Coordinator 패턴: UI에서 GoRouter 직접 사용 (`context.go`/`context.push`) 0건
- ✅ 순환 의존성: 감지되지 않음
- ✅ client.md 피처 목록: 코드와 일치

🤖 자동 생성 — audit-arch worker

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-03-27

🤖 TPM 분석 완료.

**결과:**
- actionable 항목: 2건 → 이슈 #539, #540 생성
  - #539: app_user event → ticket cross-feature UI import (P2)
  - #540: app_partner qr→checkin, verification→party cross-feature import (P2)
- skip 항목: 5건
  - 항목 2 (event → payment import): 기존 이슈 #509와 중복
  - 항목 5-7 (문서 불일치 3건): PR #535에서 이미 수정 완료
  - 대형 파일 2건: P3 리팩토링 — 출시 전 배제

원본 리포트를 닫습니다.
