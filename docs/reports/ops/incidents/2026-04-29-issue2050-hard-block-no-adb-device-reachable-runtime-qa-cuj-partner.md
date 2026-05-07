---
source_url: https://github.com/Mark-Yun/minglit/issues/2050
captured_at: 2026-04-29
issue_number: 2050
state: open
labels: [report-runtime-qa]
author: runtime-qa-cuj-partner-sonnet-subagents
title: "🛑 Hard Block — No ADB Device Reachable (runtime-qa-cuj-partner-sonnet-subagents)"
---

# 🛑 Hard Block — No ADB Device Reachable (runtime-qa-cuj-partner-sonnet-subagents)

> Issue #2050 · open · created 2026-04-29 · author @runtime-qa-cuj-partner-sonnet-subagents
> https://github.com/Mark-Yun/minglit/issues/2050

## Body

Scheduler: runtime-qa-cuj-partner-sonnet-subagents

## Hard Block: ADB 디바이스 미연결

**발생 시각**: 2026-04-29
**스케줄러**: runtime-qa-cuj-partner-sonnet-subagents
**예정 작업**: Mode B — cuj-partner.md P0+P1 시나리오 실행

## 상황

`adb devices -l` 실행 결과 연결된 디바이스 없음:

```
List of devices attached
(empty)
```

스케줄러 이름이 `-sonnet-subagents`로 끝나 gemini/haiku 패턴과 불일치. 디바이스 테이블에 없는 패턴이므로 연결된 첫 번째 디바이스를 사용하려 했으나 연결 자체가 없음.

## 영향

- cuj-partner.md P0+P1 시나리오 전체 스킵
- 앱 빌드 불가
- QA 세션 시작 불가

## 조치 필요

1. 테스트 디바이스 ADB 연결 복구
2. `adb devices -l`로 연결 확인 후 scheduler 재실행

## 관련 이슈

- #2037 (runtime-qa-smoke-user-sonnet-subagents)
- #2020 (runtime-qa-smoke-partner-sonnet-subagents)
