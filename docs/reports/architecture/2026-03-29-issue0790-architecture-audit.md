---
source_url: https://github.com/Mark-Yun/minglit/issues/790
captured_at: 2026-03-29
issue_number: 790
state: closed
labels: [P3-low, audit-report]
author: Mark-Yun
title: "🏗️ 아키텍처 감사 — 2026-03-30"
---

# 🏗️ 아키텍처 감사 — 2026-03-30

> Issue #790 · closed · created 2026-03-29T20:11:55Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/790

## Body

## 🏗️ 아키텍처 감사 리포트 — 2026-03-30

### 발견 항목

| # | 카테고리 | 위반 | 파일 | 설명 |
|---|----------|------|------|------|
| 1 | Feature 격리 | Cross-feature import (NEW) | `apps/app_user/lib/src/features/home/widgets/event_now_bar_controller.dart:1` | home → event/matching/matching_vote_controller.dart (PR #758에서 도입) |
| 2 | Feature 격리 | Cross-feature import (NEW) | `apps/app_user/lib/src/features/my_tickets/ui/my_ticket_card.dart:4` | my_tickets → ticket/ui/ticket_qr_screen.dart (PR #757에서 도입) |
| 3 | Feature 격리 | Cross-feature import (NEW) | `apps/app_user/lib/src/features/my_tickets/ui/my_tickets_page.dart:6` | my_tickets → ticket/ui/ticket_qr_screen.dart (PR #757에서 도입) |
| 4 | Feature 격리 | Cross-feature import (기존) | `apps/app_user/lib/src/features/event/admission/event_application_wizard_page.dart:7` | event → payment/ui/payment_success_screen.dart |

> **참고**: PR #783 (현재 BLOCKED)이 event → ticket, search → event, party → event 등 기존 cross-feature import 다수를 coordinator 패턴으로 전환 중. 머지 시 상당수 기존 위반 해소 예상.

### 아키텍처 건강도

| 항목 | 점수 | 비고 |
|------|------|------|
| Feature 격리 | 6/10 | app_user에 cross-feature import 잔존 (4건 신규/기존). PR #783 머지 시 개선 예상 |
| 패턴 준수 | 9/10 | Coordinator 패턴 (GoRouter 직접 사용 0건), Repository 패턴 (Supabase UI 직접 접근 0건) |
| 문서 일치도 | 9/10 | backend.md에 pii_masker.ts 누락 + CAS 제한사항 미갱신 → PR #788에서 수정 완료 |

### 대형 파일 (500줄 이상, 소스 코드만)

| 파일 | 줄 수 | 권장 조치 |
|------|-------|----------|
| `apps/app_partner/lib/src/features/application/event_application_manage_page.dart` | 592 | 탭별 위젯 분리 권장 |
| `shared/packages/minglit_kit/lib/src/data/repositories/event_repository_queries.dart` | 586 | 이미 part/mixin 패턴 적용. 현재 수준 유지 가능 |
| `apps/app_partner/lib/src/features/home/widgets/event_action_card.dart` | 526 | 액션 타입별 위젯 분리 검토 |
| `apps/app_user/lib/src/features/event/detail/event_detail_content.dart` | 512 | 섹션별 위젯 추출 검토 |
| `apps/app_partner/lib/src/features/settlement/settlement_page.dart` | 500 | 대시보드/리스트 탭 분리 검토 |

### 긍정적 변화 (최근 7일)

- **PR #768**: `event_application_manage_page.dart`에서 Supabase 직접 접근 → Repository 분리 완료
- **PR #780**: `revenue_summary_card.dart` settlement cross-import 해소
- **PR #773**: PII 마스킹 유틸리티 전체 적용 (보안 개선)
- **PR #783**: cross-feature import 대규모 해소 진행 중 (coordinator 패턴 전환)
- **PR #735**: MatchingVoteScreen → MatchingVoteContent 위젯 추출 (대형 파일 분리)

### 후속 조치

| 우선순위 | 항목 | 담당 |
|----------|------|------|
| P2 | #1-3 cross-feature import 해소 (home→event, my_tickets→ticket) | needs-dev |
| P2 | #4 event→payment cross-import 해소 | needs-dev (PR #783 범위 확장 또는 별도 이슈) |
| P3 | 대형 파일 분리 (592줄 event_application_manage_page.dart 등) | needs-dev |

### 문서 최신화

- PR #788: `backend.md` — pii_masker.ts 추가, CAS 제한사항 갱신 (auto-merge 대기 중)

🤖 자동 생성 — audit-arch worker


## Comments (1)

### Comment 1 — @Mark-Yun on 2026-03-30

🤖 **tpm-staff** DONE

**결과:**
- actionable 항목: 2건 → #851 (home→event cross-feature), #852 (my_tickets→ticket cross-feature) 생성
- skip 항목:
  - #4 event→payment cross-feature — 이미 이슈 #509 존재
  - 대형 파일 5건 — P3, 출시 전 우선순위 밖
  - PR #783은 리포트 작성 시 BLOCKED이었으나 현재 MERGED 완료

원본 리포트를 닫습니다.
