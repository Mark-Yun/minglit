---
source_url: https://github.com/Mark-Yun/minglit/issues/922
captured_at: 2026-03-31
issue_number: 922
state: closed
labels: [P3-low, report-exec]
author: Mark-Yun
title: "📊 PM Daily Report — 2026-03-31"
---

# 📊 PM Daily Report — 2026-03-31

> Issue #922 · closed · created 2026-03-31T08:08:11Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/922

## Body

## 📊 PM Daily Report — 2026-03-31

### 🌐 기술 스택 업데이트 (March 2026)
| 기술 | 최신 버전 | 주요 변경 및 밍릿 시사점 |
|------|----------|-----------------------|
| **Supabase** | 2026-03 | **PrivateLink** 지원 시작. PII(개인정보)를 다루는 우리 특성상 보안 강화 기회. `anon` 키 OpenAPI 노출 차단됨(보안 강화). |
| **Flutter** | 3.41 | **Content-sized views** 도입. 웹/앱 임베딩 시 레이아웃 최적화 용이. **Agentic UI** 로드맵 발표(사용자 의도 예측 UI). |
| **Deno** | 2.7.9 | **Deno.cron()** 기본 지원. 현재 `pg_cron` + HTTP 호출 방식을 네이티브 Deno 로직으로 전환하여 안정성 향상 가능. |

### 🏪 경쟁/유사 서비스 동향
- **Bumble** — "Suggest a Date" 기능 출시. 매칭 후 대화 정체를 방지하기 위해 오프라인 만남을 유도하는 '넛지' 제공 → **우리도 파트너의 다른 이벤트를 추천하는 방식으로 적용 가능.**
- **Hinge** — "Face Check™" (Liveness Verification) 도입. AI 생성 가짜 프로필 차단. 밍릿의 "신뢰 시스템(Layer 1)"에 생체 인증 추가 고려 필요.
- **Eventbrite** — "Off-Script Energy" 트렌드 보고서. 정형화된 파티보다 스폰테니어스하고 로우스테이크(Low-stakes)한 모임 선호도 급증 → **번개 모임이나 가벼운 소모임 기능 강화 필요.**

### 💡 신규 기능 제안

#### 1. Agentic Icebreaker (사용자 의도 예측 아이스브레이킹)
**배경**: 매칭 성공 후 대화 시작의 어려움(Chat Stall) 해결 필요.
**제안**: Supabase Edge Functions + OpenAI를 활용, 두 유저의 공통 관심사나 참여했던 이벤트 키워드를 조합하여 첫 마디를 제안하는 기능.
**기대 효과**: 매칭 후 실제 대화 전환율(Conversation Rate) 30% 이상 향상 기대.
**적용 난이도**: 보통 (Edge Function 추가)

#### 2. Liveness Trust Badge (생체 기반 신뢰 인증)
**배경**: Hinge의 Face Check 트렌드 및 유저 신뢰도 강화.
**제안**: 본인인증(Layer 1) 단계에서 카메라를 활용한 실시간 생체 인증(Liveness Check) 추가. 인증 완료 시 프로필에 특수 배지 부여.
**기대 효과**: 플랫폼 내 허위 계정 배제 및 여성 유저 안전감 증대.
**적용 난이도**: 보통 (외부 SDK 또는 ML kit 연동)

### 🚧 기능 완성도 및 제언 (출시 기준)
| 기능 | 상태 | 제언 |
|------|------|------|
| **매칭 투표 UI (app_user)** | ❌ 미구현 | 백엔드 RPC(`cast_match_vote`)는 준비되었으나 유저가 투표할 화면이 없음. P0 최우선 구현 필요. |
| **체크인 관리 (app_partner)** | ⚠️ 보완 필요 | `CheckinPlaceholderPage`가 사실상 구현되어 있으나 이름이 Placeholder임. `CheckinEntryPage`로 리네이밍 및 UI 폴리싱 필요. |
| **신고 시스템** | ⚠️ 미비 | 기본적인 저장 로직은 있으나 관리자 심사 및 제재 워크플로우가 부재함. |

### 🔧 기술 추천
- **Deno Native Cron**: `pg_cron` 의존도를 낮추고 Edge Function 내에서 복잡한 비즈니스 로직(알림 발송 타이밍 계산 등)을 직접 제어할 것을 추천.
- **Supabase PrivateLink**: 향후 엔터프라이즈 파트너(대기업/기관) 유치 시 데이터 보안 요구사항 충족을 위해 도입 검토 필요.

### 📈 업계 트렌드 요약
- **Soft Socializing**: 무거운 네트워킹보다 취미/활동 중심의 가벼운 모임이 2026년 주류.
- **Tactile UI**: Neomorphism의 재해석을 통한 프리미엄하고 만져질 듯한(Tactile) 디자인이 대세.

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-04-04

2026-03-31 리포트. 확인 완료.
