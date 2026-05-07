---
source_url: https://github.com/Mark-Yun/minglit/issues/2082
captured_at: 2026-05-02
issue_number: 2082
state: open
labels: [report-runtime-qa]
author: Mark-Yun
title: "🛑 Hard Block — No Android Device Connected (runtime-qa-smoke-user-sonnet-subagents)"
---

# 🛑 Hard Block — No Android Device Connected (runtime-qa-smoke-user-sonnet-subagents)

> Issue #2082 · open · created 2026-05-02 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2082

## Body

Scheduler: runtime-qa-smoke-user-sonnet-subagents

## 상황

모드 B 스모크 테스트 시작 시 ADB 디바이스 연결 불가.

## 확인 결과

```
$ adb devices -l
List of devices attached

$ adb -s adb-36141JEHN14570-SNEsXf._adb-tls-connect._tcp shell echo "pixel7a ok"
adb: device 'adb-36141JEHN14570-SNEsXf._adb-tls-connect._tcp' not found

$ adb -s adb-R39M2033LFZ-McLWol._adb-tls-connect._tcp shell echo "s10e ok"
adb: device 'adb-R39M2033LFZ-McLWol._adb-tls-connect._tcp' not found
```

두 디바이스(Pixel 7a, Galaxy S10e) 모두 연결 불가.

## 영향

- 대상 파일: `docs/qa/test-cases/app-user-smoke.md`
- P0+P1 시나리오 전체 스킵됨
- 테스트 커버리지 0%

## 관련 이슈

- #2078 (2026-05-01, cuj-partner-sonnet-subagents 동일 증상)
- #2042 (반복 ADB 연결 문제 구조적 개선 필요 TPM 보고)

## 요청

디바이스 물리적 연결 상태 확인 및 ADB TCP 연결 복구 필요.
