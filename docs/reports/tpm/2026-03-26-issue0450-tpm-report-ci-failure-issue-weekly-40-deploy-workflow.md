---
source_url: https://github.com/Mark-Yun/minglit/issues/450
captured_at: 2026-03-26
issue_number: 450
state: closed
labels: [P2-medium, report-exec]
author: Mark-Yun
title: "⚠️ TPM Report — 2026-03-26: ci-failure 이슈 주간 40건 — 배포 워크플로우 안정성 검토 필요"
---

# ⚠️ TPM Report — 2026-03-26: ci-failure 이슈 주간 40건 — 배포 워크플로우 안정성 검토 필요

> Issue #450 · closed · created 2026-03-26T07:04:45Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/450

## Body

## 주간 운영 분석 (2026-03-19 ~ 2026-03-26)

### 이슈/PR 트렌드

| 지표 | 값 |
|------|-----|
| 이슈 생성 | 100건 |
| 이슈 종료 | 91건 (91% close rate) |
| PR 생성 | 50건 |
| PR 머지 | 44건 (88% merge rate) |
| 기여자 | Mark-Yun, dependabot |

### 🔴 핵심 발견: ci-failure 이슈 40건/주

7일간 `ci-failure` 라벨 이슈가 **40건** 생성됨 (전체 이슈의 40%).

| 유형 | 건수 | 우선순위 |
|------|------|---------|
| Vercel Deploy failed | 다수 | P0-critical |
| Daily CUJ failed | 다수 | P0-critical |
| Android Deploy failed | 다수 | P1-high |

- 39/40건 closed → 대응은 되고 있으나, **주당 40건은 노이즈 수준**
- 핵심 CI (`ci-result`) 실패율은 **4%로 양호** (50건 중 2건 실패)
- 실패는 deploy 워크플로우(Vercel, Android, Supabase Migration, CUJ)에 집중

### 검토 요청 사항

1. **배포 워크플로우 안정성**: Vercel/Android deploy가 반복 실패하는 근본 원인 파악 필요
   - 일시적 인프라 이슈인지, 설정 문제인지?
   - 재시도 로직이 이미 있는지?
2. **ci-failure 이슈 생성 정책**: P0-critical로 자동 생성되는데, deploy 실패가 진짜 P0인지 재검토
   - Deploy 실패 = P0 vs CI 테스트 실패 = P0 구분 필요?
   - 자동 재시도 후 최종 실패만 이슈화하는 방식 검토
3. **이슈 노이즈 감소**: 주 40건의 ci-failure 이슈가 실제 actionable 이슈를 묻히게 할 수 있음

### CI 현황 (양호)

| 결과 | 건수 |
|------|------|
| success | 35 |
| skipped | 11 |
| cancelled | 2 |
| failure | 2 |

핵심 CI는 안정적이며, 문제는 배포 파이프라인에 국한됨.
