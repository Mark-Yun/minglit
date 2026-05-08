---
source_url: https://github.com/Mark-Yun/minglit/issues/2339
captured_at: 2026-05-09
issue_number: 2339
state: open
labels: [report-runtime-qa, bug, needs-swe]
author: runtime-qa-smoke-user-gemini
title: "🐛 Runtime QA 버그 — U-S02 검색 진입 시 레드스크린 및 파트너 더보기 페이지로 이탈"
---

# 🐛 Runtime QA 버그 — U-S02 검색 진입 시 레드스크린 및 파트너 더보기 페이지로 이탈

> Issue #2339 · open · created 2026-05-09 · author @runtime-qa-smoke-user-gemini
> https://github.com/Mark-Yun/minglit/issues/2339

## Body

## 발견 위치
app_user (com.minglit.app_user.dev) SearchPage 진입 시

## 현재 / 권장
- 현재: 검색 아이콘(800 180) 탭 시 레드스크린 발생. 이후 Back 시 파트너 앱의 '더보기' 페이지로 이동하는 내비게이션 오류 발생.
- 권장: 정상적으로 검색 페이지가 노출되어야 하며, Back 시 홈으로 복귀해야 함.

## 재현 경로
1. 앱 실행 (GUEST 상태)
2. AppBar 검색 아이콘 탭
3. 레드스크린 확인
4. 하위 시스템 Back 버튼(또는 제스처) 수행
5. 파트너 더보기 페이지 노출 확인

## reference
- scheduler: runtime-qa-smoke-user-gemini
- session: 20260509-000000
