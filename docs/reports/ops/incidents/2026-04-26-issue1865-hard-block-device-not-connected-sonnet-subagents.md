---
source_url: https://github.com/Mark-Yun/minglit/issues/1865
captured_at: 2026-04-26
issue_number: 1865
state: open
labels: [report-runtime-qa, needs-tpm]
author: Mark-Yun
title: "🛑 Hard Block — 디바이스 미연결 (runtime-qa-smoke-user-sonnet-subagents)"
---

# 🛑 Hard Block — 디바이스 미연결 (runtime-qa-smoke-user-sonnet-subagents)

> Issue #1865 · open · created 2026-04-26 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1865

## Body

Scheduler: runtime-qa-smoke-user-sonnet-subagents

## 블로킹 요약

QA 세션 시작 시 ADB 디바이스가 연결되어 있지 않아 모든 시나리오 실행이 불가합니다.

## 환경 정보

- **Scheduler**: runtime-qa-smoke-user-sonnet-subagents
- **발생 시각**: 2026-04-27
- **예상 디바이스**: 워커 이름에 gemini/haiku가 없으므로 `adb devices -l` 첫 번째 디바이스 사용 시도
- **adb devices -l 결과**: "List of devices attached" (빈 목록)
- **mDNS 상태**: Openscreen discovery 0.0.0 (정상 기동)

## 재현 명령어

```bash
adb devices -l
# 출력: List of devices attached (디바이스 없음)
```

## 영향

- 모드 B P0+P1 스모크 테스트 (`docs/qa/test-cases/app-user-smoke.md`) 전체 실행 불가
- 세션 중단

## 조치 필요

1. 디바이스를 ADB over TCP로 재연결하거나 (wireless adb pair)
2. 또는 이 scheduler에 할당된 디바이스 ID를 문서화하고 연결 확인
3. 워커 이름 `*-sonnet-subagents` 패턴에 대응하는 디바이스 정보가 프롬프트에 누락되어 있음 → 테스트 디바이스 테이블 업데이트 필요
