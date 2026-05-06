---
source_url: https://github.com/Mark-Yun/minglit/issues/2263
captured_at: 2026-05-06
issue_number: 2263
state: open
labels: [report-exec]
author: Mark-Yun
title: "⚠️ TPM Report — 2026-05-06: 35 PR 머지 burndown + Audit Legal P1 신규 + 인프라 P0 6일 연속"
---

# ⚠️ TPM Report — 2026-05-06: 35 PR 머지 burndown + Audit Legal P1 신규 + 인프라 P0 6일 연속

> Issue #2263 · open · created 2026-05-06 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2263

## Body

Scheduler: tpm-exec-report-claude-subagents

## Headline

- **거대한 burndown 사이클** — 24h 동안 PR 35건 머지(어제 14건 → 2.5×) + 이슈 28건 close. 실 자체 P1 file_picker(#2086) + runtime-qa 디스크(#2075) 2건 hard block 해소.
- **Legal Audit P1 신규** — `user_profiles` 제3자 제공 PIPA §17 위반(#2250) — column-level RLS 누락 + UI 실명/성별/full DOB 노출. `needs-arch` 라우팅 + 검증 완료(코드 100% 재현). #1141 PM 결정 회귀 + 컴플라이언스 이중 위반.
- **mds_core/v2 implementation 파이프라인 가동** — PartnerHomePage v2(#2219) + EventApplicationWizard v2(#2211) + PartyListPage v2(#2253) + EventMatching v2.0(#2206) 등 spec→client 일괄 구현 PR 머지 진행.
- **인프라 P0 무진전 (6일 연속)** — Vercel 9d 100% 실패(8/8 cron), iOS x2 7d/6d. Mark의 인프라 액션 0건 누적.
- **신규 Mark backlog 3건** — #2255(P1 spec 자기모순, PR #2243 머지차단), #2261(P2 spec 일관성), #2252(P1 좀비 flutter PID 70137 kill 필요).

## 1. 사람 판단 필요 사항 (반복 escalate — 6일 연속, 새 항목 +3)

### A. 인프라 P0 (변동 없음 / 누적 증가)

| 이슈 | 워크플로 | 첫 발생 | 누적 | 24h fail |
|------|----------|---------|------|----------|
| #1917 | Deploy to Vercel | 2026-04-27 | **9일** | 8/8 (100%) |
| #2049 | iOS User App Deploy | 2026-04-29 | **7일** | 1/1 |
| #2061 | iOS Partner App Deploy | 2026-04-30 | **6일** | 1/1 |

- Vercel: 76개 코멘트 누적, 매 cron 실패 통지만 쌓임. 빌드 로그 직접 확인 필요.
- iOS 양쪽: 동시 만료 패턴 → Apple Developer 인증서 / 프로비저닝 / Match 점검.

### B. 신규 Mark 액션 3건 (오늘 트리아지)

| 이슈 | 종류 | 우선순위 | 영향 |
|------|------|----------|------|
| #2255 | spec self-contradiction (`party_list_page.html:1577`) | **P1** | PR #2243 CHANGES_REQUESTED → 머지 차단 |
| #2261 | spec 표현 일관성 (`event_application_manage_page.html:437`) | P2 | 시각 contract 일관성 |
| #2252 | macOS 좀비 flutter PID 70137 (99.4% CPU, 46d) | **P1** | 디스크 재고갈 inevitable (현 가용 2.2G/228G) |

### C. report-exec 백로그 누적 (10건, 정리 후)

어제 16건 → 오늘 10건. 어제 #2148(TPM-04), #2076(receipt) 등 close되며 정리. 그러나 본 사이클 신규 1건(#2242 Metabase) + 어제 1건(#2222/#2221/#2220 spec 일괄) 추가.

| 이슈 | 종류 | 누적일 |
|------|------|--------|
| #1917 | Vercel P0 | 9일 |
| #2049 | iOS User P0 | 7일 |
| #2061 | iOS Partner P0 | 6일 |
| #2097 | Spec 후속 | 3일 |
| #2177 | TPM Report 05-05 | 1일 |
| #2220, #2221, #2222 | docs(mds): TBD spec 일괄 | 1일 |
| #2242 | PR #2210 Metabase main 검증 | 1일 |

## 2. 24h 진행 (2026-05-05 → 05-06 KST)

### 2.1 close 28건 — 어제 19건 → 47% 증가

핵심:
- **인프라/픽스 P1 hard block 2건 해소**: #2086(file_picker FilePicker.platform), #2075(gradle disk).
- **mds_core 컴포넌트 신설 4건**: MinglitDDayChip(#2198), MinglitHelpSheet(#2199), MinglitTimeline(#2096), MinglitCapacityBar(#2111).
- **client v2 구현 4건**: PartnerHomePage v2(#2219), EventApplicationWizard v2(#2211), EventMatching v2(#2206), PartyListPage v2(#2253 PR 진행 중).
- **Backend 4건**: get_entry_group RPC(#2117), Ticket→EntryGroup 1:1(#2102), bulk review EF(#2101), match_results_viewed_at(#2124).
- **CI/리포트 자동 파일링** mds-change 9건 close (#2233/#2230/#2229/#2225/#2238/#2237/#2213/#2208/#2105/#2113/#2115/#2100).

### 2.2 PR 머지 35건 — 어제 14건 → 2.5×

전부 Mark-Yun 작성자(squash 머지 author). 분포 (오픈+머지된 직전 50건 기준):
- mds_core 컴포넌트 + spec: ~10건
- client v2 implementation: ~6건
- Backend / RPC / migration: ~5건
- 리포트 동기화 (TPM/runtime-qa): ~7건
- Bug fix: ~5건
- 기타: ~2건

### 2.3 신규 트리아지 (41건 신규)

- 라벨 갭 4건 트리아지 (#2255 P1, #2261 P2, #2252 P1 → report-exec; #2260 dup of #2255 close).
- 자동 파일링 mds-change 다수가 자동 라벨 부여(`P2-medium`,`needs-swe`)되어 진입 시점에 라우팅 완료.
- 신규 P0 1건: #2235 `Deploy Supabase Migrations failed on dev` — 24h 내 close (transient).
- 신규 audit-report 1건: #2250 (Legal user_profiles overshare) → `needs-arch`.

## 3. 메트릭 (24h, 2026-05-05 ~ 06 KST)

| 지표 | 수치 | 추세 |
|------|------|------|
| 신규 이슈 | 41건 | ↑↑ (어제 2건 → 폭증, mds 자동 파일링이 큰 비중) |
| close된 이슈 | 28건 | ↑ (어제 19건 → +47%) |
| 머지된 PR | 35건 | ↑↑ (어제 14건 → +150%) |
| 미아 이슈 (no needs-*) | 4건 → 0건 | 트리아지로 해소 |
| Vercel Deploy 24h | 0/8 | ⚠ 9일째 100% 실패 |
| iOS Deploy User | 0/1 | ⚠ 7일째 |
| iOS Deploy Partner | 0/1 | ⚠ 6일째 |
| Supabase Migrations Deploy | 2/2 | ✅ 안정 (vault fix 후) |
| review-presence | 28/30 | ✅ 견고 |
| CI Unit/Widget 24h | 5/11 success, 6 fail/cancel | ⚠ 분기 PR 개발 중 transient |
| audit 처리 | 2건 (1 close, 1 routing) | 안정 |

## 4. 진행 위험 신호

### 4.1 Mark의 인프라 액션 6일 연속 0건

- 워커가 자체 해결 가능한 항목은 빠르게 처리되고 있음 (file_picker, gradle, Supabase deploy).
- 오직 **Mark만 처리 가능한 항목**(Apple cert, Vercel dashboard, macOS process kill, mds spec)이 누적 중.
- 누적 backlog: P0 인프라 3건(9d/7d/6d) + P1 spec/process 2건(신규).
- **출시까지 ~2개월** — Vercel 9일 다운은 마케팅 페이지 신뢰성 직접 영향.

### 4.2 PR 머지 35건 burndown은 좋으나 backlog 신규 41건

- 신규 41건 중 대다수는 mds_core 자동 파일링(#2229, #2230, #2233, #2238 등)으로 신규 작업이 아닌 **추적용 파일링**.
- 실제 신규 액션 항목: ~15건 정도. 그 중 P1 1건(#2250 legal audit), P0 1건(#2235 transient close), 나머지 P2/P3.
- 작업 페이스는 출시 가능 수준. 단 mds-change 자동 파일링이 backlog 시그널을 노이즈로 만들고 있음 → **TBD: mds-change 자동 close 룰 검토** (단순 문서 변경은 자동 close).

### 4.3 인증/RLS column-level 정책 부재 — 일반 패턴 가능성

- #2250 audit가 `Partners can read applicant profiles` 정책에서 column 미제한을 지적.
- 다른 RLS 정책에도 동일 패턴(전체 row read)이 있을 수 있음 → security-reviewer 워커가 audit 수행 권장.
- 현 사이클은 #2250만 단독 라우팅. 패턴 audit는 별도 트리거 필요.

## 5. 결론 + Mark 우선 액션 (6일 연속, +3)

### Mark 우선순위 (시급도 순)

1. **`kill 70137`** — #2252 — 1초. 디스크 재고갈 차단. 가장 빠른 win.
2. **Vercel 빌드 로그 점검** — #1917 — **9일 / 100% 실패율**. 가장 시급.
3. **Apple Developer 점검** — iOS x2 #2049/#2061 — **7일/6일**.
4. **spec interaction table 정정** — #2255 — PR #2243 머지 차단 해제.
5. (선택) **spec AppBar actions 일관성** — #2261 — P2.

### 운영 사이드 강한 진전

- 워커 자율 픽스 사이클(file_picker, gradle, Supabase vault, mds_core 신설, client v2)이 일관되게 작동. 어제 14 PR → 오늘 35 PR.
- Legal audit가 빠르게 catch + 코드 검증 완료 + arch routing — audit 파이프라인 정상.

### 요청 — security 패턴 audit

- #2250 의 RLS column-level 부재가 다른 정책에도 적용되는지 별도 audit 트리거 권장 (나의 권한 아님 — `report-exec`로 위 우선순위에 포함하지 않음 / arch 사이클에서 자체 판단 시 처리).
