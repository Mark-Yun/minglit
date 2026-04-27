---
source_url: https://github.com/Mark-Yun/minglit/issues/721
captured_at: 2026-03-29
issue_number: 721
state: closed
labels: [report-exec]
author: Mark-Yun
title: "📊 PM Daily Report — 2026-03-29"
---

# 📊 PM Daily Report — 2026-03-29

> Issue #721 · closed · created 2026-03-29T02:15:58Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/721

## Body

## 📊 PM Daily Report — 2026-03-29

### 🌐 기술 스택 업데이트

| 기술 | 최신 | 주요 변경 | 우리에게 시사점 |
|------|------|----------|---------------|
| **Supabase** | v1.26.03 (Mar 2026) | PostgREST v14 (GET 요청 ~20% RPS 향상), AI 테이블 필터, Diff View, Index Advisor, **OpenAPI anon key 접근 차단 (3/11~)** | ⚠️ OpenAPI 보안 변경 영향 확인 필요. PostgREST v14 성능 향상은 자동 적용 |
| **Flutter** | 3.41 (Feb 2026) | Impeller 2.0 (셰이더 jank 제거), 멀티윈도우 API, Swift Package Manager 전환 촉구, `Navigator.popUntilWithResult`, 콘텐츠 기반 뷰 자동 리사이즈 | Impeller 2.0은 이벤트 상세 페이지 스크롤 성능에 직접 영향. SPM 전환은 iOS 빌드 안정화에 필요 (P3) |
| **Deno** | 2.7 (Feb 2026) | Temporal API 안정화 (--unstable-temporal 불필요), npm overrides 지원, 새 `Deno.spawn()` API | Temporal API로 Edge Function의 날짜/시간 처리 표준화 가능. 정산 배치의 타임존 로직에 유용 |

### 🏪 경쟁/유사 서비스 동향

#### 데이팅/소셜 매칭 앱 — IRL 이벤트 통합 가속

**Tinder (SPARKS 2026 키노트, 2026.03.12)**
- **이벤트 디스커버리**: 지역 사회 활동 탐색 + 참석 예정자 확인 기능 도입. "앱 밖에서 만나기"를 플랫폼 내로 통합
- **AI "Chemistry" 매칭**: 질문 + 카메라 롤 분석으로 일일 맞춤 매치 추천. 스와이프 피로 해결 목표
- **가상 스피드 데이팅**: 비디오 기반 3분 대화 세션
- → **밍릿 시사점**: 최대 경쟁자가 밍릿의 핵심 모델(이벤트 기반 만남)을 따라오고 있음. AI 추천과 이벤트 전/중/후 경험에서 차별화 필요

**Bumble (2026.02)**
- **AI 프로필 피드백**: 사진/소개글에 AI가 개선 제안. 미국 한정 카메라 롤 분석
- **Accountability Score**: 대화 중단 패턴 추적 → "Reliable Communicator" 뱃지 부여
- → **밍릿 시사점**: 파트너의 이벤트 설명/이미지에 AI 품질 피드백 적용 가능. 호스트 신뢰도 뱃지 참고

**Hinge (2026)**
- **AI Date Concierge**: 공통 관심사 기반 구체적 장소(카페, 바) 추천
- **Safety Check-in**: 데이트 중 위치 기반 안전 확인 알림 → 미응답 시 긴급 연락처 알림
- → **밍릿 시사점**: 이벤트 당일 안전 체크인 기능은 신뢰 구축에 유용. 특히 소규모 이벤트/1:1 매칭에서 중요

#### 이벤트 플랫폼

**Meetup (2026 로드맵)**
- **통합 앱**: 주최자/참가자 앱 통합 → 단일 경험으로 전환
- **QR 체크인 간소화**: 출석 추적을 QR 기반으로 단순화
- → **밍릿 시사점**: 밍릿은 user/partner 앱 분리 유지가 적절 (역할 차이 큼). QR 체크인은 이미 구현 중 (내 티켓 파이프라인)

**소모임 (Somoim)**
- 500만+ 다운로드, 한국 오프라인 커뮤니티 1위. 웹 버전 출시 (2024.12)
- → **밍릿 시사점**: 소모임은 "동호회/취미" 영역. 밍릿의 "이벤트 기반 매칭"과는 포지셔닝이 다르지만, 커뮤니티 기능 강화 시 경쟁 영역 겹칠 수 있음

### 💡 신규 기능 제안

#### 1. AI 이벤트 추천 — "Chemistry for Events"

**배경**: Tinder가 AI "Chemistry" 기능으로 프로필+행동 기반 일일 맞춤 매치를 시작. 모든 주요 데이팅 앱이 "스와이프 피로" 해결을 위해 AI 개인화에 투자 중. 동시에 Tinder가 이벤트 디스커버리 기능을 도입하며 밍릿의 핵심 영역에 진입.

**제안**: 유저의 참석 이력, 관심 카테고리, 위치, 시간대 선호를 분석하여 "오늘의 추천 이벤트" 3~5개를 홈 피드 상단에 노출. 기존 pgvector 인프라를 활용하여:
- 유저 프로필 → 임베딩 벡터 생성
- 이벤트 메타데이터 → 임베딩 벡터 생성
- 코사인 유사도 기반 추천 + 최근 참석 이벤트 가중치

**기대 효과**:
- Tinder의 이벤트 진입에 대한 선제 대응: "AI 추천 + 이벤트" 조합은 밍릿이 먼저 구현 가능
- 이벤트 발견율 향상 → 참석률 증가 → 파트너 수익 증가
- "스와이프 피로" 없는 이벤트 중심 UX로 차별화

**적용 난이도**: 보통 (pgvector 이미 존재, 추천 아키텍처 `docs/architecture/search-and-recommendation.md`에 설계 있음)
**긴급도**: 이번 분기 (Tinder의 이벤트 기능 론칭 전에 선점)
**참고**: [Tinder SPARKS 2026](https://techcrunch.com/2026/03/12/tinder-tries-to-lure-people-back-to-online-dating-with-irl-events-virtual-speed-dating/), [Tinder AI Features](https://www.axios.com/2026/03/12/tinder-ai-features-hinge-bumble)

#### 2. 호스트 신뢰도 시스템 — "Reliable Host" 뱃지

**배경**: Bumble의 "Accountability Score" + "Reliable Communicator" 뱃지가 유저 신뢰 구축에 효과적. 밍릿에서는 파트너(호스트)의 신뢰도가 유저 참석 결정에 직접 영향.

**제안**: 파트너의 이벤트 운영 데이터를 기반으로 신뢰도 점수를 산출하고 뱃지를 부여:
- 이벤트 정시 시작률
- 참석자 리뷰 평점
- 취소/변경 빈도
- 환불 요청 비율
- 연속 개최 횟수

**기대 효과**:
- 유저의 이벤트 선택 시 신뢰 기반 의사결정 지원
- 우수 호스트에게 인센티브 (검색 노출 우선순위 등)
- 밍릿의 2-layer 신뢰 모델(Identity + Qualification)에 3번째 레이어(Performance) 추가

**적용 난이도**: 보통 (데이터는 이미 수집 중, 점수 산출 로직 + 뱃지 UI 추가)
**긴급도**: 다음 분기
**참고**: [Bumble Accountability Scores](https://techcrunch.com/2026/02/26/bumble-adds-ai-powered-photo-feedback-and-profile-guidance-tools/)

### 🔧 기술 추천

#### 1. ⚠️ Supabase OpenAPI anon key 접근 차단 대응 (긴급)

**현재 문제**: 2026.03.11부터 Supabase가 `/rest/v1/` OpenAPI 스키마 엔드포인트의 anon key 접근을 차단. "Access to schema is forbidden" 에러 발생.
**제안**: 코드베이스에서 OpenAPI spec을 anon key로 접근하는 부분이 있는지 확인. 있다면 service role key로 교체. 일반 Data API 호출(`/rest/v1/your_table`)에는 영향 없음.
**적용 난이도**: 쉬움 (영향 확인 + 키 교체)
**긴급도**: 지금 (이미 적용됨)
**참고**: [Supabase OpenAPI Breaking Change](https://github.com/orgs/supabase/discussions/42949)

#### 2. Deno Temporal API 활용 (정산 배치 타임존 처리)

**현재 문제**: Edge Function에서 날짜/시간 처리 시 `Date` 객체의 타임존 한계. 정산 배치에서 KST/UTC 변환이 수동적.
**제안**: Deno 2.7에서 안정화된 Temporal API(`Temporal.ZonedDateTime`, `Temporal.Duration`)를 정산 관련 Edge Function에서 활용. `--unstable-temporal` 플래그 불필요.
**기대 효과**: 정산 마감일, 환불 보증기간(14일) 계산의 타임존 버그 방지
**적용 난이도**: 보통 (기존 Date 로직을 Temporal로 점진 교체)
**긴급도**: 다음 분기 (정산 EF 구현 시 적용)
**참고**: [Deno 2.7 Temporal API](https://deno.com/blog/v2.7)

### ⚖️ PG 규제 변경 — 정산 시스템 영향

**FSC 규제 강화 (2026년 시행)**:
- PG사에 **미정산 자금 100% 외부 관리** 의무 (예치금, 신탁, 또는 지급보증보험)
- 미정산 자금 유용 또는 정산 기한 초과 시 **행정제재** (시정 명령, 영업정지, 등록 취소)
- 셀러(파트너)에게 미정산 자금 관리 방식 **사전 고지** 의무

→ **밍릿 시사점**: `partner-settlement` 기능 구현 시 PG사(토스페이먼츠)의 정산 주기/방식이 규제에 맞게 변경될 가능성. SRS `requirements.md`의 상태 머신 + 환불 보증기간 로직에 규제 요건 반영 여부 확인 필요.
**참고**: [FSC 규제 발표](https://www.fsc.go.kr/eng/pr010101/83048), [Kim & Chang 분석](https://www.kimchang.com/en/insights/detail.kc?sch_section=4&idx=31057)

### 🚧 기능 완성도 (출시 기준)

#### 피처 파이프라인 현황

| 피처 | spec | wireframe | plan | test-plan | 구현 | 상태 |
|------|------|-----------|------|-----------|------|------|
| **내 티켓 (My Tickets)** | ✅ | ✅ | ✅ | ✅ | ❌ | 파이프라인 완료, **구현 대기** |
| **이벤트 나우바** | ✅ | ✅ | ✅ | ❌ | ❌ | 테스트 계획 필요 |
| **디자인 패턴 카탈로그** | ✅ | ✅ | ✅ | ✅ | ❌ | 파이프라인 완료, 구현 대기 |
| **파트너 정산** | ✅ (SRS) | ❌ | ✅ (arch) | ❌ | 부분 | SRS 187항목 + arch + UI/UX 존재. 표준 파이프라인 형식 아님 |
| **개인정보 보호** | ❌ | ✅ | ❌ | ❌ | ❌ | UI/UX 설계서 + wireframe 존재, spec 미전환 |

#### IA 대비 미구현 화면

| 기능 | IA 정의 | 라우트 구현 | 상태 |
|------|---------|-----------|------|
| 내 티켓 | `/tickets/my` (가드만 설정) | ❌ 라우트 미정의 | 파이프라인 완료, 구현 대기 |
| 결제 | `/payment` (가드만 설정) | ❌ 라우트 미정의 | 위저드 내 스텝으로 존재 |
| 매칭 투표 | feature dir 존재 | 부분 구현 | 완성도 불명 |

### 📈 업계 트렌드 요약

- **IRL 이벤트 통합**: Tinder, Bumble, Hinge 모두 "앱 밖 만남"을 플랫폼 내로 통합 중. 밍릿의 이벤트 중심 모델이 업계 방향과 정확히 일치 — **선점 우위 유지가 핵심**
- **AI 개인화 필수화**: 모든 주요 앱이 AI 추천/피드백/매칭에 투자. pgvector 기반 추천 인프라가 있는 밍릿도 조기 적용 필요
- **PG 규제 강화**: 미정산 자금 보호 의무화. 정산 시스템 설계 시 규제 준수 확인 필요
- **신뢰/안전 기능**: Safety Check-in(Hinge), Accountability Score(Bumble) 등 신뢰 기능이 차별화 요소로 부상

### 📋 PM 후속 작업

| # | 작업 | 우선순위 | 비고 |
|---|------|---------|------|
| 1 | AI 이벤트 추천 기능 spec 작성 (needs-pm 이슈 생성 검토) | P1 | Tinder 이벤트 기능 대응 |
| 2 | partner-settlement 표준 파이프라인 전환 (spec.md 형식) | P2 | SRS 존재하나 파이프라인 미연결 |
| 3 | privacy-protection spec.md 작성 | P2 | UI/UX 설계서를 spec으로 전환 |
| 4 | Supabase OpenAPI 보안 변경 영향도 확인 요청 (needs-dev) | P1 | 이미 시행 중인 변경 |

### 처리 완료

- **#650** (needs-pm, 디자인 카탈로그 리뉴얼) — wireframe 존재 + 파이프라인 test-plan까지 진행 확인 → **Closed**
- **#655** (needs-pm, 어제 PM 리포트) — 후속 작업 항목 확인 → **needs-pm 라벨 제거**

## Comments (4)

### Comment 1 — @Mark-Yun on 2026-03-29

### 🔄 추가 Supabase 업데이트 (상세 조사 결과)

리포트 본문에 포함되지 않은 추가 발견사항:

#### ⚠️ Edge Functions 재귀 호출 Rate Limit (2026.03.06 시행)
- EF에서 같은 프로젝트의 다른 EF를 `fetch()`로 호출 시 **5,000 req/min** rate limit 적용
- **밍릿 영향**: PGMQ 2-tier 이벤트 파이프라인(`docs/architecture/global-event-pipeline.md`)에서 EF 체이닝 패턴 확인 필요. 이벤트 폭주 시 throttling 위험
- **추천**: EF 호출 깊이 감사 → needs-dev 이슈 생성 검토

#### ⚠️ Legacy API Key 마이그레이션 (Late 2026 데드라인)
- `anon` → `sb_publishable_...`, `service_role` → `sb_secret_...` 형식으로 전환 예정
- 마이그레이션 안 하면 앱 중단
- **밍릿 영향**: `minglit_env/*/flutter.env`의 dart-define + 백엔드 통합 테스트에서 키 참조 부분 모두 교체 필요
- **추천**: P2로 추적, 후반기 전에 마이그레이션

#### MD5 패스워드 해싱 Deprecated
- 커스텀 DB role이 MD5 사용 중이면 Postgres 업그레이드 전 `scram-sha-256`로 전환 필요

#### Storage 성능 개선
- 60M+ row 데이터셋에서 오브젝트 리스팅 **14.8x 빠름** (prefixes 테이블 + 6개 트리거 → skip-scan 알고리즘 교체)

#### Log Drains (Pro 티어)
- Postgres, Auth, Storage, EF, Realtime 로그를 Datadog, Grafana Loki, Sentry, Axiom, S3로 라우팅 가능
- **밍릿 시사점**: 현재 Axiom + Sentry 사용 중 → Log Drains로 통합 로깅 구성 가능

### Comment 2 — @Mark-Yun on 2026-03-29

### 🔄 추가 Flutter 업데이트 (상세 조사 결과)

#### ⚠️ iOS UIScene 라이프사이클 마이그레이션 (필수)
- Apple이 iOS 26+ SDK 빌드에 UIScene 라이프사이클 **강제 예정**
- Flutter 3.38에서 마이그레이션 툴링 제공 (`flutter migrate`)
- **밍릿 영향**: app_user, app_partner 모두 해당. 7월 출시 전 마이그레이션 필요
- **긴급도**: P1 — 출시 전 필수

#### ⚠️ SnackBar 동작 변경 (Flutter 3.38)
- Action이 있는 SnackBar가 **더 이상 자동으로 사라지지 않음** (행동 변경)
- **밍릿 영향**: 앱 전체에서 SnackBar+Action 사용 부분 확인 필요. UX에 직접 영향

#### Deprecated API
- `Color.withOpacity()` → `Color.withValues()` 로 교체 필요 (3.38+3.41)
- `containsSemantics` → `isSemantics`
- `findChildIndexCallback` → `findItemIndexCallback`

#### 2026 로드맵
- Impeller on Android: Skia 백엔드 제거 예정 (API 29+)
- WebAssembly 기본값 전환 목표
- Android Gradle Plugin 9.0.0 마이그레이션 예정 — 빌드 파이프라인 테스트 필요

**참고**: [Flutter 3.41 릴리즈 노트](https://docs.flutter.dev/release/release-notes/release-notes-3.41.0), [Flutter 3.38 릴리즈 노트](https://docs.flutter.dev/release/release-notes/release-notes-3.38.0)

### Comment 3 — @Mark-Yun on 2026-03-29

### 🔄 추가 시장 동향 (상세 조사 결과)

#### 🔴 페스타(Festa) 서비스 종료 — 한국 커뮤니티 이벤트 시장 공백

**페스타(festa.io)가 2025년 3월 서비스 종료.** 한국 테크/커뮤니티 이벤트 티켓팅의 핵심 플랫폼이었으며, 종료 후 시장 공백 발생:
- **이벤터스(event-us.kr)**: B2B/MICE 중심으로 대체 중 (삼성SDS, 카카오, 야놀자 등 14,000+ 클라이언트)
- **Luma**: Festa 대체로 커뮤니티 이벤트에서 트랙션 확보 중

→ **밍릿 시사점**: 커뮤니티 이벤트 + 소셜 매칭이라는 밍릿의 포지셔닝은 페스타가 남긴 시장 공백에 정확히 들어맞음. **한국 시장에서 비법인 커뮤니티 이벤트 티켓팅을 지원하면 Festa 이탈 유저 확보 가능.**

#### Tinder Events Tab — 구체적 타임라인

- LA에서 2026년 5~6월 베타 예정
- 큐레이션된 로컬 이벤트(볼링, 도예, 파티 등) + "누가 관심 있는지" 표시
- → Tinder의 한국 진출까지 시간 여유가 있으므로, **밍릿이 한국 시장에서 먼저 이벤트+매칭 경험을 확립**하는 것이 핵심

#### Toss Payments MCP 서버 출시

- AI 코딩 에이전트가 결제 연동을 더 빠르게 할 수 있도록 MCP(Model Context Protocol) 서버 제공
- Quick Account Transfer(퀵계좌이체) — 카드 자동결제보다 낮은 수수료로 빌링/자동결제 지원
- 정산 안정성 중심 전략으로 전환
- → **밍릿 시사점**: partner-settlement 구현 시 Toss Payments MCP 활용하면 연동 속도 향상. 퀵계좌이체는 수수료 절감 옵션

#### AI 아이스브레이커 (업계 표준화)

- 매칭 시점에 생성형 AI가 상대방과의 공통점 기반 첫 메시지를 제안
- Tinder, Bumble, Hinge 모두 도입 → **업계 table stakes**
- → **밍릿 시사점**: 이벤트 참석 후 매칭된 상대에게 "이 이벤트에서 둘 다 즐겼던 것" 기반 대화 시작 제안 가능

#### Passkeys — 2026년 Early Majority 진입

- FIDO2/WebAuthn 기반 패스키가 소비자 앱 표준으로 부상
- 한국에서는 카카오/네이버 로그인 위에 패스키를 레이어링하는 패턴이 현실적
- → **밍릿 시사점**: 출시 후 보안 강화 시 패스키 지원 고려 (P3)

**참고**: [TechCrunch — Tinder IRL Events](https://techcrunch.com/2026/03/12/tinder-tries-to-lure-people-back-to-online-dating-with-irl-events-virtual-speed-dating/), [TheVC — Festa](https://thevc.kr/festa), [FETV — Toss Payments 전략](https://www.fetv.co.kr/news/article.html?no=196113)

### Comment 4 — @Mark-Yun on 2026-03-29

확인 완료.
