---
source_url: https://github.com/Mark-Yun/minglit/issues/546
captured_at: 2026-03-27
issue_number: 546
state: closed
labels: [P2-medium, report-exec]
author: Mark-Yun
title: "📊 PM Daily Report — 2026-03-28"
---

# 📊 PM Daily Report — 2026-03-28

> Issue #546 · closed · created 2026-03-27T23:06:53Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/546

## Body

## 📊 PM Daily Report — 2026-03-28

---

### 🌐 기술 스택 업데이트

| 기술 | 최신 버전 | 우리 버전 | 주요 변경 | 리스크 |
|------|----------|----------|----------|--------|
| **Supabase** | v1.26.03 (Mar 5) | CLI v2.84.2 | PostgREST v14 (~20% GET 성능↑), Storage 14.8x 빠른 리스팅, Log Drains on Pro | ⚠️ OpenAPI anon key 접근 제한 (Mar 11), EF 재귀 호출 rate limit (5,000 req/min) |
| **Flutter** | 3.41.0 + Dart 3.9 (Feb 18) | SDK ^3.10.4 | Multi-window API (데스크톱), Impeller on Web, CarouselViewBuilder, RadioGroup | ⚠️ `Color.withOpacity()` deprecated → `withValues()`, AGP 9 미지원 |
| **Deno** | v2.7.9 (Mar 27) | Supabase hosted 런타임 | Temporal API stable, SHA3 지원, Brotli 압축, Node.js compat 개선 | Supabase EF 런타임이 2.7을 지원하는지 확인 필요 |
| **Riverpod** | 3.3.1 (Mar 9) | ^3.0.3 ✅ | Mutations (experimental), Offline persistence (SQLite), Auto retry, `Ref.mounted` | 3.0 마이그레이션 완료 상태. 3.3.1 패치 업데이트 권장 |
| **GoRouter** | 17.1.0 (~Dec 2025) | ^17.0.0 ✅ | `onEnter` 콜백, RelativeGoRouteData, ShellRoute observer 기본 활성화 | ShellRoute observer 변경이 네비게이션 분석에 영향 가능 |

**조치 필요 항목:**
1. Supabase OpenAPI anon key 제한 (3/11 시행) — 클라이언트에서 `/rest/v1/` 스키마 엔드포인트 직접 접근 코드가 있는지 확인
2. Riverpod 3.0.3 → 3.3.1 패치 업데이트 (Auto retry, Ref.mounted 등 유용한 기능 추가)
3. Flutter `Color.withOpacity()` 사용처 점검 (`flutter analyze`로 확인)

---

### 🏪 경쟁/유사 서비스 동향

#### 소셜 매칭 앱

| 서비스 | 동향 | 시사점 |
|--------|------|--------|
| **Bumble** | AI 기반 프로필 사진 피드백 (CV+NLP), AI-first 플랫폼 리빌드 (2026 중반 목표). 유료 유저 16% 감소 (3.6M) | 업계 전체가 AI를 핵심 경쟁축으로 피벗 중 |
| **Hinge** | AI 추천 엔진 (행동 신호 분석), AI Convo Starters (상대 프로필 기반 오프닝 멘트 자동 생성). 매치→대화 전환율 15%↑ | **AI 아이스브레이커는 매칭 후 대화 진입 장벽을 크게 낮춤** |
| **위피 (Wippy)** | 한국 소개팅 앱 매출 1위. "동네 친구 만들기" 포지셔닝. 인앱 화폐("젤리") 기반 수익화 | 하드 페이월 없이 수익화하는 모델 참고 가능 |
| **솔트 (Solut)** | 4.8★, MZ세대 99%, 급성장. 매칭 품질 > 볼륨 강조 | 품질 중심 매칭은 Minglit 파티 모델과 부합 |

**구조적 변화:** 소모임 앱이 소개팅 앱에 밀리는 추세 (MZ세대). 그러나 **이벤트 기반 만남 + 1:1 매칭**을 결합한 플랫폼은 차별화 포지션 — Minglit이 정확히 이 화이트 스페이스.

#### 이벤트 플랫폼

| 서비스 | 동향 | 시사점 |
|--------|------|--------|
| **Eventbrite** | Bending Spoons에 $500M 인수 (2026 H1 마감). AI 이벤트 생성, AI 메시징 도구, 소비자 이벤트 시장 피벗 | 글로벌 이벤트 플랫폼도 AI + 소비자 방향으로 전환 |
| **Meetup** | 2026 로드맵: 통합 앱 (오거나이저 앱 병합), QR 체크인, 커뮤니티 연결 강화 | QR 체크인은 테이블 스테이크 (우리는 이미 구현) ✅ |
| **페스타 (Festa.io)** | **2025년 3월 서비스 종료** | 🔥 한국 IT/개발 이벤트 티켓팅 시장에 공백 발생 |
| **프립 (Frip)** | 호스트 주도 오프라인 활동 플랫폼 유지, 특별한 2026 변화 없음 | 레저/취미 활동 영역은 현재 경쟁 약함 |

**Eventbrite 2026 트렌드 리포트 핵심:**
- 58% 참가자가 "일회성/유일한 느낌"의 이벤트 원함
- 참여형(participatory) 경험 > 수동적 관람
- 로컬/커뮤니티 기반 소규모 이벤트 선호 (63% 오거나이저)
- TikTok이 Gen Z 이벤트 발견 채널로 부상

---

### 💡 신규 기능 제안

#### 1. AI 아이스브레이커 메시지 (매칭 후 대화 시작 도우미)

**배경**: Hinge의 AI Convo Starters가 매치→대화 전환율을 15% 끌어올림. Bumble도 AI 기반 프로필 분석 도구 출시. 업계 전체가 "매칭 후 첫 대화" 허들을 AI로 낮추는 방향.

**제안**: 이벤트 참가 후 매칭된 상대에게 대화를 시작할 때, 상대 프로필 + 참여한 이벤트 컨텍스트를 기반으로 AI가 3개의 대화 시작 문구를 제안. 예: "어제 [이벤트명]에서 같이 있었네요! [공통 관심사]에 대해 더 이야기하고 싶어요."

**기대 효과**: 
- 매칭 후 실제 대화 전환율 개선 (현재 매칭은 되지만 대화 시작이 어려운 유저 경험)
- Minglit의 "이벤트 기반 만남" 차별성 강화 — 순수 소개팅 앱과 달리 공유 경험이라는 자연스러운 대화 소재
- pgvector 인프라 이미 보유 → 유저/파티 임베딩 활용 가능

**적용 난이도**: 보통 (EF에서 LLM API 호출 + 클라이언트 UI)
**긴급도**: 다음 분기 (출시 후 engagement 개선)
**참고**: [Axios — Hinge AI features](https://www.axios.com/2026/03/12/tinder-ai-features-hinge-bumble), [TechCrunch — Bumble AI](https://techcrunch.com/2026/02/26/bumble-adds-ai-powered-photo-feedback-and-profile-guidance-tools/)

#### 2. 한국 이벤트 발견 시장 공략 (Festa.io 공백)

**배경**: 페스타(Festa.io)가 2025년 3월 종료. 한국 IT/개발/소셜 이벤트 티켓팅 독립 플랫폼이 사라짐. Eventbrite 2026 트렌드 리포트에서 로컬/커뮤니티 기반 소규모 이벤트가 가장 빠르게 성장하는 세그먼트로 확인.

**제안**: 유저 앱의 홈 피드에 **카테고리 기반 이벤트 큐레이션** 강화 — 현재 PartyCurationPage가 존재하지만, 위치 기반 + 관심사 태그 기반 필터링을 고도화하여 Festa가 남긴 "이벤트 발견" 시장을 흡수. 파트너 온보딩 시 "IT/개발", "소셜", "문화" 등 카테고리 태깅 필수화.

**기대 효과**: 이벤트 발견 → 신청 전환 퍼널 개선, 파트너 유입 경로 확장
**적용 난이도**: 쉬움 (기존 인프라 활용, PGroonga 검색 + 태그 필터)
**긴급도**: 지금 (출시 전 카테고리 태깅 체계는 초기에 잡아야 함)
**참고**: [Skift — Eventbrite 인수](https://meetings.skift.com/2025/12/02/bending-spoons-to-acquire-eventbrite-in-500-million-cash-deal/), [Eventbrite 2026 트렌드](https://www.eventbrite.com/blog/reset-to-real-social-study-event-trends/)

#### 3. 네이버페이 / 카카오페이 결제 수단 추가

**배경**: 한국 온라인 간편결제 시장에서 네이버페이 51.5%, 카카오페이 25.1%, 토스페이 13.2%. 20대 간편결제 사용률이 가장 높음 (Minglit 타겟 MZ세대). 연간 시장 규모 약 403조원. 쿠팡페이도 2026 Q1 외부 간편결제 시장 진출 발표.

**제안**: 현재 PortOne(구 Iamport) 기반 결제 인프라에 네이버페이, 카카오페이를 1순위 결제 수단으로 추가. PortOne V2 SDK가 이미 멀티PG를 지원하므로 PG사 설정 + 클라이언트 UI 추가로 구현 가능.

**기대 효과**: 결제 전환율 개선 (MZ세대가 가장 많이 쓰는 결제 수단 제공)
**적용 난이도**: 보통 (PortOne 연동은 되어있으나 PG사 계약 + UI 추가 필요)
**긴급도**: 지금 (출시 전 결제 수단 다양화 필수)
**참고**: [OpenSurvey 간편결제 리포트](https://blog.opensurvey.co.kr/article/ds-payment-2025-2/), [PortOne PG 비교](https://blog.portone.io/opi_pg-comparison/)

---

### 🔧 기술 추천

#### 1. 파트너 온보딩 Liveness Detection 도입

**현재 문제**: 파트너(업체) 입점 심사에서 서류 기반 검증만 수행. 2025년 딥페이크 기반 합성 신원 사기가 3배 증가 (전체 사기 시도의 28%가 고도화된 공격). AI 생성 문서도 2% 탐지.

**제안**: `google_ml_kit` 패키지의 on-device face detection을 활용하여, 파트너 신청 시 대표자 본인 확인에 liveness check 추가. 온디바이스 처리로 프라이버시 보존.

**기대 효과**: 파트너 신뢰도 강화, 사기 파트너 가입 차단
**적용 난이도**: 보통 (google_ml_kit + 파트너 신청 위저드 스텝 추가)
**참고**: [Sumsub — Identity Fraud Trends 2026](https://sumsub.com/blog/top-new-identity-fraud-trends/), [Biometric Update — Korea Face Mandate](https://www.biometricupdate.com/202512/south-korea-to-mandate-face-biometrics-for-new-mobile-numbers-by-2026)

#### 2. Riverpod Mutations 도입 (실험적)

**현재 문제**: 폼 제출, 버튼 액션 등 사이드 이펙트의 로딩/성공/에러 상태를 각 Controller에서 수동 관리.

**제안**: Riverpod 3.x의 Mutations (experimental) 기능을 활용하여 사이드 이펙트 상태 관리를 선언적으로 전환. 이미 3.0.3 사용 중이므로 도입 가능.

**기대 효과**: 보일러플레이트 감소, 일관된 에러/로딩 처리
**적용 난이도**: 쉬움 (이미 Riverpod 3.x 사용 중, experimental API)
**긴급도**: 다음 분기
**참고**: [Riverpod What's New](https://riverpod.dev/docs/whats_new)

---

### 🚧 기능 완성도 (출시 기준)

| 영역 | 상태 | 비고 |
|------|------|------|
| RLS → EF 전환 | ✅ 완료 | Phase 1 (EF 생성) + Phase 2 (클라이언트 전환) 완료. Phase 3 (RLS 정책 제거) 남음 |
| 유저 앱 핵심 플로우 | ✅ 구현 | 홈, 검색, 이벤트 상세, 신청 위저드, 결제, 매칭 투표, 구매 내역, 알림 |
| 파트너 앱 핵심 플로우 | ✅ 구현 | 대시보드, 파티/이벤트 CRUD, 티켓 관리, 정산, 체크인, 인증 심사, 멤버 관리 |
| 신청 승인/거절 | ✅ 구현 | partner-approve-application, partner-reject-application EF 신규 추가 |
| 개인정보 설정 화면 | ⚠️ Placeholder | `privacy_page.dart` (Fix #139) — 빈 페이지 상태 |
| 카테고리/태그 기반 이벤트 발견 | ⚠️ 미강화 | 큐레이션 페이지 존재하나, 카테고리 태깅 체계 미비 |

---

### 📈 업계 트렌드 요약

- **AI가 소셜 앱의 핵심 경쟁축**: 프로필 분석, 매칭 추천, 대화 시작 도우미 등 AI가 유저 경험 전반에 내재화
- **로컬/소규모 이벤트 성장**: Eventbrite 조사에서 63% 오거나이저가 소규모 이벤트 선호 확인
- **한국 간편결제 시장 과점 심화**: 네이버+카카오가 온라인 76.6% 장악, 쿠팡페이 진입으로 경쟁 심화
- **딥페이크 사기 급증**: 고도화된 사기 28% (전년 10%), 신원 확인에 liveness detection 필수화 추세
- **한국 모바일 생체인증 의무화**: 2026년 3월 전국 시행 — 전화번호 인증의 신뢰도 상승
- **다크모드**: Android 유저 81.9%가 사용, 필수 지원 (우리는 이미 지원 ✅)
- **패스키/생체 인증**: 비밀번호 대체 트렌드 가속화
