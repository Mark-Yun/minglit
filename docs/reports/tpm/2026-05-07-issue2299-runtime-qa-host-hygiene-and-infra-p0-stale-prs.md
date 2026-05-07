---
source_url: https://github.com/Mark-Yun/minglit/issues/2299
captured_at: 2026-05-07
issue_number: 2299
state: open
labels: [report-exec]
author: Mark-Yun
title: "⚠️ TPM Report — 2026-05-07: runtime-qa 호스트 hygiene 패턴 + 인프라 P0 7일째 + stale PR 3건"
---

# ⚠️ TPM Report — 2026-05-07: runtime-qa 호스트 hygiene 패턴 + 인프라 P0 7일째 + stale PR 3건

> Issue #2299 · open · created 2026-05-07 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2299

## Body

Scheduler: tpm-exec-report-claude-subagents

## TL;DR

- **Runtime-QA 호스트 hygiene 패턴 신규** — 48시간 내 2개 다른 워커 세션이 host 환경(disk/zombie process)에 의해 hard block. 워커별 클린업이 아니라 호스트 차원 SOP 필요.
- **인프라 P0 7일 연속** — Vercel deploy 10일째, iOS deploy User/Partner 8일째 dev 머지 차단. 어제 리포트(#2263) 대비 진척 0건.
- **Stale PR 3건** (#2018 DIRTY 9일째, #2210 DIRTY + CHANGES_REQUESTED, #2272 BLOCKED) — branch 위생 / 후속 PR 차단 위험.
- **운영 처리량은 정상** — 7일 132 이슈 생성, 102 종료(77%), 104 PR 머지.

## 1. Runtime-QA 호스트 hygiene 패턴 (신규 우려)

48시간 내 서로 다른 runtime-qa 스케줄러가 host 환경 자원으로 hard block:

| 이슈 | 일자 | 스케줄러 | 원인 |
|------|------|---------|------|
| [#2252](https://github.com/Mark-Yun/minglit/issues/2252) | 2026-05-05 | runtime-qa-smoke-user-sonnet-subagents | 46일 stuck flutter PID 70137 (CPU 99.4%) → 디스크 소진 |
| [#2277](https://github.com/Mark-Yun/minglit/issues/2277) | 2026-05-06 | runtime-qa-cuj-user-gemini | ENOSPC, `flutter clean` 수행에도 회복 안 됨 |

**공통 신호**: 다중 worker가 같은 Mac-mini에서 빌드 캐시를 분리/공유 없이 누적. 워커 종료 시 zombie 프로세스/캐시 회수가 자동화돼 있지 않음. 워커 단위 SOP가 아니라 **호스트 차원 정기 청소(또는 빌드 격리)** 가 root cause 해결.

**제안 (Mark 판단)**:
- (단기) launchd cron으로 stuck flutter 프로세스 감시 + KILL — `pgrep -f flutter_tools` + age check
- (중기) 워크트리별 `.dart_tool/flutter_build` 격리 + age 기반 정리 (ex. 7일 미사용 시 prune)
- (장기) runtime-qa 빌드를 별도 호스트/컨테이너로 격리 검토

오늘 새로 발생한 단발 사건이 아니라 패턴화 단계 — 다음 사이클에 같은 에러가 또 나오면 P0 escalation.

## 2. 인프라 P0 6일째 → 7일째

어제 리포트(#2263)에서 dump한 P0 ci-failure 이슈는 그대로 열려있음:

| 이슈 | 영역 | 차단 일수 |
|------|------|-----------|
| [#1917](https://github.com/Mark-Yun/minglit/issues/1917) | Vercel Deploy | 10일 (4-27 ~) |
| [#2049](https://github.com/Mark-Yun/minglit/issues/2049) | iOS Deploy User | 8일 (4-29 ~) |
| [#2061](https://github.com/Mark-Yun/minglit/issues/2061) | iOS Deploy Partner | 7일 (4-30 ~) |

이번 사이클에 진척 없음. 모두 `report-exec` 라벨 — 사람 자격증/환경 변수 등 수동 작업 추정. **출시 (2026-07) 전 iOS TestFlight·web 배포 길이 막힌 상태이므로 7월까지 미해결 시 G/L 위험.** 어제와 동일 escalation 유지.

## 3. Stale PR — branch hygiene

| PR | 상태 | 일수 | 비고 |
|----|------|------|------|
| [#2018](https://github.com/Mark-Yun/minglit/pull/2018) | DIRTY (conflict) | 9일 | `needs-swe` Riverpod 3 autoDispose race fix — rebase 필요 |
| [#2210](https://github.com/Mark-Yun/minglit/pull/2210) | DIRTY + CHANGES_REQUESTED | 2일 | Metabase legacy table drop, #2242 merge hold ([#2242](https://github.com/Mark-Yun/minglit/issues/2242)) |
| [#2272](https://github.com/Mark-Yun/minglit/pull/2272) | BLOCKED + CHANGES_REQUESTED | 1일 | EventApplicationListPage 4-탭 dashboard, #2126 후속 |

**Action**: #2018은 SWE에게 rebase 또는 close 결정 필요 — 9일째 DIRTY는 너무 길다. 이 사이클에 `needs-swe` 라벨 유지하되 SWE 워커 다음 사이클에 우선 처리하도록 코멘트 trigger 권장.

## 4. 운영 메트릭 (7일)

| 지표 | 값 | 평가 |
|------|----|------|
| 이슈 생성 | 132 | — |
| 이슈 종료 | 102 | close rate 77% (target 70%+) ✅ |
| PR 머지 | 104 | 매우 높음 ✅ |
| Open issue 총수 | 30 | 어제 33 → 30 (-3) ✅ |
| Untriaged routing | 2 → 0 | 본 사이클 처리 ✅ |

**워커 처리량은 건강하다.** 병목은 인프라 P0와 host hygiene이지 throughput이 아니다.

## 5. 본 사이클 처리

- [#2294](https://github.com/Mark-Yun/minglit/issues/2294) — close (PR #2291에서 이미 코드 반영)
- [#2127](https://github.com/Mark-Yun/minglit/issues/2127) — `needs-swe` + P2-medium 라벨링 (Carousel queue groupId)
- 본 리포트 — `report-exec` 발행

## 6. Mark 판단 요청

1. **Runtime-QA 호스트 hygiene SOP 채택 여부** — 단기 launchd cron 도입할지, 중기 빌드 격리로 갈지
2. **인프라 P0 3건의 차단 해소 일정** — 7월 출시까지 reasonable한 deadline 설정
3. **PR #2018 처리** — rebase / close / 보류 중 선택
