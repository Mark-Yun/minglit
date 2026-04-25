---
source_url: https://github.com/Mark-Yun/minglit/issues/1652
captured_at: 2026-04-20
issue_number: 1652
state: closed
labels: [bug, needs-swe, report-runtime-qa]
author: Mark-Yun
title: "⚠️ Runtime QA 버그 — CUJ-U03 구매 내역에서 예매 취소(환불) 버튼 미표시"
---

# ⚠️ Runtime QA 버그 — CUJ-U03 구매 내역에서 예매 취소(환불) 버튼 미표시

> Issue #1652 · closed · created 2026-04-20T06:27:44Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1652

## Body

Scheduler: runtime-qa-cuj-user-sonnet-subagents

## 발견 시나리오
CUJ-U03: 마이페이지 → 구매 내역 → 환불 신청

## 재현 단계
1. DevUserSwitchScreen에서 `user_18_f_강남@test.com` 로그인
2. 마이페이지 → 구매 내역 진입
3. 결제완료 상태의 구매 항목 확인

## 관찰 결과
- 구매 내역 화면에 2건의 구매 항목 표시됨:
  - `[QA] 스포츠 소셜 이벤트` (2026.04.20, 결제완료)
  - `자유 오픈 밍글` (2026.04.17, 환수없음)
- **예매 취소(환불) 버튼이 미표시** — 첫 번째 항목은 미래 이벤트임에도 버튼 없음

## 기대 결과
결제완료 + 이벤트 미시작 → `canCancel()` 조건 충족 → 예매 취소 버튼 표시

## 추정 원인
- 시드 데이터의 `status` 또는 `refund_status` 값 불일치
- 환불 정책 미설정 (환불 기간 0일 등)

## 환경
- 앱: app_user.dev (2026-04-20 빌드)
- 디바이스: Pixel 7a
- 테스트 계정: user_18_f_강남@test.com

## 판정
⚠️ WARNING — UI 플로우는 정상이나 핵심 환불 기능 접근 불가

## Comments (2)

### Comment 1 — @Mark-Yun on 2026-04-20

🤖 **needs-swe-sonnet-1** 작업 시작합니다.

### Comment 2 — @Mark-Yun on 2026-04-20

PR #1654 생성: https://github.com/Mark-Yun/minglit/pull/1654

**Root Cause**: `apply_event` RPC가 무료 신청 시 `payment_id=null, payment_amount=0`으로 저장. `canCancel()`이 `isRefundReady()`를 통해 `paymentId != null`을 요구하므로 취소 버튼 미표시.

**Fix**: 
- `canCancel()`: 무료 티켓 (paymentAmount=0, paymentId=null) 분기 추가
- `runRefundFlow()`: 무료 티켓은 환불 계산 건너뛰고 0원 확인 다이얼로그로 진행
- `user-cancel-order` EF는 payment_amount=0 케이스 이미 지원하므로 백엔드 수정 불필요

테스트 4개 추가, 전체 18개 통과.
