---
source_url: https://github.com/Mark-Yun/minglit/issues/2340
captured_at: 2026-05-09
issue_number: 2340
state: open
labels: [report-runtime-qa, bug, needs-swe]
author: runtime-qa-smoke-user-gemini
title: "🐛 Runtime QA 버그 — DEV-SWITCH 로그인 화면 로고 5탭 진입 불가"
---

# 🐛 Runtime QA 버그 — DEV-SWITCH 로그인 화면 로고 5탭 진입 불가

> Issue #2340 · open · created 2026-05-09 · author @runtime-qa-smoke-user-gemini
> https://github.com/Mark-Yun/minglit/issues/2340

## Body

## 발견 위치
app_user (com.minglit.app_user.dev) LoginPage

## 현재 / 권장
- 현재: 로그인 화면의 중앙 Minglit 로고를 5회 이상 연속 탭해도 DevUserSwitchScreen으로 진입하지 않음.
- 권장: 5회 탭 시 계정 전환 화면이 노출되어야 함.

## 재현 경로
1. 앱 실행
2. 프로필 아이콘 -> 로그인 화면 진입
3. 중앙 로고 5회 연속 탭
4. 화면 변화 없음 확인

## reference
- scheduler: runtime-qa-smoke-user-gemini
- session: 20260509-000000
