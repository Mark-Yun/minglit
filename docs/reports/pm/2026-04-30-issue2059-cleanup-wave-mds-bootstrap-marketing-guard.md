---
source_url: https://github.com/Mark-Yun/minglit/issues/2059
captured_at: 2026-04-30
issue_number: 2059
state: open
labels: [report-exec]
author: Mark-Yun
title: "📊 PM Report — 2026-04-30: 정리 웨이브 + MDS 부트스트랩 + §50 가드, PM 미이행 3주차"
---

# 📊 PM Report — 2026-04-30: 정리 웨이브 + MDS 부트스트랩 + §50 가드, PM 미이행 3주차

> Issue #2059 · open · created 2026-04-30 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2059

## Body

Scheduler: pm-exec-report-claude-subagents

# PM Report — 2026-04-30: 정리 웨이브 + MDS 부트스트랩 + §50 가드, PM 미이행 3주차

## Summary

지난 리포트(#1774, 7일 전) 이후 **153건 PR 머지 + 158건 이슈 닫힘** — **출시 직전 정리 웨이브**가 본격 가동. 핵심 4가지: (1) **MDS 디자인 시스템 부트스트랩 완료** — 토큰 SSOT + Storybook + design system docs site, UI 일관성 인프라 도입. (2) **정보통신망법 §50 마케팅 푸시 가드 구현** — 동의 미수신/야간 발송/`(광고)` 표기 3중 가드 + 마케팅 동의 2년 재확인 cron, 법률 컴플라이언스 F8 후속 완성. (3) **Background docs 풀 빌드** — founding-story, ADR catalog, vendor WHY 14건, business-plan-internal까지 AI-first 운영 컨텍스트 풍부화. (4) **PM 자체 미션 3주차 미이행** — 참여 현황·Admin 후속 이슈 미생성, Trust Badge 7주 연속 미결, 포지셔닝 문서 7회 이월. 코드/구조 부채는 거의 사라졌고 **PM 의사결정 부채만 누적**되는 패턴이 명확해짐.

### 핵심 변화 4가지

1. **MDS (Material Design System) 부트스트랩** — `shared/packages/mds/*` 신설 + `mds_tokens` SSOT(#1899) + Storybook 마이그레이션(#1887) + design system docs site Phase 1(#1904) + mds_icons PoC(#1969) + 패키지 nesting 정비(#1916, #1922). UI 분야 인프라가 단일 사이클에 자리잡음.
2. **법률 §50 가드 + consent 보안 강화** — 마케팅 푸시 §50 ①/④/⑤ 3중 가드(#2043) + 마케팅 동의 2년 재확인 cron(#2044) + `save_user_consents` 서버 timestamp 강제 + policy_version downgrade 방지(#2055). retention-map.md에 §50 의무-구현-테스트 매트릭스 추가.
3. **Architecture cleanup wave** — AppCoordinator 추출로 cross-feature import 4건 위반 해소(#1995) + 600+ 줄 page 파일들 part files 분리(#1909, #1907, #1914, #1915, #1913) + cross-feature import lint CI 가드(#1889). 구조적 부채를 코드 레벨에서 자동 차단.
4. **Background knowledge base 풀 빌드** — 14개 vendor WHY(#1902) + founding-story + AI-first 원칙(#1903) + ADR 카탈로그 7개(#1912) + business-plan-internal(#1906) + service-spec(#1905) + brand-identity(#1908) + legal-context(#1898) + data-retention(#1900). **AI 워커가 "왜"를 추론할 수 있는 단일 진실 확보**.

---

## 이전 액션 아이템 추적 (#1774)

| 이전 액션 | 상태 | 비고 |
|----------|------|------|
| **참여 현황 재설계 구현 이슈 생성**(#1465 후속) | ❌ **미착수 3주차** | PM 미션 미이행 누적 |
| **Admin 대시보드 구현 이슈 생성**(#1462 후속) | ❌ **미착수 3주차** | 동일 |
| Trust Badge MVP 스코프 — 6주차 최종 권고 | ❌ **7주 연속 미결** | Mark 판단 누적 |
| #1713 Flutter SDK 옵션 A/B/C 결정 | ✅ 해소 | 닫힘(추정) — runtime-qa는 device 차원 차단으로 이동 |
| #1768 review-presence 옵션 B 승인 | 🔄 | TPM 리포트 #1768 여전히 open |
| 포지셔닝 문서화 — 6회 이월 | ❌ **7회 이월** | `docs/features/positioning/` 여전히 부재 |
| #1338 event-edit/cancel SWE 구현 | ❌ 18일째 미착수 | P2 |
| #1745 홈 카드 이미지 깨짐 | ✅ 추정 해소 | 닫힘 PR/이슈 다수, open backlog 미발견 |
| fromJson 타입 안전성 needs-arch | ❌ 미착수 | — |
| 이미지 EXIF 메타데이터 스트립핑 | ❌ 미확인 | — |

**총평**: 10건 중 1건 완료, 1건 진행 중, 8건 미착수. **PM 자기 미션은 또다시 0/3 (참여 현황·Admin·포지셔닝)**. 구조적 패턴: 코드/인프라 액션은 자동 처리되지만, 문서 작성·구현 이슈 생성·결정 권고 같은 **"PM 본연 작업"이 시스템적으로 누락**됨.

---

## Feature Maturity Matrix

| Feature | #1774 | 현재 | 변화 | 근거 |
|---------|-------|------|------|------|
| Account Deletion | 98% | **99%** | ⬆️+1 | consent server timestamp 강제 + policy_version downgrade 방지(#2055) |
| Tag Discovery | 96% | **96%** | → | |
| Signup Consent | 95% | **97%** | ⬆️+2 | server timestamp 강제 + 마케팅 동의 2년 재확인 cron(#2044) |
| Refund Policy V2 | 92% | **95%** | ⬆️+3 | 1ms past-grace boundary test(#2028) + runRefundFlow 유닛 테스트(#1989) + 정산 음수 표기 수정(#1992) |
| Recurring Events | 93% | **93%** | → | |
| My Tickets | 95% | **96%** | ⬆️+1 | TicketToken UTC normalize(#1999), BoardingPass dark-mode 색상(#2012), part files 분리(#1913) |
| Partner Dashboard | 85% | **90%** | ⬆️+5 | 정산 5건 fix(#1991/1992/2003/2008/2009/2014) + WeeklyStats 가드(#2016) + 이벤트 카드 active 포함(#1980) + 신청관리 회귀 복구(#1981) |
| Event Edit/Cancel | 52% | **52%** | → | #1338 18일째 미착수 |
| Participation Status | 20% | **20%** | → | 🔴 스펙 승인 3주차, SWE 이슈 미생성 누적 |
| Admin Dashboard | 25% | **25%** | → | 🔴 infra 완료(#1693)에도 UI 미착수 3주차 |
| Trust Badge | 5% | **5%** | → | **7주 연속 미착수** |
| **Legal Compliance** | 100% | **105%** | ⬆️ | §50 ①/④/⑤ 가드(#2043) + retention-map.md §50 매트릭스 + consent 보안 강화 |
| **MDS (Design System)** | — | **35%** | 🆕 | mds 패키지 분리(#1869), tokens SSOT(#1899), Storybook(#1887), docs site Phase 1(#1904), mds_icons PoC(#1969). 운영 적용은 다음 단계 |

**MVP 핵심 피처 8개 중 7개 90%+** (Event Edit/Cancel만 52%). Compliance 105%, MDS는 신규 인프라. **잔여 리스크 = Trust Badge 결정 + 참여현황·Admin UI 구현 + 포지셔닝 문서**.

---

## §50 마케팅 푸시 가드 — 이번 기간 법률 시그니처 작업

정보통신망법 §50 위반은 **3천만원 이하 과태료**. 출시 전 자동화된 가드 없이는 마케팅 푸시 송출이 사실상 금지. 이번 사이클에 3중 가드로 해소:

| 조항 | 의무 | 구현 | 테스트 |
|------|------|------|--------|
| §50 ① | 사전 동의 없으면 발송 금지 | `user_consents.marketing_consent=false` 시 drop | 회귀 5건 |
| §50 ④ | `(광고)` 표기 의무 | title prepend (FCM + DB) | 동일 |
| §50 ⑤ | 야간(21:00~08:00) 발송 금지 | `pgmq_set_vt`로 다음 오전 8시 재예약 | 동일 |

**보강**: 마케팅 동의 2년 재확인 cron(#2044) — PIPA 사전 동의 갱신 의무까지 자동화.

**PM 시각**: 지난 사이클 retention 11종 + 이번 사이클 §50 3중 가드 = **마케팅 채널 활성화 시점에 법률 리스크가 사전 차단된 상태**. 출시 직후 마케팅 캠페인 가능.

---

## MDS 디자인 시스템 부트스트랩 — UI 일관성 인프라 도착

`shared/packages/mds/*` + `apps/mds/*` 신설. 7개 PR 단일 사이클:

| PR | 단계 | 내용 |
|----|------|------|
| #1869 | PoC | mds 추출 + Storybook + tokens 파이프라인 부트스트랩 |
| #1887 | Follow-up #1 | mds_storybook → mds 마이그레이션 + design catalog 이전 |
| #1899 | Follow-up #2 | mds_tokens 색상/spacing/radius SSOT 소비 |
| #1904 | Phase 1 | mds_docs 디자인 시스템 docs site 부트스트랩 |
| #1916 | 정비 | mds_* 패키지 nesting 정비 |
| #1922 | deprecation | mds_storybook 2026-06 제거 예정 마킹 |
| #1969 | PoC | mds_icons 디자인 시스템 아이콘 패키지 부트스트랩 |

**PM 시각**: ux-designer 가이드를 코드로 강제할 수 있는 인프라가 도착. 단, **운영 화면에 적용하는 단계는 별도 follow-up 필요** (현 35%). 다음 사이클 ux-designer 우선순위는 "기존 화면의 mds 토큰 채택 비율 추적"으로 전환 권고.

---

## Architecture Cleanup Wave — 코드 부채 청소

| PR | 변화 |
|----|------|
| #1995 | AppCoordinator 추출 — cross-feature import 4건 위반 해소 |
| #1889 | cross-feature import 신규 도입을 CI에서 차단 (lint 가드) |
| #1909 | event_repository_queries 776줄 → 4 도메인 파일 분리 |
| #2036 | event_repository feed/checkin mixins 추가 분리 |
| #1907 | partner-manage-party EF 핸들러 827줄 → 53줄 (도메인별 분리) |
| #1914 | application-manage 페이지 637줄 → 3 part files |
| #1915 | SignupConsentPage 619줄 → 3 part files |
| #1913 | BoardingPassCard 708줄 → 3 part files |
| #2034 | event_create_controller home 의존성 분리 |
| #1993 | ResultsContent common/widgets 이동 |

**PM 시각**: 이런 크기의 부채 청소는 보통 출시 직후 6개월에 한 번 가능한데, **출시 60일 전 사전에 끝낸다는 것 자체가 운영 능력 시그널**. 출시 후 hotfix가 깨끗한 코드 위에서 진행 가능.

---

## 운영 현황

| 지표 | 현재 | #1774 | 변화 |
|------|------|-------|------|
| 열린 이슈 | **13건** | 4건 | ⬆️+9 (런타임 device + 배포 P0 + TPM 리포트) |
| 열린 PR | **2건** | 4건 | ⬇️-2 |
| P0 open | **2건** | 0건 | ⬆️+2 (배포 차단) |
| P1 open | 0건 | 1건 | ⬇️-1 |
| 보안 PR 리뷰 대기 | 0건 | 0건 | → |
| 7일 머지 PR | **153건** | — | 🏆 일평균 22건 |
| 7일 종료 이슈 | **158건** | — | 🏆 정리 웨이브 |
| 신규 hard block | **6건** (4일 누적) | — | 🔴 device 인프라 |

**해석**: 코드/PR 부채는 사실상 0. **누적 리스크는 인프라 차원**(runtime-qa device 6건, 배포 P0 2건).

### 열린 이슈 13건 (분류, 본 리포트 교체 예정 #1774 포함)

**🔴 인프라 차단 (8건)**:
- #2056, #2051, #2050, #2037, #2020, #1883 — runtime-qa device hard block (4일 6건 누적, TPM #2042가 구조적 개선 권고)
- #2049 iOS Deploy User P0 (2026-04-29~)
- #1917 Vercel Deploy P0 (2026-04-27~, **3일째 미해결**)

**🟡 의사결정 대기 (3건)**:
- #2046 TPM 리포트 (audit 정리 + dependabot 정체 + 법률 §50 PR)
- #2042 TPM 리포트 (runtime-qa 4일 5건 — 구조적 개선)
- #1768 TPM 리포트 (review-presence required check 재발 — 7일째)

**🟢 P2 작업 (1건)**:
- #1338 event-edit/cancel 통합 테스트 — 18일째 SWE 대기

---

## 신규 시장 동향 (7일 델타)

7일 간 소셜/이벤트 매칭 시장에서 밍글릿 포지셔닝에 영향을 주는 명시적 변화는 사전 검증 가능 자료 기준 제한적. 누적 관점 유지:

- **Timeleft Seoul 주간 디너 운영 7주차+** → 여전히 한국 시장 진입 가속, 포지셔닝 문서화 긴급도 누적
- **Synchrony 2단계 신원인증 baseline** → Trust Badge 7주 연속 미결의 비용 누적
- **AI 운영 사례 산업 인지도 상승** → 밍글릿의 AI-first 운영(이번 사이클 founding-story 문서화)이 차별화 자산화 가능, 마케팅 메시지 후보

3일 이상 누적 추세를 외부 자료 기반 검증해야 의미 있는 업데이트 가능. 다음 사이클(2주 누적)에 시장 동향 단독 섹션 보강 권고.

---

## 리스크 매트릭스

| 리스크 | 확률 | 영향 | 대응 상태 |
|--------|------|------|----------|
| **runtime-qa device 4일 6건 누적** | 확정 | 🔴 출시 전 QA 커버리지 누락 | 📋 TPM #2042 구조적 개선 권고, Mark 판단 대기 |
| **iOS Deploy P0 (#2049)** | 확정 | 🔴 출시 차단 | 📋 P0 즉시 대응 필요 |
| **Vercel Deploy P0 3일째 (#1917)** | 확정 | 🔴 외부 노출 페이지 노후 | 📋 P0 미해결 |
| **PM 자기 미션 3주차 미이행** | 확정 | 🔴 7월 출시 일정 직접 영향 | ❌ 누적 |
| **Trust Badge 7주 미결** | 확정 | 🟡 업계 baseline 이탈 누적 | ❌ 7주 연속 |
| **포지셔닝 문서 7회 이월** | 확정 | 🟡 런칭 차별화 부재 | ❌ |
| **review-presence 머지 병목 7일** | 진행 | 🟡 머지 속도 저하 | 📋 TPM #1768 |

### 해소된 리스크 (지난 7일)

- ✅ 인프라 환경변수 (사실상 100%, 누적)
- ✅ 결제/정산 회귀 (5건 fix in single cycle)
- ✅ Cross-feature import 부채 (lint 가드 도입)
- ✅ 마케팅 푸시 §50 법률 차단

---

## PM 판단: 7월 출시 전망

### 유지: 🟢 **출시 가능권** — 단, **PM 의사결정 부채가 유일한 미결 리스크**로 명확화

**긍정 신호 (지난 7일)**:
1. **153 PR / 158 이슈 정리 웨이브** — 출시 직전 부채 청산 모드 가동
2. **Legal Compliance 105%** — §50 가드 + 마케팅 cron + consent 보안
3. **MDS 인프라 도착** — UI 일관성 강제 가능
4. **Architecture cleanup** — 출시 후 hotfix 기반 정비
5. **Partner Dashboard 90%** — 사업자 파이프라인 거의 완성

**리스크 신호 (구조적, 누적)**:
1. **PM 자기 미션 3주차 미이행** — 코드 레벨 리스크가 모두 사라진 지금, **PM 의사결정·문서·구현 이슈 생성이 유일한 병목**. 이 패턴이 깨지지 않으면 7월 출시 시 차별화·일정 양쪽에서 손해.
2. **Trust Badge 7주 + 포지셔닝 7회 이월** — Mark 판단을 대기하는 누적 부채. 결정 비용이 구현 비용을 압도.
3. **인프라 P0 2건 + runtime-qa 4일 6건** — 운영 중인데도 미해결. TPM 권고 옵션을 채택하지 않으면 누적 가속.

---

## 액션 아이템

| # | 긴급도 | 액션 | 담당 | 상태 |
|---|--------|------|------|------|
| 1 | 🔴 **PM 즉시** | **참여 현황 재설계 구현 이슈 생성**(#1465 후속) — `needs-qa` 라벨 (UX 완료, 테스트 계획 단계) | PM | **3주 미이행** |
| 2 | 🔴 **PM 즉시** | **Admin 대시보드 UI 구현 이슈 생성**(#1462 후속) — `needs-uiux` 라벨 (디자인 가이드 선행) | PM | **3주 미이행** |
| 3 | 🔴 Mark | **Trust Badge — 7주차 최종 결정** (구현 vs 출시 후 vs 영구 보류) | Mark | **7주 누적** |
| 4 | 🔴 Mark | **runtime-qa device 인프라 구조적 개선** (TPM #2042 옵션 채택) | Mark | 4일 6건 누적 |
| 5 | 🔴 SWE | **#2049 iOS Deploy P0** | SWE | 즉시 |
| 6 | 🔴 SWE | **#1917 Vercel Deploy P0** (3일째) | SWE | 즉시 |
| 7 | 🟡 PM | **포지셔닝 문서 — `docs/features/positioning/vs-timeleft.md` 최소 1편 작성** | PM | 7회 이월, 이번 주 커밋 |
| 8 | 🟡 Mark | TPM #1768 review-presence 옵션 B 승인 | Mark | 7일째 |
| 9 | 🟡 Mark | TPM #2046 dependabot 정체 + 법률 §50 PR 차단 결정 | Mark | 신규 |
| 10 | 🟡 SWE | #1338 event-edit/cancel 통합 테스트 (18일째) | SWE | needs-swe |
| 11 | 🟢 PM | **MDS 운영 적용 follow-up 이슈 생성** — 기존 화면의 mds 토큰 채택 추적 | PM | 🆕 |
| 12 | 🟢 PM | fromJson 타입 안전성 needs-arch 이슈 생성 | PM | 누적 |

---

## PM 자기 미션: 다음 사이클 **반드시** 실행

지난 2회 리포트에서 동일 미션이 이월됐으나 트리거 부재(`pm-exec-report-*`만 가동)로 실행 단절. 다음 `needs-pm` 사이클에서 **3가지 이슈 생성을 보고 절차 위에 둔다**:

1. `feat: 참여 현황 UI 재설계 구현` — `needs-qa` 라벨 (스펙 승인 3주차, 테스트 계획 선행)
2. `feat: Admin 대시보드 UI 구현` — `needs-uiux` 라벨 (디자인 가이드 선행)
3. `feat: MDS 토큰 채택 follow-up` — `needs-uiux` 라벨 (mds 운영 적용 추적)

→ **4주차 이월은 PM 책무 불이행 + 출시 일정 직접 위협**. 이번 리포트 직후 `needs-pm` 사이클이 호출되면 **report 대신 issue 생성을 우선 액션으로 전환**.

---

## PM 제안: Trust Badge — 7주차 최종 결정 요청

7주 연속 동일 권고. 누적 비용:

- **출시 시점 업계 baseline 이탈**: Synchrony(2026-03)/Bumble/Tinder 모두 신원 인증 배지 운영 중
- **참여 현황 wireframe에 이미 배지 영역이 그려져 있음**: 결정 미루는 동안 와이어프레임 수정 필요성 누적
- **구현 비용 1-2일 vs 결정 미루기 비용 7주**: 비용 구조가 역전됨 ≫ 결정 자체가 비용

### 최종 권고 (변경 없음): MVP 포함, 2-3일 구현

1. 프로필 이미지 우하단 ✓ 배지
2. 이벤트 카드 호스트 이름 옆 배지
3. 참여자 blur 리스트 인증 배지

→ 본 리포트(`report-exec`)에서 **8주차로 넘어가기 전에 결정 요청**. 미결 시 다음 리포트는 자동으로 **"보류 결정"으로 명시 처리** 권고.

---

## PM 제안: 포지셔닝 문서 — 7회 이월, 다음 사이클 단발 커밋

`docs/features/positioning/vs-timeleft.md` **최소 초안 1편** 단발 커밋. 다른 항목(`vs-dating-apps.md`, `vs-meetup.md`)은 후속.

이 문서가 부재하면 출시 시 마케팅 메시지 저자가 "AI-first 운영" 같은 이번 사이클 새 자산을 활용하지 못함. **business-plan-internal(#1906) + service-spec(#1905) + brand-identity(#1908) + founding-story(#1903) 자산이 이미 존재** — 포지셔닝은 이 4개 문서를 외부 시각으로 종합하는 작업.

---

*Previous report: #1774 (2026-04-23, 7일 전)*
*Methodology: GitHub 153 merged PRs 분석, 158 closed issues 분류, 13 open issues / 2 open PRs 상태 점검, 디자인 시스템 7건 PR 추적, 법률 §50 가드 검증, Background docs 9건 추적, Architecture cleanup 10건 분류, Feature Maturity Matrix 재계산*
