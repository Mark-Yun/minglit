---
source_url: https://github.com/Mark-Yun/minglit/issues/2129
captured_at: 2026-05-03
issue_number: 2129
state: open
labels: [report-runtime-qa]
author: runtime-qa-cuj-partner-sonnet-subagents
title: "❓ Runtime QA 의문 — 파트너 대시보드 \"준비 중\" 카드에 숫자 대신 \"-\" 표시"
---

# ❓ Runtime QA 의문 — 파트너 대시보드 "준비 중" 카드에 숫자 대신 "-" 표시

> Issue #2129 · open · created 2026-05-03 · author @runtime-qa-cuj-partner-sonnet-subagents
> https://github.com/Mark-Yun/minglit/issues/2129

## Body

Scheduler: runtime-qa-cuj-partner-sonnet-subagents

## 발견 위치
파트너 대시보드 (`/`) 상단 통계 카드 섹션

## 관찰 내용
대시보드 진입 시 상단 3개 통계 카드:
- **승인 대기**: `0` (숫자 표시)
- **다가오는 이벤트**: `3` (숫자 표시)
- **준비 중**: `-` (숫자 미표시)

"준비 중" 카드만 숫자 없이 `-`만 표시됨. 다가오는 이벤트가 3개 있는 상황에서 준비 중 상태 이벤트 수가 표시되지 않음.

## 질문
- `-`는 의도된 UX인가? (null/unknown 상태를 의미?)
- 아니면 해당 API 응답이 누락되어 fallback으로 `-`를 표시하는 건가?
- `0`과 `-`가 의미상 다른 경우라면 tooltipㆍ설명 텍스트가 필요하지 않은가?

## 재현
1. 파트너 앱 실행 (서울 강남 소셜클럽 계정)
2. 대시보드 홈 화면 진입
3. 상단 통계 카드 3개 확인 → "준비 중" 카드에 `-` 표시

## 환경
- Scheduler: runtime-qa-cuj-partner-sonnet-subagents
- Device: Galaxy S10e (SM-G970N)
- App: com.minglit.app_partner.dev (v26.05.2114-dev)
- 세션: 2026-05-03T21:01
