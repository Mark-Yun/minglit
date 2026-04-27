---
source_url: https://github.com/Mark-Yun/minglit/issues/1410
captured_at: 2026-04-13
issue_number: 1410
state: closed
labels: [report-exec]
author: Mark-Yun
title: "📊 PM Report — 2026-04-13: QA 버그 전수 해소 + 디자인 시스템 고속 정비 + 결제 플로우 신규 차단"
---

# 📊 PM Report — 2026-04-13: QA 버그 전수 해소 + 디자인 시스템 고속 정비 + 결제 플로우 신규 차단

> Issue #1410 · closed · created 2026-04-13T08:04:55Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1410

## Body

Scheduler: pm-exec-report-claude-subagents

# PM Report — 2026-04-13: QA 버그 전수 해소 + 디자인 시스템 고속 정비 + 결제 플로우 신규 차단 발견

## Summary

지난 리포트(#1229) 이후 3일간 **30건 PR 머지, 30건 이슈 종료**로 프로젝트 처리 속도가 사상 최고치를 기록했다. QA 세션에서 발견된 P0/P1 버그 5건이 **전수 해소**되었고, 디자인 시스템 표준화(다크모드, 칩 위젯, 로고 SVG 등)와 통합 테스트 커버리지 확대가 병행되었다. 단, Runtime QA에서 **결제하기 진입 시 Type Cast Error**(#1409)가 새로 발견되어 핵심 유저 플로우에 신규 차단이 생겼다.

### 핵심 변경 3가지

1. **QA 버그 전수 해소**: 이전 보고의 P0(#1222), P1(#1219, #1217, #1206, #1152) 5건 모두 종료. 열린 이슈 19건 → 5건으로 감소.
2. **디자인 시스템 고속 정비**: 다크모드 지원(#1399, #1395), 칩 위젯 표준화(#1405, #1403), 로고 SVG(#1401), 이미지 placeholder(#1406), 로그아웃 다이얼로그(#1402), semantic status colors(#1388) 등 8건 머지.
3. **결제 플로우 신규 차단**: #1409 — `type 'Null' is not a subtype of type 'Map<String, dynamic>'` 에러. 결제하기 버튼 탭 시 Red Screen. CUJ-U01(회원가입→결제→신청) 플로우 차단.

---

## 이전 액션 아이템 추적

| 이전(#1229) 액션 | 상태 |
|-----------------|------|
| #1222 P0 Supabase DNS 해소 | ✅ 종료 |
| #1217 P1 파트너 신청관리 빈 화면 | ✅ 종료 |
| #1206 P1 QR 입장 에러 | ✅ 종료 |
| #1152 P1 party_tags 버그 (96h+ 미착수) | ✅ 종료 (04-10) |
| #1219 P1 정원 초과 | ✅ 종료 |
| QA 세션 정례화 제안 | 🔄 실질적으로 Runtime QA가 자동화 실행 중 |
| Trust Badge MVP 스코프 축소 검토 | ❌ 미조치 — 여전히 5% |

**총평**: 7개 액션 중 5개 완료. 처리 속도가 발견 속도를 앞지름 — 긍정적 전환점.

---

## Feature Maturity Matrix (교정)

| Feature | 이전(#1229) | 교정 | 변화 | 근거 |
|---------|------------|------|------|------|
| Account Deletion | 97% | **97%** | → | 변동 없음 |
| Tag Discovery | 92% | **96%** | ⬆️+4 | #1152(P1) 해소, #1212 Now Bar 해소 |
| Signup Consent | 90% | **90%** | → | 변동 없음 |
| Refund Policy V2 | 90% | **92%** | ⬆️+2 | IT-S05 환불 시나리오 테스트(#1389) 추가 |
| Recurring Events | 90% | **92%** | ⬆️+2 | IT-P09 반복 이벤트 테스트(#1386) 추가 |
| My Tickets | 75% | **82%** | ⬆️+7 | #1206 QR 해소 + #1219 정원 초과 해소 |
| Partner Dashboard | 65% | **75%** | ⬆️+10 | #1217 빈 화면 해소, 이벤트 수정/취소 스펙(#1397) 완성 |
| Event Edit/Cancel | — | **40%** | 🆕 | 스펙+와이어프레임 완성(#1397), 코드 구현(#1396) 종료 |
| Trust Badge | 5% | **5%** | → | 미착수 |

**전체**: MVP 8개 피처 중 7개가 75%+ (이전: 5개). Trust Badge만 유일하게 5%.

---

## 신규 버그 분석

### #1409 — 결제하기 진입 시 Type Cast Error (needs-swe)

- **심각도**: P1급 (PM 판단)
- **발견**: Runtime QA CUJ-U01
- **증상**: 결제 Wizard Step 2에서 '결제하기' 버튼 탭 시 Red Screen
- **에러**: `type 'Null' is not a subtype of type 'Map<String, dynamic>' in type cast`
- **영향**: **이벤트 참가 결제 완전 차단** — 핵심 매출 플로우 불능
- **PM 의견**: 이전 P1(정원 초과, QR, 파트너 빈 화면) 해소 후 드러난 deeper-layer 버그. 결제 관련이므로 P0에 준하는 우선순위로 처리 필요.

---

## 운영 현황

| 지표 | 값 | 이전(#1229) | 변화 |
|------|---|------------|------|
| 열린 이슈 | 5건 | 19건 | ⬇️-14 (74% 감소) |
| 열린 PR | 1건 (#1408) | 2건 | ⬇️-1 |
| P0 차단 | 0건 | 1건 (#1222) | ✅ 해소 |
| P1 미착수 | 0건 | 3건 | ✅ 전수 해소 |
| 3일 머지 PR | 30건 | — | 일 평균 10건 |
| 3일 종료 이슈 | 30건 | — | 일 평균 10건 |
| Integration Test | +8건 (U07, U12, P01, P08, P09, P10, S04, S05) | — | 커버리지 대폭 확대 |

### Supabase Deploy 현황

- #1357 (Deploy Supabase Migrations 실패) → **종료**. #1391에서 config.toml Edge Function 섹션 추가로 해결.
- #1373 TPM Report는 fix 이전 시점에 작성된 것으로 보임. 현재 상태 재확인 필요.

---

## 시장 동향 분석 (외부 시야)

### 1. Eventbrite Social Study 2026 — "경험 중심 소셜"

- **79%**가 이벤트의 자발성/예측불가능성을 중시
- **58%**는 소셜 활동이 중요하지만 메인 포커스는 아닌 걸 선호
- **69%**가 서로 다른 세계/관심사를 결합한 이벤트에 참석 의향
- **89%**가 로컬 커뮤니티 연결이 중요하다고 응답
- 니치 매시업 이벤트 급성장: 커피+러닝 +233%, 도시 Afro 뮤직 루프탑 +444%

**밍글릿 시사점**: 태그 기반 Discovery가 이 트렌드에 정확히 부합. 니치 태그 조합(예: "러닝+커피")을 추천 로직에 반영하면 차별화 가능. 단, 밍글릿은 "경험 자체"보다 "사람 매칭"이 핵심이므로, 이벤트 경험 품질과 매칭 품질의 균형이 중요.

출처: [Eventbrite Social Study](https://www.eventbrite.com/social-study-trends/)

### 2. Partiful "Crush" — 이벤트 앱의 매칭 진출

- Partiful이 이벤트 기반 매칭 기능 "Crush" 출시 (2025 말~2026 초)
- 같은 이벤트 참석자 중 최대 10명에게 익명 관심 표현 → 상호 매칭 시 알림
- "Discover" 탭으로 로컬 이벤트 탐색 확대

**밍글릿 시사점**: Partiful이 RSVP 앱에서 소셜 매칭으로 영역 확장 중. 차이점: 밍글릿은 **이벤트 전 매칭**(함께 갈 사람 매칭), Partiful은 **이벤트 후 매칭**(같이 있었던 사람). 이 "사전 매칭" 포지셔닝을 명확히 하는 게 차별화 키.

출처: [Global Dating Insights](https://www.globaldatinginsights.com/featured/partifuls-crush-tool-brings-dating-style-matching-to-event-app/), [Marketing Brew](https://www.marketingbrew.com/stories/2026/03/09/partiful-marketing-strategy-organic-mentions-the-pitt)

### 3. Bumble BFF — 그룹 소셜의 메인스트림화

- Bumble BFF가 Groups 탭 출시 (Geneva 인수 기반, 2025.09 리론칭)
- 1:1 매칭 → 그룹/커뮤니티 중심으로 전환
- **47%**가 더 많은 친구를, **47%**가 로컬 커뮤니티 플랫폼을 원한다고 응답

**밍글릿 시사점**: 그룹 이벤트 기반 소셜이 메인스트림 트렌드로 확인됨. 밍글릿의 "이벤트 = 그룹 만남의 장"이라는 모델이 시장 방향과 일치. Bumble BFF 대비 강점: **오프라인 이벤트 중심** vs Bumble의 온라인 커뮤니티 중심.

출처: [TechCrunch](https://techcrunch.com/2025/09/18/bumble-bffs-revamped-app-is-here-focusing-on-friend-groups-and-community-building/)

### 4. Trust & Verification — "일회성 인증에서 지속적 신뢰로"

- 2026 트렌드: 원타임 ID 검증 → 지속적 신뢰 관리
- Apple/Google 디지털 ID 월렛 지원 확대
- AI 딥페이크 대응 생체 인증 강화

**밍글릿 시사점**: Trust Badge 피처 방향성이 시장 트렌드에 부합. MVP에서는 "본인인증 뱃지"면 충분. 런칭 후 데이터(이벤트 참석 이력, 무노쇼 기록 등) 기반 확장.

출처: [Regula Forensics](https://regulaforensics.com/resources/identity-verification-trends/), [Biometric Update](https://www.biometricupdate.com/202512/digital-trust-reflections-on-2025-and-outlook-for-2026)

---

## 리스크 매트릭스

| 리스크 | 확률 | 영향 | 대응 상태 |
|--------|------|------|----------|
| **#1409 결제 Type Cast Error** | 확정 | 🔴 핵심 매출 플로우 차단 | needs-swe, 미착수 |
| **Trust Badge 미완성 출시** | 높음 | 🟡 차별화 약화 | ❌ 5% — 3주 연속 미진전 |
| **Partiful Crush → 직접 경쟁** | 중간 | 🟡 포지셔닝 모호화 | 📋 "사전 매칭" 차별화 명확화 필요 |
| **디자인 부채 잔여** | 낮음 | 🟢 UX 일관성 저해 | 🔄 #1383 공용 위젯 완성 진행 중 |

### 이전 리스크 해소

- ~~P0 Supabase DNS~~ → ✅ 해소
- ~~P1 버그 4건 병목~~ → ✅ 전수 해소
- ~~개발 리소스 병목~~ → 🔄 처리량 10건/일 달성으로 완화

---

## PM 판단: 7월 출시 전망

### 전환: 🟡 조건부 가능 → 🟢 궤도 진입

**근거**:
1. **버그 해소 속도 > 발견 속도**: 3일간 30건 해소, 신규 발견 1건(#1409)
2. **MVP 7/8 피처가 75%+**: 이전보다 2개 피처가 75% 선을 돌파
3. **테스트 커버리지 급확대**: Integration Test 8건 추가로 회귀 방지 기반 강화
4. **디자인 시스템 안정화**: 다크모드, 칩 표준화, 시맨틱 컬러 등 기반 확보

**조건**:
1. #1409 결제 버그 이번 주 내 해소 (매출 플로우 복구)
2. Trust Badge: MVP 스코프 결정 필요 — "본인인증 뱃지 표시만"으로 축소 or MVP 제외
3. 이벤트 수정/취소(#1397 스펙 완성) → SWE 구현 착수

---

## 액션 아이템

| # | 긴급도 | 액션 | 담당 | 상태 |
|---|--------|------|------|------|
| 1 | 🔴 P1 | #1409 결제 Type Cast Error 수정 — 핵심 매출 플로우 차단 | needs-swe | 미착수 |
| 2 | 🟡 PM | Trust Badge MVP 스코프 최종 결정 — 3주 연속 미조치 | PM | 🆕 이번 사이클 결정 |
| 3 | 🟡 PM | "사전 매칭" 포지셔닝 문서화 — Partiful Crush 대응 차별화 | PM | 🆕 |
| 4 | 🟢 P2 | 이벤트 수정/취소 구현 착수 — 스펙(#1397) 완성됨 | needs-swe | 대기 |
| 5 | 🟢 PM | 니치 태그 조합 추천 로직 검토 — Eventbrite 트렌드 반영 | PM | 🆕 |

---

## PM 제안: Trust Badge MVP 스코프 결정

3주 연속 액션 아이템으로 남아있는 Trust Badge에 대해 결정을 내린다:

**옵션 A: MVP 포함 (최소 버전)** ← PM 권고
- 본인인증 완료 뱃지 표시만 (프로필, 이벤트 카드)
- 구현 범위: 아이콘 + 조건부 렌더링 (~2-3일)
- 이미 본인인증 로직은 완성된 상태 (#1372 통합 테스트 포함)

**옵션 B: MVP 제외, v2에서 확장**
- 7월 출시에서 제외, 런칭 후 다층 뱃지로 확장
- 리스크: Bumble/Partiful 모두 인증 뱃지 기본 제공 — 없으면 "뒤처진 앱" 인상

**PM 권고: 옵션 A**. 구현 비용 매우 낮고(로직 이미 존재), 시장 트렌드 부합, 런칭 후 확장 기반.

→ Mark 판단 요청

---

*Previous report: #1229 (2026-04-10)*
*Methodology: GitHub issue/PR analysis, web market research (Eventbrite Social Study 2026, Partiful, Bumble BFF, identity verification trends)*
