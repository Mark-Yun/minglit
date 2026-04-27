---
source_url: https://github.com/Mark-Yun/minglit/issues/436
captured_at: 2026-03-26
issue_number: 436
state: closed
labels: [P3-low, audit-report]
author: Mark-Yun
title: "🏗️ 아키텍처 감사 — 2026-03-26"
---

# 🏗️ 아키텍처 감사 — 2026-03-26

> Issue #436 · closed · created 2026-03-26T02:08:05Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/436

## Body

## 🏗️ 아키텍처 감사 리포트 — 2026-03-26

### 발견 항목

| # | 카테고리 | 위반 | 파일 | 설명 |
|---|----------|------|------|------|
| 1 | Feature 격리 | Cross-feature coupling | `app_user/.../event/admission/event_admission_controller.dart` | `ticket/ui/ticket_selection_sheet.dart` 직접 import (controller→다른 feature UI) |
| 2 | Feature 격리 | Cross-feature coupling | `app_user/.../event/admission/event_application_wizard_page.dart` | `payment/ui/payment_success_screen.dart` 직접 import (UI→다른 feature UI) |
| 3 | Feature 격리 | Cross-feature coupling | `app_user/.../payment/ui/payment_success_screen.dart` | `event/logic/event_detail_controller.dart` 직접 import (UI→다른 feature controller) |
| 4 | Feature 격리 | Cross-feature coupling | `app_user/.../ticket/ui/ticket_selection_sheet.dart` | `event/admission/event_admission_controller.dart` 직접 import — #1과 순환 의존 |
| 5 | 문서 불일치 | Cron Jobs | `docs/architecture/backend.md` | 크론잡 7개 누락 — PR #435에서 수정 완료 |
| 6 | 문서 불일치 | Shared Modules | `docs/architecture/backend.md` | `refund_utils.ts`, `validation_utils.ts` 누락 — PR #435에서 수정 완료 |

### 아키텍처 건강도

- Feature 격리: **7/10** — event↔ticket↔payment 간 순환 커플링 존재. coordinator를 통하지 않는 직접 import 4건.
- 패턴 준수: **9/10** — Repository 패턴(UI에서 Supabase 직접 접근 0건), Coordinator 패턴(GoRouter 직접 사용 0건) 모두 준수.
- 문서 일치도: **8/10** — Edge Function 목록 정확. 크론잡/공유모듈 누락은 PR #435에서 수정 완료. 테이블·피처 목록 일치.

### 대형 파일 (500줄 이상, .g.dart/.freezed.dart/테스트 제외)

| 파일 | 줄 수 | 권장 조치 |
|------|-------|----------|
| `shared/packages/minglit_kit/lib/src/features/dev/design_catalog_page.dart` | 792 | 개발 도구이므로 우선순위 낮음. 카테고리별 파일 분리 고려 |
| `apps/app_user/lib/src/features/event/detail/event_detail_content.dart` | 512 | 섹션별 위젯 추출 권장 (상세 정보/티켓/환불정책 등) |

### Cross-feature 순환 의존 상세

```
event/admission/event_admission_controller
    ↓ imports
ticket/ui/ticket_selection_sheet
    ↓ imports  
event/admission/event_admission_controller  ← 순환!
```

**권장 수정:**
- `ticket_selection_sheet`가 필요로 하는 event 로직을 callback/interface로 추상화
- 또는 admission flow를 하나의 feature로 통합 (event + ticket + payment의 admission 서브피처)

### 문서 최신화 (PR #435)

backend.md에 누락된 크론잡 7개와 공유모듈 2개를 추가하는 PR을 생성했습니다.

🤖 자동 생성 — audit-arch worker

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-03-27

🤖 TPM 분석 완료.

**결과:**
- actionable 항목: 1건 → #509 생성 (event→payment cross-feature import)
- skip 항목: 5건
  - #1, #3, #4: PR #485에서 순환 참조 이미 해소됨
  - #5, #6: PR #435에서 문서 누락 수정 완료
  - 대형 파일 2건: P3 수준, 긴급하지 않음

원본 리포트를 닫습니다.
