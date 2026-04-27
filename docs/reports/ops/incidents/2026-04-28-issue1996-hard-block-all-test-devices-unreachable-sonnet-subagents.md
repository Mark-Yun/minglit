---
source_url: https://github.com/Mark-Yun/minglit/issues/1996
captured_at: 2026-04-28
issue_number: 1996
state: open
labels: [report-runtime-qa, needs-tpm]
author: Mark-Yun
title: "🛑 Hard Block — All Test Devices Unreachable (runtime-qa-smoke-user-sonnet-subagents)"
---

# 🛑 Hard Block — All Test Devices Unreachable (runtime-qa-smoke-user-sonnet-subagents)

> Issue #1996 · open · created 2026-04-28 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1996

## Body

Scheduler: runtime-qa-smoke-user-sonnet-subagents

## 블로킹 요약

`runtime-qa-smoke-user-sonnet-subagents` 스케줄러 세션에서 모든 테스트 디바이스가 DNS 해석 실패로 연결 불가. QA 실행 중단.

## 환경

- **Scheduler**: runtime-qa-smoke-user-sonnet-subagents
- **실행 모드**: Mode B (app-user-smoke)
- **발생 시각**: 2026-04-28

## 진단 결과

```
$ adb devices -l
List of devices attached
(no devices)

$ adb connect adb-36141JEHN14570-SNEsXf._adb-tls-connect._tcp
failed to resolve host: 'adb-36141JEHN14570-SNEsXf._adb-tls-connect._tcp': nodename nor servname provided, or not known

$ adb connect adb-R39M2033LFZ-McLWol._adb-tls-connect._tcp
failed to resolve host: 'adb-R39M2033LFZ-McLWol._adb-tls-connect._tcp': nodename nor servname provided, or not known
```

## 영향

- **Pixel 7a** (gemini 워커용): DNS 해석 실패
- **Galaxy S10e** (haiku 워커용): DNS 해석 실패
- 본 스케줄러(`sonnet-subagents`)는 테이블에 매핑된 디바이스가 없어 fallback(`adb devices -l` 첫 번째)을 사용하려 했으나 디바이스 없음

## 관련 이슈

- #1883 (Pixel 7a Not Reachable — 2026-04-27, 아직 open)

## 필요 조치

1. 두 디바이스 모두 Wi-Fi ADB 연결 복구 확인
2. mDNS(`.local` DNS) 해석 가능한 네트워크 상태 확인
3. `runtime-qa-smoke-user-sonnet-subagents` 스케줄러의 디바이스 매핑 추가 (`common-runtime-qa.txt` 디바이스 테이블)
