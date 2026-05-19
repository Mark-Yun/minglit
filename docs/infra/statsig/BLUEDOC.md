# Statsig

minglit 프로젝트가 사용하는 Statsig 컴포넌트의 진입점. Feature gate, 실험, staged rollout, 메트릭 모니터링.

## 사용 컴포넌트

| 컴포넌트 | 용도 | 상세 |
|----------|------|------|
| **Feature Gates** | platform 별 flag, dependent gate, cohort 분기 — **Tier 1 feature kill 의 primary 도구** | TBD (`gates.md` 예정) |
| **Experiments** | A/B 실험, layer 기반 트래픽 분배 | TBD (`experiments.md` 예정) |
| **Dynamic Config** | layered 값 config | TBD |
| **Metrics** | flag rollout 메트릭 게이트 (one-sided sequential testing) | TBD |
| **Holdouts** | 통계적 회귀 검증 (장기 holdout cohort) | TBD |

## Firebase Remote Config 와의 경계

- **Statsig**: cohort 분기, 메트릭 비교, staged rollout, dependent gate
- **Firebase RC**: 단순 on/off, kill switch, cold start fetch, min-version endpoint
- 상세: [../branch-strategy/life-of-flag.md](../branch-strategy/life-of-flag.md)

## API 사용 룰 (literature gotchas)

- **layered experiment 에는 `getLayer` 만** ([Statsig 공식 docs](https://docs.statsig.com/layers/)). `getExperiment` 는 비직관적 동작
- **Holdout + Layer interaction**: holdout cohort 의 layer default 가 일반 사용자와 다름 ([Statsig 공식 docs](https://docs.statsig.com/holdouts/))
- **Nested dependent gate depth ≤ 2**: 6중 nested = 64 code paths (Featureflip), 테스트 cover 불가

## 핵심 컨벤션

- **Platform 별 flag 분리** — `{area}_{feature}_be / _mu / _mp / _web`
- **Backend 100% + 1주 soak 후 mobile/web 5% 진입** (dependent gate 강제)
- **4-flag-as-1 tooling** — 4개 flag cleanup 을 묶음 단위로 (안 그러면 `_be` 만 cleanup, `_mu` 50% 영구 고착)
- 메타데이터 (owner, cleanup 일, sibling flags, 관련 metric) 콘솔 description 필수
- staged rollout 메트릭 가드: error rate, crash-free, latency p95 (business metric 은 trip wire 만)

## 관련

- [../branch-strategy/life-of-flag.md](../branch-strategy/life-of-flag.md) — 전체 lifecycle
- [../branch-strategy/error-detection.md](../branch-strategy/error-detection.md) — Statsig 메트릭의 detection layer 위치
- [../firebase/BLUEDOC.md](../firebase/BLUEDOC.md)
- [BLUEDOC convention](../bluedoc/BLUEDOC.md)

---
_Reviewed: 2026-05-19 09:47_
