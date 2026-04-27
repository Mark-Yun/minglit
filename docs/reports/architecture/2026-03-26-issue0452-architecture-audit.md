---
source_url: https://github.com/Mark-Yun/minglit/issues/452
captured_at: 2026-03-26
issue_number: 452
state: closed
labels: [audit-report]
author: Mark-Yun
title: "🏗️ 아키텍처 감사 — 2026-03-27"
---

# 🏗️ 아키텍처 감사 — 2026-03-27

> Issue #452 · closed · created 2026-03-26T15:05:56Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/452

## Body

## 🏗️ 아키텍처 감사 리포트 — 2026-03-27

### 발견 항목

| # | 카테고리 | 위반 | 파일 (대표) | 설명 |
|---|----------|------|------------|------|
| 1 | Feature 격리 | Cross-import (circular) | `app_user: event ↔ ticket` | `event_admission_controller.dart` ↔ `ticket_selection_sheet.dart` 순환 참조 |
| 2 | Feature 격리 | Cross-import (near-circular) | `app_user: event → payment → event` | `event_application_wizard_page.dart` → `payment_success_screen.dart` → `event_coordinator.dart` |
| 3 | Feature 격리 | Cross-import (bidirectional) | `app_partner: party ↔ ticket` | `party/ticket/` → `ticket/widgets/` AND `ticket/edit/` → `party/detail/` |
| 4 | Feature 격리 | Cross-import | `app_user` 16건, `app_partner` 9건 | home→auth, payment→event, search→event, partner→home, ticket→event 등 |
| 5 | Coordinator 위반 | `context.pop()` 직접 사용 | `app_partner: qr/qr_scanner_screen.dart:140` | UI에서 GoRouter 직접 호출 (경미) |
| 6 | 파일 크기 | 792줄 | `minglit_kit: features/dev/design_catalog_page.dart` | 500줄 초과 — 분리 권장 |
| 7 | 파일 크기 | 512줄 | `app_user: features/event/detail/event_detail_content.dart` | 500줄 초과 — 분리 권장 |
| 8 | EF 코드 중복 | `_shared/response_utils` 미채택 | 8개 EF에서 인라인 CORS/Response 패턴 | `response_utils.ts`가 있지만 production EF 0개가 사용 중 |

### 아키텍처 건강도

- Feature 격리: **5/10** — 25건의 크로스 임포트, 2건의 순환 참조
- 패턴 준수: **8/10** — Repository 패턴 위반 0건, Coordinator 위반 1건 (경미)
- 문서 일치도: **9/10** — `env_keystore.ts` 누락만 발견 (PR #451에서 수정)

### 대형 파일 (500줄 이상, 프로덕션 코드)

| 파일 | 줄 수 | 권장 조치 |
|------|-------|----------|
| `shared/packages/minglit_kit/lib/src/features/dev/design_catalog_page.dart` | 792 | dev 전용이므로 우선순위 낮음, 카테고리별 분리 고려 |
| `apps/app_user/lib/src/features/event/detail/event_detail_content.dart` | 512 | 섹션별 위젯으로 분리 권장 |

### 클린 항목 (위반 없음)

- ✅ Repository 패턴: UI에서 Supabase 직접 접근 0건
- ✅ Repository 순환 의존성: minglit_kit 리포지토리 간 순환 import 0건
- ✅ Edge Function 수: 40개 (문서 일치)
- ✅ 테이블 수: 54개 (문서 일치)
- ✅ 크론잡 수: 11개 (문서 일치)
- ✅ Feature 목록: app_user 9개, app_partner 12개 (문서 일치)

### 이전 감사 대비 변화

- 문서-코드 일치도 개선 (PR #435 2026-03-26 감사에서 대부분 반영됨)
- Cross-feature import 건수는 지속적 관리 필요 (이전 PR #399, #405에서 일부 해소)

### 권장 후속 작업 (우선순위순)

1. **P2**: `event ↔ ticket` 순환 참조 해소 — 공유 인터페이스를 minglit_kit으로 추출
2. **P2**: `event → payment → event` 근접 순환 해소
3. **P3**: `app_partner: party ↔ ticket` 양방향 커플링 해소
4. **P3**: `_shared/response_utils.ts` 전체 EF 채택 (`corsHeaders` 인라인 정의 제거)
5. **P3**: `event_detail_content.dart` 512줄 → 섹션 위젯 분리

🤖 자동 생성 — audit-arch worker

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-03-26

🤖 TPM 분석 완료.

**결과:**
- actionable 항목: **2건** → 이슈 #453, #454 생성
  - #453 (P2): app_user event ↔ ticket 순환 참조 + event → payment → event 근접 순환 해소
  - #454 (P3): app_partner party ↔ ticket 양방향 커플링 해소
- skip 항목: **6건**
  - 항목 4 (일반 cross-import 25건): 구체적 순환 참조(#453, #454)로 이미 커버, 나머지는 개별 추적 불필요
  - 항목 5 (`context.pop()` 1건): 경미한 컨벤션 위반, 기능 영향 없음
  - 항목 6 (`design_catalog_page.dart` 792줄): dev 전용 코드, 프로덕션 영향 없음
  - 항목 7 (`event_detail_content.dart` 512줄): 임계치 근접 수준, 긴급성 없음
  - 항목 8 (`response_utils` 미채택): 인라인 패턴이 dev EF 2개에만 해당, 프로덕션 영향 없음

원본 리포트를 닫습니다.
