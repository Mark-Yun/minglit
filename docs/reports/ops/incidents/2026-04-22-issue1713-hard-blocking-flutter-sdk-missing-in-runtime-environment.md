---
source_url: https://github.com/Mark-Yun/minglit/issues/1713
captured_at: 2026-04-22
issue_number: 1713
state: open
labels: [P1-high, report-exec]
author: Mark-Yun
title: "🐛 [Hard Blocking] Flutter SDK missing in runtime environment"
---

# 🐛 [Hard Blocking] Flutter SDK missing in runtime environment

> Issue #1713 · open · created 2026-04-22T00:20:38Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1713

## Body

Scheduler: needs-runtime-qa-gemini-1

## 현상
`needs-runtime-qa-gemini-1` 워커가 모드 B(정기 스모크 테스트)를 위해 `app_user` 앱 빌드를 시도했으나, 실행 환경에 Flutter SDK가 설치되어 있지 않거나 PATH 설정이 누락되어 `flutter build` 명령이 실패합니다.

## 상세
- `flutter` 명령어: `command not found`
- `fvm` 명령어: `command not found`
- `dart` MCP 서버 에러: `Flutter SDK location unknown`
- 탐색 시도 경로: `/usr/local/bin`, `~/fvm`, `/opt/flutter` 모두 없음

## 기대 결과
`runtime-qa` 워커가 앱을 빌드하고 디바이스에 설치할 수 있도록 Flutter SDK가 사전 설치되고 PATH에 등록되어 있어야 합니다.

## 조치 요청
환경 설정 업데이트 및 SDK 설치가 필요합니다.


## Comments (2)

### Comment 1 — @Mark-Yun on 2026-04-23

🤖 **tpm-exec-report-claude-subagents**

runtime-qa 워커가 정기 스모크를 수행하려면 runtime 환경에 Flutter SDK가 설치되어야 함. 이건 워커 환경 구성 변경이 필요한 사안으로 Mark 판단이 필요합니다.

**옵션:**
- A) runtime 환경에 Flutter SDK 설치 (모드 B 지원)
- B) 모드 B를 polling 대신 on-demand로 전환 (요청 시 별도 컨테이너/환경에서 실행)
- C) 모드 B 제거하고 모드 A (이슈 재현)만 유지

P1-high + report-exec 부여. needs-runtime-qa는 일단 유지.

### Comment 2 — @Mark-Yun on 2026-04-23

🤖 **needs-tpm-claude-1** — 영향 범위 업데이트

동일 현상이 2026-04-23 `runtime-qa-smoke-partner-gemini` (partner 스모크 워커)에서도 재현 보고됨 (#1765, 중복으로 close). 

**확인된 영향 범위**: user + partner runtime-qa 양쪽 모두 모드 B 수행 불가. 최신 빌드 없이 구버전 APK로 QA가 진행될 리스크가 누적되고 있습니다.

Mark 판단이 계속 대기 중이라 상황이 악화되고 있음을 기록합니다.
