---
source_url: https://github.com/Mark-Yun/minglit/issues/1269
captured_at: 2026-04-12
issue_number: 1269
state: closed
labels: [bug, report-runtime-qa]
author: Mark-Yun
title: "🐛 Runtime QA 버그 — 파트너 앱 (app_partner) P0/P1 스모크 실패"
---

# 🐛 Runtime QA 버그 — 파트너 앱 (app_partner) P0/P1 스모크 실패

> Issue #1269 · closed · created 2026-04-12T03:21:41Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1269

## Body

Scheduler: runtime-qa-smoke-partner-gemini
Session ID: 20260412-120033
Test Case: docs/qa/test-cases/app-partner-smoke.md

### 1. [Critical] 직원 관리 (Staff Management) 화면 무한 로딩 (RPC 에러)
- **현상**: '더보기 > 직원 관리' 진입 시 스피너만 돌며 목록이 뜨지 않음.
- **로그**: ❌ [PartnerRepo] getPartnerMembers Error ERROR: PostgrestException(message: structure of query does not match function result type, code: 42804, details: Returned type partner_role does not match expected type text in column 3., hint: null)
- **원인 추정**: Supabase RPC get_partner_members의 반환 타입(enum)과 앱측 기대 타입(text) 불일치. 최근 스키마 변경 여파로 보임.

### 2. [Major] 파티 관리 (Party Management) 메뉴 실종
- **현상**: docs/qa/test-cases/app-partner-smoke.md에 따르면 '더보기' 탭에 '파티 관리' 메뉴가 있어야 하나, Owner/Partner 계정 모두에서 보이지 않음.
- **영향**: 파티(장소) 목록 조회 및 기본 정보 편집 불가.

### 3. [Major] 장소 가이드 (Location Guide) 배너 실종
- **현상**: 홈 화면에 '장소 가이드' 배너(P-S06)가 보이지 않음.

### 4. [Warning] 디버그 아이콘의 내비게이션 바 침범
- **현상**: 개발용 레드 버그 아이콘(FAB)이 하단 탭바의 '더보기' 영역과 겹쳐 있어, 메뉴 이동 시 의도치 않게 버그 리포트 창이 열림.

---
**Evidence**:
- 스크린샷: qa-sessions/20260412-120033/screenshots/member_list_final.png
- 로그: adb logcat 내 PostgrestException 42804


## Comments (6)

### Comment 1 — @Mark-Yun on 2026-04-12

🤖 **needs-swe-codex-1** 작업 시작합니다.

### Comment 2 — @Mark-Yun on 2026-04-12

🤖 **needs-swe-codex-1** 구현 완료, PR 생성했습니다: https://github.com/Mark-Yun/minglit/pull/1270

리뷰 대기로 라벨을 전환합니다.

### Comment 3 — @Mark-Yun on 2026-04-12

🤖 **needs-review-sonnet-1** 코드 리뷰 완료. 수정 필요 사항 발견.

**[PR #1270](https://github.com/Mark-Yun/minglit/pull/1270) 리뷰 결과**

`partner_home_page.dart`에서 `LocationGuideBanner`가 동일 스크롤 뷰에 두 번 삽입되어 있습니다. 이로 인해:
1. 홈 화면에 배너 2개 표시 — UX 회귀
2. `partner_home_page_test.dart`의 `findsOneWidget` 매처 실패 → CI 블록

올바른 위치 한 곳만 남기고 수정해 주세요. 수정 후 `needs-review` 라벨 재부착해 주세요.

Reviewed commit: 54d2b88e8b34106649fccaf49a85e3c5de33413b

### Comment 4 — @Mark-Yun on 2026-04-12

🤖 **needs-review-sonnet-1** 코드 리뷰 완료.

PR #1270 diff 검토 결과 문제 없음. CI 통과 대기 중.

리뷰 요약:
- SQL role::text 캐스트 수정: PostgREST 42804 근본 원인 해결 확인
- LocationGuideBanner 이중 삽입: if/else 상호배타 분기 — 올바름
- 신규 테스트 커버리지 적절

GitHub 계정 동일로 approve 불가 — Approvals 0개 필요이므로 ci-result 통과 시 auto-merge 진행.

### Comment 5 — @Mark-Yun on 2026-04-12

🤖 **needs-review-sonnet-1** PR #1270 머지 완료. needs-review 라벨 제거. 모니터링 종료.

### Comment 6 — @Mark-Yun on 2026-04-12

🤖 **needs-swe-codex-1** PR #1270 머지 완료했습니다.

- `get_partner_members_with_user` RPC role enum/text 불일치 수정
- 더보기 `파티 관리` 메뉴 복구
- 홈 `장소 가이드` 배너 복구
- 디버그 FAB 침범 건은 dev에 이미 반영된 Fix #1262로 확인

검증: CI `ci-result` 통과, PR merged.
