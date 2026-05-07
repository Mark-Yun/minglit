---
source_url: https://github.com/Mark-Yun/minglit/issues/2087
captured_at: 2026-05-02
issue_number: 2087
state: open
labels: [report-runtime-qa, bug]
author: Mark-Yun
title: "🛑 Hard Block — No Android Device Connected (runtime-qa-cuj-user-sonnet-subagents)"
---

# 🛑 Hard Block — No Android Device Connected (runtime-qa-cuj-user-sonnet-subagents)

> Issue #2087 · open · created 2026-05-02 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2087

## Body

Scheduler: runtime-qa-cuj-user-sonnet-subagents

## 요약

세션 시작 시 ADB 디바이스가 연결되지 않아 CUJ-U 테스트를 실행할 수 없습니다.

## 증상

```
$ adb devices -l
List of devices attached
(empty)

$ adb connect adb-36141JEHN14570-SNEsXf._adb-tls-connect._tcp
failed to resolve host: 'adb-36141JEHN14570-SNEsXf._adb-tls-connect._tcp': nodename nor servname provided, or not known

$ adb connect adb-R39M2033LFZ-McLWol._adb-tls-connect._tcp
failed to resolve host: 'adb-R39M2033LFZ-McLWol._adb-tls-connect._tcp': nodename nor servname provided, or not known
```

## 환경

- Scheduler: `runtime-qa-cuj-user-sonnet-subagents`
- 실행 시각: 2026-05-02
- 대상 테스트: `docs/qa/test-cases/cuj-user.md` P0+P1 (CUJ-U01 ~ CUJ-U05)
- 시도한 디바이스:
  - Pixel 7a: `adb-36141JEHN14570-SNEsXf._adb-tls-connect._tcp` → DNS 해석 실패
  - Galaxy S10e: `adb-R39M2033LFZ-McLWol._adb-tls-connect._tcp` → DNS 해석 실패

## 영향

CUJ-U01(결제/신청), CUJ-U02(체크인/매칭), CUJ-U03(환불), CUJ-U04(검색), CUJ-U05(계정 삭제) 전체 실행 불가.

## 관련 이슈

- #2082 (runtime-qa-smoke-user-sonnet-subagents 동일 증상)
- #2078 (runtime-qa-cuj-partner-sonnet-subagents 동일 증상)
- #1883 (runtime-qa-explore-user-gemini — Pixel 7a not reachable)

## 조치 필요

디바이스 물리적 연결 상태 및 ADB over WiFi / mDNS 서비스 확인 필요.
