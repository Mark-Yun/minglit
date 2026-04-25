---
source_url: https://github.com/Mark-Yun/minglit/issues/678
captured_at: 2026-03-28
issue_number: 678
state: closed
labels: [audit-report]
author: Mark-Yun
title: "🏗️ 아키텍처 감사 — 2026-03-29"
---

# 🏗️ 아키텍처 감사 — 2026-03-29

> Issue #678 · closed · created 2026-03-28T15:07:52Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/678

## Body

## 🏗️ 아키텍처 감사 리포트 — 2026-03-29

### 발견 항목

| # | 카테고리 | 위반 | 파일 | 설명 |
|---|----------|------|------|------|
| 1 | Feature 격리 | Cross-import | `app_user/features/event/` → `auth`, `home`, `payment`, `ticket` | event 피처가 4개 다른 피처를 직접 import |
| 2 | Feature 격리 | Cross-import | `app_user/features/home/` → `auth`, `event` | home 피처가 auth, event를 직접 import |
| 3 | Feature 격리 | Cross-import | `app_user/features/partner/` → `home` | partner 피처가 home을 직접 import |
| 4 | Feature 격리 | Cross-import | `app_user/features/party/` → `event` | party 피처가 event를 직접 import |
| 5 | Feature 격리 | Cross-import | `app_user/features/search/` → `event` | search 피처가 event를 직접 import |
| 6 | Feature 격리 | Cross-import | `app_partner/features/home/` → `settlement` | home이 settlement_coordinator를 직접 import |

### 아키텍처 건강도

- Feature 격리: **6/10** — app_user에 cross-feature import 다수, app_partner는 PR #582 이후 1건만 잔존
- 패턴 준수: **10/10** — Repository 패턴 위반 0건, Coordinator 패턴 위반 0건 (UI에서 Supabase 직접 접근·GoRouter 직접 사용 없음)
- 문서 일치도: **8/10** — match_result 이벤트 타입·일부 컬럼/RPC 누락 → PR #677에서 수정

### 대형 파일 (500줄 이상, 프로덕션 코드만)

| 파일 | 줄 수 | 권장 조치 |
|------|-------|----------|
| `apps/app_partner/lib/src/features/application/event_application_manage_page.dart` | 595 | UI 로직 분리 (위젯 추출) |
| `apps/app_partner/lib/src/features/home/widgets/event_action_card.dart` | 526 | 하위 위젯 분리 |
| `apps/app_user/lib/src/features/event/detail/event_detail_content.dart` | 512 | 섹션별 위젯 분리 |
| `apps/app_partner/lib/src/features/settlement/settlement_page.dart` | 500 | 로직/UI 분리 |

> `design_catalog_page.dart` (1,141줄)은 dev-only 카탈로그이므로 제외.

### 문서 최신화

PR #677 에서 다음 항목 반영 완료:
- `backend.md`: `match_pairs.notification_sent` 컬럼, `cast_match_vote()` RPC 추가
- `global-event-pipeline.md`: `match_result` 이벤트 타입 (10번째), Route Matrix, 알림 템플릿 반영

### 참고

- app_user cross-feature import는 구조적으로 공유 모델/위젯을 `minglit_kit`로 추출해야 해결됨 (대규모 리팩토링 필요)
- app_partner는 PR #582에서 대부분 해결됨, 잔여 1건(home → settlement)은 대시보드 특성상 허용 가능

🤖 자동 생성 — audit-arch 워커

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-03-28

🤖 **tpm-staff** 분석 완료.

**결과:**
- actionable 항목: 0건 (신규 이슈 불필요)
- skip 항목: 전부

**skip 사유:**
| # | 항목 | 사유 |
|---|------|------|
| 1-5 | Cross-feature imports (app_user) | 이미 #634에서 추적 중. P2 리팩토링 — 출시 후 |
| 6 | Cross-feature import (app_partner) | 이미 #635에서 추적 중. 리포트도 "허용 가능" 판단 |
| - | 대형 파일 4건 | P3 리팩토링 — 출시 전 배제 대상 |
| - | 문서 최신화 | PR #677에서 이미 수정 완료 |
| - | 패턴 준수 | 10/10 위반 없음 |

**요약:** 프로젝트 방향(7월 출시 MVP 우선)에 따라 P2-P3 코드 건강성 항목은 출시 후 처리.
기존 이슈 #634, #635, #509에서 이미 추적 중.

원본 리포트를 닫습니다.
