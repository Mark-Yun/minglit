---
source_url: https://github.com/Mark-Yun/minglit/issues/866
captured_at: 2026-03-30
issue_number: 866
state: closed
labels: [P3-low, report-exec]
author: Mark-Yun
title: "📊 PM Daily Report — 2026-03-30"
---

# 📊 PM Daily Report — 2026-03-30

> Issue #866 · closed · created 2026-03-30T08:05:20Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/866

## Body

## 📊 PM Daily Report — 2026-03-30

### 🌐 기술 스택 업데이트

| 기술 | 최신 버전 | 주요 변경 | 우리에게 영향 |
|------|----------|----------|-------------|
| Supabase | v1.26.03 (March 2026) | ⚠️ OpenAPI spec anon key 접근 deprecated (3/11~), Storage 최대 14.8x 성능 개선, AI 대시보드 필터, Queue 기반 Table Editor | OpenAPI 변경은 client library 사용에 영향 없음 (Data API 정상). Storage 성능 개선은 이미지 많은 이벤트/파트너 목록에 긍정적 |
| Flutter | 3.41.5 (Feb 2026) | Multi-window support (실험적), Design System 모듈화 (Material/Cupertino 분리 패키지), Asset 플랫폼별 번들링, Linux merged threads | Design System 모듈화는 장기적으로 minglit_kit 디자인 시스템과 Flutter Material 업데이트 독립 가능. Asset 번들링으로 앱 크기 최적화 가능 (출시 후 P3) |
| Deno | 2.7.1 (Mar 27, 2026) | tsgo 기반 타입 체킹 대폭 가속, `deno audit` 의존성 보안 검사, V8 14.2 업그레이드 | Edge Function 개발 시 타입 체킹 속도 향상. `deno audit`로 EF 의존성 보안 검사 가능 — audit-security에 유용 |

### 🏪 경쟁/유사 서비스 동향

#### Tinder — IRL Events + AI 매칭 (2026.03, [출처](https://techcrunch.com/2026/03/12/tinder-tries-to-lure-people-back-to-online-dating-with-irl-events-virtual-speed-dating/))
- **Events 탭** 베타 출시 (LA, 5~6월): 큐레이션된 로컬 이벤트(볼링, 도예, 레이브 등)에서 매치와 오프라인 만남
- **Virtual Speed Dating**: 3분 영상 채팅 기반 스피드 데이팅
- **Chemistry AI**: 카메라롤 스캔 + Q&A로 일일 매치 큐레이션, 스와이프 피로도 감소
- **🔑 밍릿 시사점**: Tinder가 "이벤트 기반 오프라인 만남"으로 전환 중 — 이는 **밍릿의 핵심 가치 제안과 정확히 동일**. 밍릿이 먼저 출시하면 선점 효과, 늦으면 Tinder의 자본력에 밀릴 수 있음. **7월 출시 일정이 전략적으로 매우 중요**

#### Bumble — 신뢰도 시스템 (2026.02, [출처](https://techcrunch.com/2026/02/26/bumble-adds-ai-powered-photo-feedback-and-profile-guidance-tools/))
- **Accountability Score**: 대화 중단 패턴 추적 → 점수 하락. 고점수자에게 'Reliable Communicator' 뱃지
- **AI Photo Feedback**: 프로필 사진 품질/진정성 피드백
- **Suggest a Date**: 대화 정체 시 오프라인 만남 제안 기능 (캐나다 테스트)
- **🔑 밍릿 시사점**: 이벤트 참가자의 "노쇼" 문제에 대응할 수 있는 신뢰도 시스템 아이디어. 밍릿의 trust-and-verification 2-layer 모델과 결합 가능

#### Hinge — Safety Check-ins (2026)
- 위치 데이터 + AI 컨시어지를 활용한 데이트 중 안전 확인 알림
- **🔑 밍릿 시사점**: 이벤트 당일 참가자 안전 확인은 출시 후 고려 가능 (P3)

#### 국내 — 비긴즈 AI 매칭 ([출처](https://www.venturesquare.net/1056034))
- 사람인 비긴즈: 외모 → 가치관/라이프스타일 기반 매칭 전환, AI 사진 진단, 프로필 요약
- 소모임: 500만+ 다운로드, 관심사 기반 자동 추천 강화
- **🔑 밍릿 시사점**: 국내 시장도 "외모 → 가치관/관심사" 매칭 트렌드. 밍릿의 이벤트 기반 만남은 이 트렌드와 자연스럽게 부합 — 같은 이벤트에 관심 있다는 것 자체가 가치관 신호

### 🚧 기능 완성도 (출시 기준)

IA/메뉴 구조 대비 코드 확인 결과:

| 기능 | IA 정의 | 구현 | 상태 | 비고 |
|------|--------|------|------|------|
| 홈 / 이벤트 목록 | ✅ | ✅ | 완료 | Realtime 구독 포함 |
| 이벤트 상세 + 신청 | ✅ | ✅ | 완료 | 결제 플로우 포함 |
| 검색 | ✅ | ✅ | 완료 | PGroonga 기반 |
| 마이페이지 | ✅ | ✅ | 완료 | |
| 내 티켓 | ✅ | ✅ | 완료 | 오늘 이벤트 배너 + 과거/예정 섹션 |
| 매칭 투표 | ✅ | ✅ | 완료 | EventNow 바텀시트 Phase 3 내장 |
| 이벤트 리뷰 화면 | ✅ (Phase 5) | ❌ | **미구현** | TODO(mark) #665 — 이벤트 종료 후 리뷰 화면 네비게이션 없음 |
| 큐레이션 목록 | ✅ | ✅ | 완료 | |
| 파트너 상세/이벤트 | ✅ | ✅ | 완료 | |
| 알림 센터/설정 | ✅ | ✅ | 완료 | minglit_kit 공유 |
| 개인정보/차단 관리 | ✅ | ✅ | 완료 | |
| 체크인 (파트너) | ✅ | ✅ | 완료 | 스마트 이벤트 선택 로직 |
| 정산 (파트너) | ✅ | ✅ | 완료 | |
| RLS→EF 마이그레이션 | 📋 계획됨 | ❌ | **Phase 1 미시작** | 21개 테이블 대상, 12개 신규 EF 필요 |

**핵심 갭**: 
1. **이벤트 리뷰 (#665)** — 이벤트 종료 후 사용자 피드백 루프가 끊겨 있음. 출시 전 필수.
2. **RLS→EF 전환** — 보안 강화 목적. 출시 전 최소 high-risk 테이블(social_repository)은 전환 필요.

### 💡 신규 기능 제안

#### 1. 참가자 신뢰도 점수 (Attendance Score)

**배경**: Bumble의 Accountability Score + 밍릿의 기존 trust-and-verification 2-layer 모델에서 착안. 이벤트 플랫폼의 가장 큰 문제는 **노쇼(no-show)** — 티켓 구매 후 불참하면 파트너 매출 손실, 다른 참가자 경험 저하.

**제안**: 
- 이벤트 참석/노쇼 이력을 추적하여 참가자별 신뢰도 점수 산출
- 체크인 시스템(이미 구현됨)의 데이터를 활용 — 추가 인프라 최소
- 높은 점수 유저에게 "단골 참가자" 뱃지 → 파트너가 우선 수락 가능
- 반복 노쇼 유저에게 경고 → 일정 횟수 이상 시 예약 제한

**기대 효과**: 
- 파트너: 노쇼율 감소 → 매출 안정성
- 유저: 신뢰도 높은 참가자끼리 매칭 품질 향상
- 플랫폼: 리텐션 + 재구매율 상승

**적용 난이도**: 보통 (체크인 데이터 이미 있음, 점수 계산 로직 + UI 뱃지 추가)
**긴급도**: 다음 분기 (출시 후 데이터 축적 필요)

**참고**: [Bumble Accountability Score](https://techcrunch.com/2026/02/26/bumble-adds-ai-powered-photo-feedback-and-profile-guidance-tools/), [Tinder Safety](https://www.ubergizmo.com/2026/03/tinder-ai-matchmaking/)

#### 2. 이벤트 기반 매칭 강화 — "같은 이벤트 관심" 시그널 활용

**배경**: Tinder가 Events 탭을 출시하며 "이벤트에서 만남"을 핵심 전략으로 전환 중. 밍릿은 이미 이벤트 기반이지만, 현재 매칭은 이벤트 당일 투표 방식. **이벤트 전** 단계에서 관심사 시그널을 활용하지 않고 있음.

**제안**:
- "이 이벤트에 관심 있는 사람" 목록을 이벤트 상세에서 (익명 프로필로) 노출
- 같은 이벤트에 반복 참여하는 유저 간 "자주 만남" 하이라이트
- 이벤트 검색 시 "비슷한 취향의 사람이 N명 참여 예정" 소셜 프루프 표시

**기대 효과**:
- 이벤트 전환율(상세 → 신청) 향상 — 소셜 프루프 효과
- 매칭 투표 전에 관심도 형성 → 매칭 품질 향상
- Tinder Events와의 차별점: 밍릿은 "이미 이벤트 중심"이므로 더 자연스러운 경험

**적용 난이도**: 보통 (pgvector 추천 인프라 이미 있음, UI 추가 필요)
**긴급도**: 지금 (7월 출시 전 차별화 포인트)

**참고**: [Tinder Events Tab](https://techcrunch.com/2026/03/12/tinder-tries-to-lure-people-back-to-online-dating-with-irl-events-virtual-speed-dating/)

### 🔧 기술 추천

#### 1. `deno audit` Edge Function 보안 검사 도입

**현재 문제**: EF 의존성 보안 검사가 체계적으로 이루어지지 않음 (audit-security 수동 검토)
**제안**: Deno 2.6+의 `deno audit` 명령을 CI에 추가하여 EF 의존성 취약점 자동 검사
**기대 효과**: EF 의존성 보안 자동화, audit-security 워커 부담 감소
**적용 난이도**: 쉬움 (CI yaml에 step 1개 추가)
**참고**: [Deno 2.6 Release](https://deno.com/blog/v2.6)

### 📈 업계 트렌드 요약

1. **오프라인 전환 가속**: Tinder(Events 탭), Bumble(Suggest a Date) 모두 "앱→오프라인" 전환에 집중. 밍릿의 이벤트 기반 모델이 업계 메가트렌드와 정확히 일치 — **타이밍이 좋다**
2. **AI 개인화 보편화**: 2026년 모바일 앱은 AI-native 설계가 표준. 밍릿의 pgvector 추천은 좋은 기반이나, 실시간 컨텍스트(시간대, 위치, 이전 참여 패턴) 반영은 출시 후 강화 필요
3. **신뢰/안전 경쟁**: 본인 인증 → 행동 기반 신뢰도로 진화. 밍릿의 Identity+Qualification 2-layer가 업계 선도적이나, 행동 데이터(참석률) 레이어 추가 검토 필요
4. **UX 트렌드**: 예측적 UI (다음 행동 예측), 미니멀 인터페이스, 제스처 네비게이션이 2026 주류 ([출처](https://uxpilot.ai/blogs/mobile-app-design-trends))

---

*이 리포트는 pm-staff 자동 실행으로 생성되었습니다.*

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-04-04

2026-03-30 리포트. 확인 완료.
