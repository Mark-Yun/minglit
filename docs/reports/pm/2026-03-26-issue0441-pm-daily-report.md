---
source_url: https://github.com/Mark-Yun/minglit/issues/441
captured_at: 2026-03-26
issue_number: 441
state: closed
labels: [report-exec]
author: Mark-Yun
title: "📊 PM Daily Report — 2026-03-26"
---

# 📊 PM Daily Report — 2026-03-26

> Issue #441 · closed · created 2026-03-26T03:04:46Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/441

## Body

## 📊 PM Daily Report — 2026-03-26

### 🌐 기술 스택 업데이트

| 기술 | 최신 버전 | 우리 버전 | 주요 변경 |
|------|----------|----------|----------|
| Flutter | 3.41 (Dart 3.11) | Dart ^3.10.4 | Multi-window API, `Color.withOpacity()` deprecated → `withValues()`, CarouselView.builder |
| Supabase Platform | v1.26.03 | supabase_flutter ^2.12.0 | Storage 14.8x 성능 개선(listV2), Log Drains Pro 티어 출시, X/Twitter OAuth, Hydra(pg_duckdb) 인수 |
| Deno | 2.7.8 | Edge Functions 사용 | Temporal API 안정화, `Deno.cron()` Deploy 지원, Deploy GA ($200/mo Builder plan) |
| PostgreSQL | 17 | 17 | ✅ 최신 |

**주의 사항:**
- `Color.withOpacity()`가 Flutter 3.41에서 deprecated됨 → `dart fix --apply`로 일괄 마이그레이션 필요
- Supabase Storage `listV2` 엔드포인트 전환 시 deep pagination 14.8x 성능 향상 가능
- Freezed 3.0 메이저 breaking change 출시 (Dart macros 취소 대응) — 현재 ^3.2.3 사용 중, 업그레이드 시 코드젠 파일 전체 점검 필요

---

### 🏪 경쟁/유사 서비스 동향

#### 글로벌 데이팅/소셜 앱

| 서비스 | 신규 기능 (Q1 2026) | 우리에게 시사점 |
|--------|---------------------|----------------|
| **Tinder** | AI Chemistry(행동 기반 매칭), Speed Dating Events(실시간 그룹 비디오), Face Check 의무화 | 그룹 이벤트 포맷을 세계 1위 앱이 직접 검증 중 — minglit의 이벤트 매칭 방향성과 일치 |
| **Hinge** | Direct to Date(매칭→일정 즉시 잡기), Face Check 글로벌 확대(스팸 50%↓) | 매칭→실제 만남 전환율이 핵심 KPI. 이벤트 참여 예약 UX 단축 필요 |
| **Bumble** | AI 프로필/사진 피드백(글로벌), Suggest a Date(캐나다 파일럿) | 프로필 완성도가 매칭 품질에 직결 — AI 가이드 도입 검토 가치 |

#### 한국 소셜 앱
- **소모임, 아만다, 위피, 블라인드소개팅**: Q1 2026 주요 기능 발표 없음
- → 글로벌 트렌드(본인인증 강화, AI 매칭, IRL 이벤트)가 아직 한국 경쟁앱에 미반영된 **선점 기회**

#### 이벤트 플랫폼
- **Eventbrite**: Bending Spoons에 $500M 인수(비상장 전환). Meetup도 동일 모회사 — 양대 플랫폼 통합 리스크 발생
- **Meetup**: 2026 로드맵에 QR 체크인, 단일 앱 통합 포함
- **페스타(festa.io)**: Q1 2026 신규 발표 없음
- → Eventbrite+Meetup 독점 심화로 **니치 이벤트 플랫폼에 시장 기회** 존재

---

### 💡 신규 기능 제안

#### 1. 본인인증 강화 (Identity Verification)
**배경**: Hinge Face Check 도입 후 스팸/사기 계정 50% 이상 감소. Tinder는 미국 신규 가입 시 의무화. 글로벌 표준으로 자리잡는 중.
**제안**: 현재 trust-and-verification 2-layer 모델(Identity + Qualification)에 **얼굴 인증 레이어 추가**. 가입 시 셀카 촬영 → 프로필 사진과 대조 → 인증 배지 부여. 한국 시장에서는 PASS 인증 + 얼굴 매칭 조합이 현실적.
**기대 효과**: 플랫폼 신뢰도 대폭 향상, 허위 프로필 차단, 유저 리텐션 개선
**적용 난이도**: 어려움 (3rd party 얼굴 인식 API 연동 + 개인정보 처리 동의 설계)
**긴급도**: 다음 분기 (경쟁 우위 선점)
**참고**: [Hinge Face Check](https://www.globaldatinginsights.com/featured/hinge-expands-face-check-testing-adds-direct-to-date-feature/)

#### 2. 매칭→이벤트 즉시 예약 (Direct to Event)
**배경**: Hinge "Direct to Date"가 매칭 직후 만남 일정을 잡는 기능을 파일럿 중. Tinder도 Speed Dating Events로 그룹 실시간 만남 도입. 핵심 트렌드는 **매칭에서 실제 만남까지의 시간 단축**.
**제안**: 이벤트 상세 페이지에서 "함께 참여할 사람 찾기" → 관심사/프로필 기반 매칭 → 바로 같은 이벤트에 동반 참여 예약. 매칭과 이벤트 참여를 하나의 플로우로 합치기.
**기대 효과**: 이벤트 참여 전환율 향상, 매칭 품질 향상(같은 관심사 기반), 차별화
**적용 난이도**: 보통 (매칭 로직 + 이벤트 참여 플로우 연결)
**긴급도**: 다음 분기
**참고**: [Hinge Direct to Date](https://www.globaldatinginsights.com/featured/hinge-expands-face-check-testing-adds-direct-to-date-feature/), [Tinder AI Features](https://www.axios.com/2026/03/12/tinder-ai-features-hinge-bumble)

#### 3. AI 프로필 가이드
**배경**: Bumble이 AI 기반 프로필 가이드를 글로벌 출시. 사진 품질 분석, 바이오 개선 제안을 제공하여 프로필 완성도와 매칭률 향상.
**제안**: 프로필 작성/편집 시 AI가 개선 포인트 제안 — "사진이 어둡습니다", "자기소개에 관심사를 추가하면 매칭률 2배". pgvector 기반 추천 시스템과 연계하여 프로필 완성도 스코어링.
**기대 효과**: 프로필 완성률 향상 → 매칭 품질 향상 → 유저 만족도 증가
**적용 난이도**: 보통 (Edge Function + LLM API 호출)
**긴급도**: 장기 (핵심 매칭 플로우 안정화 후)
**참고**: [Bumble AI Features — TechCrunch](https://techcrunch.com/2026/02/26/bumble-adds-ai-powered-photo-feedback-and-profile-guidance-tools/)

---

### 🔧 기술 추천

#### 1. Supabase Log Drains → Axiom 연동
**현재 문제**: Edge Function 디버깅 시 Axiom을 사용하고 있으나(docs/debugging/edge-functions.md 참조), 로그 수집 경로가 수동/부분적.
**제안**: Supabase Log Drains (Pro 티어, 2026년 3월 출시)로 Postgres/Auth/Storage/Edge Functions/Realtime 로그를 Axiom에 자동 스트리밍. $60/drain/project + $0.20/M events.
**기대 효과**: 전체 스택 통합 옵저버빌리티, 장애 감지 시간 단축
**적용 난이도**: 쉬움 (대시보드 설정)
**긴급도**: 지금 (Pro 플랜 사용 중이라면 즉시 적용 가능)
**참고**: [Supabase Log Drains](https://supabase.com/blog/log-drains-now-available-on-pro)

#### 2. Supabase Storage listV2 마이그레이션
**현재 문제**: Storage 객체 목록 조회 시 OFFSET 기반 페이지네이션 사용 → 대량 파일 시 성능 저하.
**제안**: `listV2` 엔드포인트(cursor-based pagination)로 전환. 60M+ row 기준 14.8x 성능 향상. 코드 변경 없이 자동 적용되지만, SDK 호출을 `listV2`로 명시 전환하면 최대 효과.
**기대 효과**: 파일 목록 조회 성능 대폭 향상
**적용 난이도**: 쉬움
**긴급도**: 지금
**참고**: [Supabase Storage Overhaul](https://supabase.com/blog/supabase-storage-performance-security-reliability-updates)

#### 3. Edge Functions에 Temporal API 도입
**현재 문제**: 날짜/시간 처리에 `Date` 객체 사용 — 타임존 변환, 기간 계산 등이 번거롭고 버그 유발 가능.
**제안**: Deno 2.7에서 안정화된 Temporal API 사용. `Temporal.ZonedDateTime`, `Temporal.Duration` 등으로 KST 타임존 처리 명확화.
**기대 효과**: 날짜/시간 관련 버그 감소, 코드 가독성 향상
**적용 난이도**: 보통 (기존 Date 사용 코드 점진적 마이그레이션)
**긴급도**: 다음 분기
**참고**: [Deno 2.7 Release](https://github.com/denoland/deno/releases)

---

### 📈 업계 트렌드 요약

- **IRL 가속화**: 글로벌 데이팅 앱들이 "온라인 매칭 → 오프라인 만남" 전환 속도를 핵심 지표로 설정. 이벤트/소셜 플랫폼에 유리한 매크로 트렌드.
- **AI는 대체가 아닌 촉진 도구**: AI가 프로필 작성, 매칭, 대화를 돕되 인간 연결을 대체하지 않는 방향. AI 생성 콘텐츠에 대한 불신 증가.
- **본인인증 = 기본 기능**: Face Check, 실명인증이 프리미엄이 아닌 기본 안전 기능으로 전환 중.
- **이벤트 플랫폼 통합**: Eventbrite+Meetup 동일 모회사 — 독점 심화로 니치 플랫폼에 기회.
- **한국 간편결제 > 실물카드**: 카카오페이/네이버페이를 1순위 결제 수단으로 배치해야 함. 구독/링크결제 급성장.
- **모바일 UX 2026**: AI 적응형 레이아웃, 미니멀 UI, 제스처 우선 내비게이션, 패스키 인증이 메인스트림.

---

*Sources: Axios, TechCrunch, Global Dating Insights, Supabase Blog, Flutter Dev, Deno Blog, PortOne Blog, Analytics Insight, SPDLoad, Event Tech Live*
