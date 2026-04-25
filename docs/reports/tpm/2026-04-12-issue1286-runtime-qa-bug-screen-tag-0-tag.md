---
source_url: https://github.com/Mark-Yun/minglit/issues/1286
captured_at: 2026-04-12
issue_number: 1286
state: closed
labels: [bug, needs-review, report-runtime-qa]
author: Mark-Yun
title: "⚠️ Runtime QA 버그 — 홈 화면 '🔥 핫 태그' 섹션에 이벤트 0개 태그 노출"
---

# ⚠️ Runtime QA 버그 — 홈 화면 '🔥 핫 태그' 섹션에 이벤트 0개 태그 노출

> Issue #1286 · closed · created 2026-04-12T08:58:28Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1286

## Body

Scheduler: runtime-qa-smoke-user-sonnet-subagents

## 현상

홈 화면 '🔥 핫 태그' 섹션에 표시되는 모든 태그가 "7일 +0" (최근 7일 이벤트 0개)로 표시됨. '핫 태그'는 활성도가 높은 태그를 의미하는데 0개 이벤트 태그가 노출되는 것은 개념적 모순.

## 재현 경로

1. 앱 실행 → 홈 화면
2. '🔥 핫 태그' 섹션 확인

## 관찰 데이터 (uiautomator dump)

```
#독서 / 7일 +0
#스터디 / 7일 +0
#영화 / 7일 +0
#커피 / 7일 +0
#클럽 / 7일 +0
#야외 / 7일 +0
```

모든 핫 태그가 7일 내 이벤트 0개.

## 기대 동작

- 실제 이벤트가 있는 태그만 핫 태그로 노출
- 또는 이벤트 0개인 경우 해당 태그를 핫 태그 섹션에서 숨김
- 또는 섹션 자체를 빈 상태로 처리 ("핫 태그가 없습니다")

## 판정 근거

카운트 논리 모순: '핫' 태그라 명명했으나 0개 이벤트로 활성도 없음.

## 증거

![홈 화면 핫 태그](https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/runtime-qa/20260412-173634/home_hot_tags.png)

## 세션 정보

- Session: 20260412-173634
- Device: Pixel 7a (adb-36141JEHN14570-SNEsXf._adb-tls-connect._tcp)
- 앱 버전: dev flavor debug build (dev branch HEAD)

## Comments (3)

### Comment 1 — @Mark-Yun on 2026-04-12

🤖 **needs-swe-sonnet-subagents-1** 작업 시작합니다.

### Comment 2 — @Mark-Yun on 2026-04-12

PR #1301 생성. auto-merge 활성화.

### Comment 3 — @Mark-Yun on 2026-04-12

🤖 **needs-swe-sonnet-subagents-1** PR #1301 머지 완료. 이슈 #1286 해결.

CodeRabbit 코멘트(Fix 주석 포맷) 대응 후 자동 머지됨.
