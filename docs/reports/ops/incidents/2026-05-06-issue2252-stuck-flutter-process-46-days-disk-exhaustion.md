---
source_url: https://github.com/Mark-Yun/minglit/issues/2252
captured_at: 2026-05-06
issue_number: 2252
state: open
labels: [report-runtime-qa]
author: Mark-Yun
title: "🛑 Hard Block — stuck flutter process (PID 70137) running 46 days at 99% CPU, causing disk exhaustion"
---

# 🛑 Hard Block — stuck flutter process (PID 70137) running 46 days at 99% CPU, causing disk exhaustion

> Issue #2252 · open · created 2026-05-05T21:10:43Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2252

## Body

Scheduler: runtime-qa-smoke-user-sonnet-subagents

## 상황

QA 빌드 세션 중 디스크 공간 부족(ENOSPC)으로 `flutter build apk` 실패 발생. 조사 결과, 46일 이상 실행 중인 좀비 flutter 프로세스가 디스크를 소진 중임을 확인.

## Stuck Process 정보

| 항목 | 값 |
|------|-----|
| PID | 70137 |
| 실행 시간 | 46일 8시간 (`20Mar26` 시작) |
| CPU 사용률 | 99.4% |
| 프로세스 | `/Users/mark/development/flutter/bin/cache/dart-sdk/bin/dartvm flutter_tools.snapshot assemble` |
| 대상 | `apps/app_partner/build/app/intermediates/flutter/prodDebug/` |
| 빌드 타입 | `prod` flavor, debug |

## 영향

- 빌드 도중 디스크가 0바이트로 가득 참 → `app_user` QA 빌드 실패
- 정리 후 2.2GB 확보됐으나, 프로세스가 여전히 실행 중이라 재발 가능

## 재현

```bash
ps aux | grep flutter | grep "20Mar26"
# 또는
ps -p 70137 -o pid,etime,pcpu,args
```

## 권장 조치

```bash
kill 70137  # 또는 kill -9 70137
# 이후 필요시 재빌드
```

## 현재 디스크 상태 (정리 후)
- 가용: 2.2GB / 228GB (85% 사용)
