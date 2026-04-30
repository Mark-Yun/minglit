---
source_url: https://github.com/Mark-Yun/minglit/issues/2056
captured_at: 2026-04-30
issue_number: 2056
state: open
labels: [report-runtime-qa]
author: Mark-Yun
title: "🛑 Hard Block — Galaxy S10e TLS Connection Failure (runtime-qa-cuj-user-sonnet-subagents)"
---

# 🛑 Hard Block — Galaxy S10e TLS Connection Failure (runtime-qa-cuj-user-sonnet-subagents)

> Issue #2056 · open · created 2026-04-30 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2056

## Body

Scheduler: runtime-qa-cuj-user-sonnet-subagents

## Hard Block: Galaxy S10e ADB TLS 연결 실패

**발생 시각**: 2026-04-30 15:00 KST
**스케줄러**: runtime-qa-cuj-user-sonnet-subagents
**예정 작업**: Mode B — cuj-user.md P0+P1 시나리오 실행

## 상황

`adb devices -l` 결과 연결된 디바이스 없음.

mDNS에서는 디바이스가 검색됨:
```
adb-R39M2033LFZ-McLWol	_adb-tls-connect._tcp	192.168.219.105:34655
```

그러나 직접 연결 시도 시 실패:
```
$ adb connect 192.168.219.105:34655
failed to connect to 192.168.219.105:34655

$ adb -s adb-R39M2033LFZ-McLWol._adb-tls-connect._tcp shell echo ok
adb: device 'adb-R39M2033LFZ-McLWol._adb-tls-connect._tcp' not found
```

## 원인 추정

`_adb-tls-connect._tcp` 서비스는 사전 페어링된 TLS 인증서가 필요함. 디바이스가 mDNS에 보이지만 TLS 인증서 페어링이 유실되어 연결 불가.

## 영향

- cuj-user.md P0+P1 시나리오 전체 스킵
- app_user 빌드 불가
- QA 세션 시작 불가

## 조치 필요

1. Galaxy S10e에서 무선 디버깅 재페어링:
   - 디바이스 → 설정 → 개발자 옵션 → 무선 디버깅 → 새 기기와 페어링
   - `adb pair <ip>:<pairing-port>` 실행
2. TLS 연결 복구 확인: `adb devices -l`
3. scheduler 재실행

## 관련 이슈

- #2050 (runtime-qa-cuj-partner-sonnet-subagents — no device)
- #2037 (runtime-qa-smoke-user-sonnet-subagents — no device)
- #2020 (runtime-qa-smoke-partner-sonnet-subagents — no device)
