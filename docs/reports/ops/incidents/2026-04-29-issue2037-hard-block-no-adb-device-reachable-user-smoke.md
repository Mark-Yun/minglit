---
source_url: https://github.com/Mark-Yun/minglit/issues/2037
captured_at: 2026-04-29
issue_number: 2037
state: open
labels: [report-runtime-qa, needs-tpm]
author: Mark-Yun
title: "🛑 Hard Block — No ADB Device Reachable (runtime-qa-smoke-user-sonnet-subagents)"
---

# 🛑 Hard Block — No ADB Device Reachable (runtime-qa-smoke-user-sonnet-subagents)

> Issue #2037 · open · created 2026-04-29 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2037

## Body

Scheduler: runtime-qa-smoke-user-sonnet-subagents

## 요약

ADB 연결 가능한 디바이스가 없어 QA 세션을 시작할 수 없습니다.  
`adb devices -l` 결과가 비어 있고, 알려진 두 디바이스 모두 DNS 해석 실패입니다.

## 증상

```
$ adb devices -l
List of devices attached
(장치 없음)

$ adb connect adb-R39M2033LFZ-McLWol._adb-tls-connect._tcp
failed to resolve host: nodename nor servname provided, or not known

$ adb connect adb-36141JEHN14570-SNEsXf._adb-tls-connect._tcp
failed to resolve host: nodename nor servname provided, or not known
```

## 영향

- `runtime-qa-smoke-user-sonnet-subagents` 세션 전체 블로킹
- `app-user-smoke.md` P0+P1 시나리오 실행 불가

## 관련 이슈

- #1883 — Pixel 7a Not Reachable (여전히 열림, 2026-04-27)
- #2020 — Galaxy S10e Not Reachable (여전히 열림, 2026-04-28)

## 대응 필요

- [ ] 디바이스 물리적 연결 상태 확인
- [ ] ADB 무선 디버깅 재활성화 (개발자 옵션 → 무선 디버깅)
- [ ] mDNS 탐지 실패 시 직접 IP로 `adb connect <IP>:PORT` 시도
- [ ] 인프라 복구 후 본 이슈 및 #1883, #2020 일괄 종료

## 환경

- Scheduler: runtime-qa-smoke-user-sonnet-subagents
- 발생 시각: 2026-04-29
- 플랫폼: macOS Darwin 23.6.0
