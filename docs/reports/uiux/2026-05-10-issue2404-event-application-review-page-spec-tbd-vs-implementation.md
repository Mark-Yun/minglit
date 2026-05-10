---
source_url: https://github.com/Mark-Yun/minglit/issues/2404
captured_at: 2026-05-10
issue_number: 2404
state: open
labels: []
author: Mark-Yun
title: "[audit-uiux/차이] event_application_review_page spec — Widget 'TBD' 표기 vs 실제 구현 완료"
---

# [audit-uiux/차이] event_application_review_page spec — Widget 'TBD' 표기 vs 실제 구현 완료

> Issue #2404 · open · created 2026-05-10 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2404

## Body

Scheduler: needs-uiux-claude-1

## 발견 위치
- spec: \`apps/mds/docs/public/specs/event_application_review_page/index.html\` (Header 'Route / Surface' row + 'Widget class' table cell)
- 실제 위젯: \`apps/app_user/lib/src/features/payment/ui/event_application_review_page.dart\`
- 라우트: \`apps/app_user/lib/src/routing/app_routes.dart:288-297\` (\`EventApplicationReviewRoute\`, path \`/purchase-history/:applicationId/review\`)

## 현재 / 권장
- 현재 (spec): 두 군데에서 widget을 'TBD'로 표시.
  - \`<tr><th>Route / Surface</th><td><code>EventApplicationReviewRoute</code> · widget: <code>EventApplicationReviewPage</code> <em>(TBD)</em></td></tr>\`
  - \`<tr><th>Widget class</th><td><code>EventApplicationReviewPage</code> · <code>TBD</code></td></tr>\`
- 현재 (코드): \`EventApplicationReviewPage\` 위젯이 실제로 존재하고 라우트도 등록되어 있다 (\`final String applicationId\` 받아 build).
- 권장: spec의 'TBD' 라벨을 제거하고 실제 구현 위치(\`apps/app_user/lib/src/features/payment/ui/event_application_review_page.dart\`)를 'Widget class' / 'Route / Surface' row에 명시. 추가로 spec이 언급하는 \`MinglitTimeline\` / \`MinglitTimelineStep\` 구현 상태도 재확인 필요(아직 mds_core에 없으면 별도 follow-up).

## 영향
- "TBD"라고 표시된 spec은 spec walk / audit / 디자인 리뷰에서 "구현 대기 중"으로 오해되어 실제 구현물 검증이 누락된다.
- \`MinglitTimeline\` / \`MinglitTimelineStep\` 컴포넌트 의존이 spec에 명시되어 있지만 mds_core 추가 여부와 실제 위젯 사용 여부가 spec/코드 어느 쪽에서도 확정되지 않은 상태.

## reference
- spec: \`apps/mds/docs/public/specs/event_application_review_page/index.html\`
- 코드: \`apps/app_user/lib/src/features/payment/ui/event_application_review_page.dart\`
- 라우트: \`apps/app_user/lib/src/routing/app_routes.dart:288\`
