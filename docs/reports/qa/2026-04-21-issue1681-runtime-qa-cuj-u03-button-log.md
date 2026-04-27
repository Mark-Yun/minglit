---
source_url: https://github.com/Mark-Yun/minglit/issues/1681
captured_at: 2026-04-21
issue_number: 1681
state: closed
labels: [report-runtime-qa]
author: Mark-Yun
title: "❓ Runtime QA 의문 — CUJ-U03: '환불 신청' 버튼이 '예매 취소'로 구현됨 (카탈로그 불일치)"
---

# ❓ Runtime QA 의문 — CUJ-U03: '환불 신청' 버튼이 '예매 취소'로 구현됨 (카탈로그 불일치)

> Issue #1681 · closed · created 2026-04-21T06:50:27Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1681

## Body

Scheduler: runtime-qa-cuj-user-sonnet-subagents

## 발견 경위
CUJ-U03 (마이페이지 → 구매내역 → 환불 신청) 테스트 중 발견.

## 관찰 내용
- **테스트 카탈로그 기대**: 구매 상세에서 "환불 신청" 버튼 탭 → 환불 정책 안내 + 확인 다이얼로그
- **실제 UI**: "예매 취소" 버튼 (영수증, 문의하기, 예매 취소 3개 버튼)
- 명시적 "환불 신청" 버튼은 없음
- 테스트 디바이스: Pixel 7a / 앱 버전: 26.04.1561-dev
- 로그인 계정: user_18_f_강남@test.com (user 계정)

## 의문
1. "예매 취소"가 환불 처리를 포함하는가? 아니면 별도 환불 UI가 존재하는가?
2. 카탈로그의 "환불 신청" 버튼 명칭을 "예매 취소"로 업데이트해야 하는가?
3. 환불 정책 안내 다이얼로그가 "예매 취소" 탭 시 표시되는가?

## 영향
- `docs/qa/test-cases/cuj-user.md` CUJ-U03 Step 3 검증 기준 업데이트 필요 가능성
- 환불 플로우가 카탈로그와 다른 경로로 구현되어 있는 경우 카탈로그 수정 필요

## Comments (2)

### Comment 1 — @Mark-Yun on 2026-04-21

🤖 **needs-qa-claude-1** 작업 시작합니다.

CUJ-U03 환불 신청 / 예매 취소 카탈로그 정확성 검증 후 카탈로그 또는 코드 정합성 정정 예정.

### Comment 2 — @Mark-Yun on 2026-04-21

🤖 **needs-qa-claude-1** 카탈로그 정정 PR 생성: #1685.

**확인된 사실** (코드 검증):
- 진입 버튼 라벨: `예매 취소` (`apps/app_user/lib/src/features/payment/ui/purchase_history_card.dart:220`)
- 탭 시: `예매 취소 확인` 다이얼로그 — 결제 금액 / 환불 비율 / 환불 금액 / 수수료 표시
- 실행 시: PG 자동 환불 처리 + `예매가 취소되었습니다.` 토스트
- 환불 기간 초과: `환불 불가` 다이얼로그 (고객센터 안내)

**판단**: 제품 UX 명명 "예매 취소"가 의도된 용어 (사용자 친화). 자동 환불을 포함하므로 카탈로그를 코드에 맞춰 정정.

PR #1685 머지 완료 시 자동 close 예정.
