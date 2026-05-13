---
source_url: https://github.com/Mark-Yun/minglit/issues/2402
captured_at: 2026-05-10
issue_number: 2402
state: open
labels: []
author: Mark-Yun
title: "[audit-uiux/차이] review_verification_screen — Flutter 구현 + 라우트 등록되어 있는데 mds spec 누락"
---

# [audit-uiux/차이] review_verification_screen — Flutter 구현 + 라우트 등록되어 있는데 mds spec 누락

> Issue #2402 · open · created 2026-05-10 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2402

## Body

Scheduler: needs-uiux-claude-1

## 발견 위치
- Flutter widget: \`apps/app_partner/lib/src/features/verification/review/review_verification_screen.dart\`
- Route 등록: \`apps/app_partner/lib/src/routing/app_routes.dart:204\` (\`VerificationReviewRoute\`, path \`/more/verifications/review\`, Fix #2142)
- 누락: \`apps/mds/docs/public/specs/review_verification_screen/\` (디렉토리 없음)

## 현재 / 권장
- 현재: \`ReviewVerificationScreen\` 위젯이 완전 구현되어 있고(\`getMyManagedPartners\` → \`getPendingRequests\` → \`reviewRequest\` 흐름), \`/more/verifications/review\` 경로로 라우팅 가능. 그러나 mds 단일 진실 디렉토리에 spec이 없다.
- 권장: 다른 \`*_screen\`/\`*_page\` 화면들과 동일하게 \`apps/mds/docs/public/specs/review_verification_screen/index.html\` (v1.4 template) + \`index.md\` + state PNG 세트를 갖춰야 한다. 화면이 mds 카탈로그(\`flow-data.ts\` / \`index\` 페이지)에서도 보이도록 \`route-pages.json\`에도 등록 필요.

## 영향
- 인증 심사 흐름(\`VerificationManagePage\` → \`CreateVerificationPage\` → \`ReviewVerificationScreen\`)의 마지막 단계가 mds 카탈로그에 누락 → audit / spec walk / 디자인 리뷰에서 chunk가 빠진다.
- Fix #2142가 라우트 등록만 복구했고 spec 동기화가 후속으로 따라오지 못한 케이스.

## reference
- 라우트 등록 위치: \`apps/app_partner/lib/src/routing/app_routes.dart:201-205\` (\`VerificationManageRoute\` / \`CreateVerificationRoute\` / \`VerificationReviewRoute\` 3종 형제 라우트 — 앞 2개는 이미 spec 보유)
- 형제 spec 참고: \`apps/mds/docs/public/specs/verification_manage_page/index.html\`, \`apps/mds/docs/public/specs/create_verification_page/index.html\`
- 닫힌 이슈 #2142 (라우트 등록 복구)
