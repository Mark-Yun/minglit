---
source_url: https://github.com/Mark-Yun/minglit/issues/1849
captured_at: 2026-04-25
issue_number: 1849
state: open
labels: [bug, needs-tpm, report-runtime-qa]
author: Mark-Yun
title: "🐛 Runtime QA 버그 — Pixel 7a ADB 무선 연결 세션 중 끊김 (Haiku 서브에이전트 adb pair 시도)"
---

# 🐛 Runtime QA 버그 — Pixel 7a ADB 무선 연결 세션 중 끊김 (Haiku 서브에이전트 adb pair 시도)

> Issue #1849 · open · created 2026-04-25T06:42:04Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1849

## Body

Scheduler: runtime-qa-cuj-user-sonnet-subagents

## 증상

CUJ-U03/U05 시나리오 수행을 위해 Haiku 서브에이전트를 위임하는 과정에서 Pixel 7a (adb-36141JEHN14570-SNEsXf._adb-tls-connect._tcp)의 무선 ADB 연결이 끊겼다.

## 발생 맥락

- **세션**: 20260425-150109
- **타임스탬프**: 2026-04-25 15:40 KST
- **발생 단계**: CUJ-U03/U05 Dev 유저 로그인 시도 중 Haiku 서브에이전트가 `adb pair`, `adb reconnect` 등의 명령어를 시도한 이후
- **원인 추정**: Haiku 서브에이전트가 디바이스 재연결을 위해 `adb pair` / `adb connect` 시도 → TLS 페어링 상태 오염 → mDNS 서비스에서 Pixel 7a 사라짐

## 영향

- Pixel 7a가 mDNS 서비스 목록에서 사라짐
- `adb devices -l` 빈 결과 (Galaxy S10e, Pixel Watch 4는 남아있음)
- 세션 중 CUJ-U03, CUJ-U05 테스트 미완료

## 완료된 테스트 결과

| 시나리오 | 결과 |
|---------|------|
| CUJ-U01 Step 1-3 (홈 → 이벤트 상세 → 신청 버튼) | ✅ PASS |
| CUJ-U01 Step 4 (로그인 리다이렉트) | ✅ PASS |
| CUJ-U04 (검색 → 필터 → 이벤트 → 뒤로가기 검색 유지) | ✅ PASS |
| CUJ-U03 (구매내역 → 취소) | ❌ 미완료 (로그인 필요) |
| CUJ-U05 (계정 삭제 플로우) | ❌ 미완료 (로그인 필요) |
| CUJ-U02 (체크인 → 매칭) | ❌ 미완료 (연결 끊김) |

## 재발 방지 제안

Haiku 서브에이전트 프롬프트에서 `adb pair`, `adb reconnect`, `adb disconnect`, `adb kill-server` 명령어를 명시적으로 금지해야 한다. 이 명령어들은 무선 ADB TLS 페어링 상태를 오염시켜 세션 전체를 블로킹할 수 있다.

## 환경

- 디바이스: Pixel 7a (adb-36141JEHN14570-SNEsXf._adb-tls-connect._tcp)
- 빌드: app_user v26.04.1845-dev (debug)
- OS: Android (Pixel 7a)
