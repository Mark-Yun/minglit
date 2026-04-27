---
source_url: https://github.com/Mark-Yun/minglit/issues/726
captured_at: 2026-03-29
issue_number: 726
state: closed
labels: [report-exec]
author: Mark-Yun
title: "⚠️ TPM Report — 2026-03-29: needs-dev 백로그 급증 (30건 적체, 주간 소화율 10%)"
---

# ⚠️ TPM Report — 2026-03-29: needs-dev 백로그 급증 (30건 적체, 주간 소화율 10%)

> Issue #726 · closed · created 2026-03-29T03:15:37Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/726

## Body

## 요약

needs-dev 라벨 이슈가 **30건 적체** 중이며, 지난 7일간 소화된 건 **3건**(10%)에 불과합니다.
감사 워커들의 이슈 생성 속도가 issue-worker의 처리 속도를 크게 초과하고 있습니다.

## 현황

| 지표 | 수치 |
|------|------|
| needs-dev 미처리 | 30건 |
| 지난 7일 신규 생성 | ~35건 |
| 지난 7일 처리 완료 | 3건 |
| 소화율 | ~10% |

### 우선순위별 분포

| 우선순위 | 건수 | 비율 |
|----------|------|------|
| P1-high | 15건 | 50% |
| P2-medium | 14건 | 47% |
| P3-low | 1건 | 3% |

## P1-high 주요 적체 항목

- **event-now-bar 피처** (#659~#665): 7건 — 상태머신, Realtime, 미니바, 바텀시트 등 연쇄 의존성
- **내 티켓 피처** (#637~#641): 5건 — Repository, Controller, UI, 라우트
- **디자인 시스템 테스트** (#689, #690): 2건
- **리팩토링** (#658): 1건

## 분석

1. **감사 → 이슈 파이프라인 과잉**: audit 워커들이 주 35건 이슈 생성 vs issue-worker 주 3건 처리
2. **피처 이슈 일괄 생성**: event-now-bar, 내 티켓 등 피처 플랜에서 한 번에 5~7건씩 생성됨
3. **issue-worker 단일 처리**: 현재 issue-worker 1개가 순차 처리 — 병목

## 의사결정 필요 사항

1. **issue-worker 병렬화**: 여러 issue-worker를 동시에 돌려 처리량 증대?
2. **P2 이슈 일시 보류**: P1-high 15건 우선 집중, P2는 출시 후로 미루기?
3. **감사 주기 조절**: audit 워커 실행 빈도를 줄여 이슈 생성 속도 조절?
4. **피처 이슈 배치 크기**: 한 피처의 서브이슈를 한 번에 다 만들지 않고, 앞 이슈가 완료되면 다음 것 생성?

## 권장안

- **단기**: P1-high 15건에 집중. P2는 freeze.
- **중기**: issue-worker 병렬 실행 (2~3개) 또는 피처별 순차 파일링으로 전환.

## Comments (2)

### Comment 1 — @Mark-Yun on 2026-03-29

🤖 TPM 업데이트 (2026-03-29 2차 분석)

**needs-dev 백로그 악화 중:**

| 지표 | 이전 (3/29 1차) | 현재 |
|------|----------------|------|
| 총 적체 | 30건 | **41건 (+37%)** |
| P1-high | 15건 | **21건 (+40%)** |
| P2-medium | 14건 | **17건 (+21%)** |
| P3-low | 1건 | 3건 |

하루 만에 11건 증가. 감사 워커 이슈 생성 속도 > issue-worker 처리 속도 격차가 벌어지고 있음.

**권장 조치** (기존 제안 유지 + 강화):
1. 감사 워커 이슈 생성 속도 조절 (throttle) — 하루 최대 N건 cap 설정
2. P1-high 21건 중 피처 의존성 체인(event-now-bar 7건, 내 티켓 5건)은 순차 처리가 필수 → issue-worker가 체인 단위로 집중 처리하도록 가이드
3. P3-low 3건은 출시 전 배제 대상 — 라벨만 유지하고 처리 대기열에서 제외

### Comment 2 — @Mark-Yun on 2026-03-29

issue-worker 정상 동작 복구됨 (set -e 제거, 좀비 정리). 백로그 소화 관찰 중.
