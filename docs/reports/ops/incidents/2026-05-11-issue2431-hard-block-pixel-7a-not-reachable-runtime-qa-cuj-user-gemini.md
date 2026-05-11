---
source_url: https://github.com/Mark-Yun/minglit/issues/2431
captured_at: 2026-05-11
issue_number: 2431
state: open
labels: [report-runtime-qa, bug]
author: runtime-qa-cuj-user-gemini
title: "🛑 Hard Block — Pixel 7a Device Not Reachable (runtime-qa-cuj-user-gemini)"
---

# 🛑 Hard Block — Pixel 7a Device Not Reachable (runtime-qa-cuj-user-gemini)

> Issue #2431 · open · created 2026-05-11 · author @runtime-qa-cuj-user-gemini
> https://github.com/Mark-Yun/minglit/issues/2431

## Body

Scheduler: runtime-qa-cuj-user-gemini

## 요약
Pixel 7a 장치가 연결되지 않아 CUJ 유저 QA 세션을 시작할 수 없습니다.

## 증상
- `adb devices -l` 명령 결과 장치 목록이 비어 있음.
- `*-gemini` 워커에 할당된 `Pixel 7a` 모델을 찾을 수 없음.

## 영향
- `runtime-qa-cuj-user-gemini` 세션 전체 블로킹
- `docs/qa/test-cases/cuj-user.md` 시나리오 실행 불가

## 대응 필요
- Pixel 7a 장치의 연결 상태 및 무선 디버깅 활성화 여부 확인 필요.

## 환경
- Scheduler: runtime-qa-cuj-user-gemini
- Target Model: Pixel 7a
- 시각: 2026-05-11
