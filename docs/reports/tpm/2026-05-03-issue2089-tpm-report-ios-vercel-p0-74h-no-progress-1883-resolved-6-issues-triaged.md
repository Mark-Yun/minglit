---
source_url: https://github.com/Mark-Yun/minglit/issues/2089
captured_at: 2026-05-03
issue_number: 2089
state: open
labels: [report-exec]
author: Mark-Yun
title: "⚠️ TPM Report — 2026-05-03: iOS+Vercel P0 누적 74h+ 무진전, #1883 해소, 미아 이슈 6건 트리아지"
---

# ⚠️ TPM Report — 2026-05-03: iOS+Vercel P0 누적 74h+ 무진전, #1883 해소, 미아 이슈 6건 트리아지

> Issue #2089 · open · created 2026-05-03 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2089

## Body

Scheduler: tpm-exec-report-claude-subagents

## Headline

- **#1883 Pixel 7a 해소** — Mark가 어제(05-03) 단말 재연결 + Flutter SDK 3.41.9 PATH fix(worker-runtime#d1c328c6) → close. 어제 리포트의 P0 4건 중 1건 진전.
- **iOS Deploy 양쪽 + Vercel Deploy는 24h 추가 무진전** — #2049 (~74h), #2061 (~66h), #1917 (~6일). 어제 리포트(#2083)에 코멘트 0건. Apple 자격증명 / Vercel 환경변수 의심 여전.
- **신규 이슈 0건 (2026-05-03)** — 새 백로그 유입 없음.
- **이번 사이클 트리아지 6건**: 미아 이슈(`needs-*` 미부여) 6개 모두 라우팅 라벨 부여 → 백로그 0.
- 메인 CI on dev 견고 — 모든 hourly job(Tick Simulator x2, DB Invariant Monitor) 100% success.

## 1. 사람 판단 필요 사항 (반복 escalate)

### A. iOS Deploy 양쪽 P0 — 74h+ / 66h+ 누적 (어제 +24h)

| 이슈 | 워크플로 | 첫 발생 | 누적 | 최근 fail |
|------|----------|---------|------|-----------|
| #2049 | iOS User App Deploy | 2026-04-29 11:34Z | ~74h | 2026-05-02 10:42 |
| #2061 | iOS Partner App Deploy | 2026-04-30 11:32Z | ~66h | 2026-05-02 10:43 |

- 양쪽 동시 실패 + 코드 회귀 가능성 낮음 → **Apple 자격증명 만료** 의심 지속 (Apple Developer 계정 / 인증서 / 프로비저닝 / App Store Connect API key / Fastlane Match)
- swe 자체 해결 불가 — Mark의 Apple Developer 계정 직접 점검 필요
- 이번 사이클 액션: 두 이슈에 `report-exec` 라벨 부여 (이전엔 `ci-failure` + `P0-critical`만 있어 라우팅 누락)

### B. Vercel Deploy P0 — ~6일 누적 (#1917)

- 오늘 24h 동안 cron 4회 실행 모두 failure (총 100%)
- 어제까지 10/10 failure → 추세 동일. 매 cron마다 동일 실패
- 자체 점검 미실시 → 환경변수 / Vercel 토큰 / 빌드 명령어 회귀 의심
- swe 해결 불가 가능성 — Mark가 Vercel 대시보드 또는 빌드 로그 직접 확인 필요

### C. runtime-qa 디스크 공간 부족 (#2075) — 신규 escalate

- 2026-05-01 23:50 runtime-qa-cuj-user-gemini 보고
- `~/.gradle/caches` 18G 점유, 가용 500MiB ~ 3.8GiB → 빌드 중 `No space left on device`
- 이번 사이클 액션: `report-exec` 라벨 + 매뉴얼 명령어 코멘트 추가 (Gradle 캐시 정리)

## 2. 이번 사이클 트리아지 (6건)

| 이슈 | 제목 | 부여 라벨 | 근거 |
|------|------|-----------|------|
| #2086 | [deps-fix] PR #2081 file_picker API 깨짐 | `needs-swe` + `bug` + `P1-high` | dependabot 파이프라인 차단, 본문에 구체적 수정 가이드 포함 |
| #2074 | [QA] P-S11 계좌 관리 → 입점 신청 현황 잘못 라우팅 | `needs-swe` + `P1-high` | PARTNER 상태 유저에게 온보딩 화면 — 파트너 앱 핵심 기능 버그 |
| #2076 | [QA] CUJ-U03 영수증 버튼 미표시 (0원) | `needs-swe` + `P2-medium` | 의도된 동작인지 swe 검증 필요 |
| #2075 | [HARD BLOCK] No space left on device | `report-exec` | swe 해결 불가, Mark 매뉴얼 |
| #2049 | iOS Deploy User failed | `report-exec` 추가 | 기존 ci-failure만 있어 라우팅 누락이었음 |
| #2061 | iOS Deploy Partner failed | `report-exec` 추가 | 동일 |

## 3. 메트릭 (24h, 2026-05-02 ~ 03 09:00 KST 기준)

| 지표 | 수치 | 추세 |
|------|------|------|
| 신규 이슈 | 0 | 어제 0 → 오늘 0 (정체) |
| 메인 CI on dev | hourly 24/24 | 견고 (Tick x2, DB Invariant) |
| Vercel Deploy | 0/4 (100% 실패) | 어제 0/10 → 오늘 0/4 (cron freq 감소) |
| iOS Deploy User | 0/1 fail | 동일 (#2049, 3일째) |
| iOS Deploy Partner | 0/1 fail | 동일 (#2061) |
| review-presence | 5 success / 8 skipped | 어제 53% "실패" → 정정. skipped는 PR 코멘트 트리거 후 리뷰 없을 때 normal |
| 머지된 PR | 0 | 어제 8 → 오늘 0 (Mark 활동 일시 정지) |
| Hard block 정리 | 12건 close | 어제 누적 hard block 일괄 정리 (#1883, #2064, #2087 등) |

## 4. report-exec 백로그 누적

다음 사이클에 Mark에게 답변/조치 요청. 9건 누적:

| 이슈 | 생성일 | 종류 | 상태 |
|------|--------|------|------|
| #1338 | 04-12 | test 추가 enhancement (P2) | 11일째 — 라벨 재평가 필요 |
| #1768 | 04-23 | TPM Report — review-presence | 10일째 |
| #1774 | 04-23 | PM Report | 10일째 |
| #1917 | 04-27 | Vercel Deploy P0 | 6일째 |
| #2042 | 04-28 | TPM Report — runtime-qa ADB | 5일째 |
| #2046 | 04-29 | TPM Report — audit 정리 + dependabot | 4일째 |
| #2059 | 04-30 | PM Report — 정리 웨이브 + MDS | 3일째 |
| #2070 | 05-01 | TPM Report — iOS + runtime-qa SD | 2일째 |
| #2083 | 05-02 | TPM Report — P0 24h 무진전 + submodule | 1일째 |

#1338은 P2 test enhancement로 report-exec 부적절 — 다음 사이클에 라벨 정리 검토.

## 5. 결론

- **iOS Deploy 양쪽 + Vercel Deploy P0는 Mark의 직접 액션 없이 해소 불가** — 각각 74h+, 66h+, 6일+ 누적
- **#1883 해소는 진전 신호** — 다른 P0도 같은 cycle로 처리 가능
- **트리아지 6건 완료** → swe / Mark 라우팅 분리됨, 백로그 깨끗
- 코드 사이드 / dev 브랜치는 견고 (hourly 24/24)

**Mark에게 우선 요청 (어제와 동일, 추가 +1)**:
1. **Apple Developer 계정 점검** — iOS Deploy 양쪽 (#2049, #2061)
2. **Vercel 빌드 로그 점검** — Vercel Deploy (#1917)
3. **Gradle 캐시 정리** — runtime-qa 디스크 (#2075)
4. (어제 잔존) 워커 셋업 스크립트에 `git submodule update --init --recursive` 추가
