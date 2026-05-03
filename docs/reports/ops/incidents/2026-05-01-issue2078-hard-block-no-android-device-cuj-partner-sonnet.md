---
source_url: https://github.com/Mark-Yun/minglit/issues/2078
captured_at: 2026-05-01
issue_number: 2078
state: open
labels: [report-runtime-qa, bug, report-exec]
author: Mark-Yun
title: "🛑 Hard Block — No Android Device Connected (runtime-qa-cuj-partner-sonnet-subagents)"
---

# 🛑 Hard Block — No Android Device Connected (runtime-qa-cuj-partner-sonnet-subagents)

> Issue #2078 · open · created 2026-05-01 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2078

## Body

Scheduler: runtime-qa-cuj-partner-sonnet-subagents

## 이슈 내용

`adb devices -l` 실행 결과가 비어 있으며, 양쪽 알려진 디바이스 모두 연결 불가 상태입니다.

## 재현 단계

1. `adb devices -l` 실행 → 결과 없음
2. Pixel 7a 명시 연결 시도: `adb connect adb-36141JEHN14570-SNEsXf._adb-tls-connect._tcp` → `failed to resolve host`
3. Galaxy S10e 명시 연결 시도: `adb connect adb-R39M2033LFZ-McLWol._adb-tls-connect._tcp` → `failed to resolve host`

## 환경

- Scheduler: runtime-qa-cuj-partner-sonnet-subagents
- 실행 파일: `docs/qa/test-cases/cuj-partner.md`
- OS: darwin 23.6.0
- 모드: Mode B (정기 스모크 — P0+P1 시나리오)

## 관련 이슈

- #2077 (runtime-qa-cuj-partner-gemini 동일 증상)
- #1883 (runtime-qa-explore-user-gemini Pixel 7a 미연결)

## 조치 필요

- ADB 네트워크 디바이스(mDNS) 연결 인프라 점검
- 양쪽 디바이스 모두 호스트 해석 실패 상태 → 네트워크 레벨 문제일 가능성
- 연결 복구 전까지 runtime-qa-cuj-partner-sonnet-subagents CUJ 테스트 중단
