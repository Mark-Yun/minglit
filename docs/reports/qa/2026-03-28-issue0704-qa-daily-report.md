---
source_url: https://github.com/Mark-Yun/minglit/issues/704
captured_at: 2026-03-28
issue_number: 704
state: closed
labels: [audit-report]
author: Mark-Yun
title: "🧪 QA 일일 리포트 — 2026-03-29"
---

# 🧪 QA 일일 리포트 — 2026-03-29

> Issue #704 · closed · created 2026-03-28T23:12:25Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/704

## Body

## 🧪 QA 일일 리포트 — 2026-03-29

### 오늘 머지된 PR 테스트 현황 (22건)

| PR | 제목 | 코드 변경 | 테스트 추가 | 상태 |
|----|------|----------|-----------|------|
| #617 | feat: 레이아웃 시스템 위젯 (MinglitSection, MinglitContentCard, MinglitKeyValueRow) + 카탈로그 | ✅ lib 5파일 | ❌ | ⚠️ 보강 필요 |
| #645 | fix(security): PGMQ 시스템 테이블 RLS 정책 누락 수정 | ✅ migration | ✅ pgTAP | OK |
| #644 | fix(security): settlement EF 권한 수준 불일치 수정 | ✅ EF 코드 | ✅ EF test | OK |
| #643 | fix(security): event-matching 인가 우회 차단 | ✅ EF 코드 | ✅ EF test | OK |
| #676 | fix(workers): SESSION_TIMEOUT unbound variable | scripts만 | - | OK |
| 나머지 17건 | docs/config/wireframe 변경 | 코드 변경 없음 | - | OK |

### 테스트 보강 제안

#### 1. [P2] PR #617 — 레이아웃 시스템 위젯 테스트 누락

**변경 파일:**
- `shared/packages/minglit_kit/lib/src/ui/widgets/common/minglit_content_card.dart`
- `shared/packages/minglit_kit/lib/src/ui/widgets/common/minglit_key_value_row.dart`
- `shared/packages/minglit_kit/lib/src/ui/widgets/common/minglit_section.dart`
- `shared/packages/minglit_kit/lib/src/features/dev/design_catalog_page.dart`

**제안:**
- `test/src/ui/widgets/common/minglit_section_test.dart` 신규 작성
  - 기본 렌더링 (title + children)
  - subtitle 있을 때 렌더링
  - trailing 위젯 렌더링
- `test/src/ui/widgets/common/minglit_content_card_test.dart` 신규 작성
  - 기본 렌더링 (child 포함)
  - padding/margin 커스텀 적용
  - onTap 콜백 동작
- `test/src/ui/widgets/common/minglit_key_value_row_test.dart` 신규 작성
  - label + value 텍스트 렌더링
  - value 위젯 커스텀 렌더링
- `test/goldens/layout_widgets_golden_test.dart` golden 테스트 추가 (light/dark)
- **이유:** 공통 레이아웃 위젯은 여러 피처에서 재사용됨. 시각적 회귀 방지 필요.
- **우선순위:** P2 (공통 UI 위젯이지만 순수 표시용)

### 버그 이슈 회고

| 이슈 | 상태 | 수정 PR | regression test | 비고 |
|------|------|--------|-----------------|------|
| #594 | ✅ Closed | #645 | ✅ `54_pgmq_system_rls_test.sql` | OK |
| #593 | ✅ Closed | #644 | ✅ `payout_sync_test.ts`, `settlement_register_transfers_test.ts` | OK |
| #592 | ✅ Closed | #643 | ✅ `event_matching_test.ts` | OK |
| #576 | ✅ Closed | - | - | PM으로 리디렉션 (피처 요청) |
| #674 | 🟡 Open | - | - | issue-worker 스크립트 버그, 수정 PR 미제출 |
| #654 | 🟡 Open | - | - | 파트너 홈 다크모드 미적응, 수정 PR 미제출 |

### 테스트 커버리지 현황

| 프로젝트 | lib 파일 | test 파일 | 비율 |
|----------|---------|----------|------|
| app_user | 64 | 49 | 76.6% |
| app_partner | 152 | 49 | 32.2% |
| minglit_kit | 152 | 63 | 41.4% |
| Edge Functions | 62 | 55 | 88.7% |

### CI 상태 (최근 24h)
- 총 실행: 10회
- 성공: 9회
- 취소: 1회 (재실행 후 성공)
- 실패: 0회
- Flaky test: 없음

### 요약
- 보안 수정 3건 모두 regression test 포함 ✅
- 코드 변경 PR 중 #617만 테스트 미포함 (P2)
- 미해결 버그 2건 (#674, #654) — 수정 PR 제출 시 regression test 포함 필요
- CI 안정적, flaky test 없음

🤖 자동 생성 — audit-qa

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-03-28

🤖 **tpm-staff** 분석 완료.

**결과:**
- actionable 항목: 0건
- skip 항목:
  - #674 (issue-worker 스크립트 버그) — 이미 `needs-dev` + P2 라벨 부여됨
  - #654 (파트너 홈 다크모드) — 이미 `needs-dev` + P2 라벨 부여됨
  - PR #617 레이아웃 위젯 테스트 누락 — 순수 표시용 위젯이라 핵심 비즈니스 로직 아님. 프로젝트 방향 기준 P3 수준으로 출시 전 배제
  - 보안 수정 3건 (#643/#644/#645) — 모두 regression test 포함, 정상
  - CI — 안정적 (실패 0건, flaky 없음)

원본 리포트를 닫습니다.
