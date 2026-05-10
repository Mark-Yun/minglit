---
source_url: https://github.com/Mark-Yun/minglit/issues/2403
captured_at: 2026-05-10
issue_number: 2403
state: open
labels: []
author: Mark-Yun
title: "[audit-uiux/차이] route-pages.json — 5개 등록 라우트 누락 (user 4 + partner 1)"
---

# [audit-uiux/차이] route-pages.json — 5개 등록 라우트 누락 (user 4 + partner 1)

> Issue #2403 · open · created 2026-05-10 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2403

## Body

Scheduler: needs-uiux-claude-1

## 발견 위치
\`apps/mds/docs/src/lib/route-pages.json\`

## 현재 / 권장

\`app_routes.dart\`에 \`@TypedGoRoute\`로 등록된 라우트 중 \`route-pages.json\`에 누락된 항목:

### app_user (4건)
| Route | Path | Widget | Flutter 위치 | mds spec |
|-------|------|--------|--------------|----------|
| \`EventMatchingRoute\` | \`/events/:eventId/matching\` | \`EventMatchingScreen\` | \`apps/app_user/lib/src/features/event/matching/ui/event_matching_screen.dart\` | \`event_matching_screen\` ✅ |
| \`EventApplicationConfirmationRoute\` | \`/events/:eventId/apply/confirmation\` | \`MinglitConfirmationPage\` (kit 컴포넌트) | \`apps/app_user/lib/src/routing/app_routes.dart:195-225\` | 없음 (composed page) |
| \`PurchaseHistoryDetailRoute\` | \`/purchase-history/:applicationId\` | \`PurchaseHistoryDetailPage\` | \`apps/app_user/lib/src/features/payment/ui/purchase_history_detail_page.dart\` | \`purchase_history_detail_page\` ✅ |
| \`EventApplicationReviewRoute\` | \`/purchase-history/:applicationId/review\` | \`EventApplicationReviewPage\` | \`apps/app_user/lib/src/features/payment/ui/event_application_review_page.dart\` | \`event_application_review_page\` ✅ |

### app_partner (1건)
| Route | Path | Widget | Flutter 위치 | mds spec |
|-------|------|--------|--------------|----------|
| \`VerificationReviewRoute\` | \`/more/verifications/review\` | \`ReviewVerificationScreen\` | \`apps/app_partner/lib/src/features/verification/review/review_verification_screen.dart\` | 없음 (issue #2402 별도) |

### 권장
- 위 5개 라우트를 \`route-pages.json\`의 \`user\` / \`partner\` 섹션에 등록 (\`{"<RouteName>": {"widget": "<WidgetName>", "file": "<path>"}}\` 형식)
- \`MinglitConfirmationPage\`처럼 kit 컴포넌트로 합성된 라우트는 \`widget: null\` + 라우트 빌더 코드 위치를 \`file\`로 가리키는 방식 협의 필요

## 영향
- \`route-pages.json\`은 \`flow-data.ts\` / spec generator / spec walk 워커 등이 참조하는 manifest. drift 시:
  - flow chart에서 빠진 라우트는 시각화되지 않음
  - per-spec index.md 자동 생성에서 widget→spec back-link 끊김
  - spec walk 카탈로그가 5개 화면을 빼먹을 가능성

## reference
- 라우트 정의: \`apps/app_user/lib/src/routing/app_routes.dart\` (line 175, 195, 272, 288)
- 라우트 정의: \`apps/app_partner/lib/src/routing/app_routes.dart:204\` (\`VerificationReviewRoute\`, Fix #2142)
- manifest: \`apps/mds/docs/src/lib/route-pages.json\`
- spec generator 가이드: \`apps/mds/docs/src/lib/flow-data.ts\` 헤더 주석 ("When routes change, update both the Mermaid charts here AND regenerate route-pages.json")
