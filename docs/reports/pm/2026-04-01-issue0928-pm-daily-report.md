---
source_url: https://github.com/Mark-Yun/minglit/issues/928
captured_at: 2026-04-01
issue_number: 928
state: closed
labels: [P3-low, report-exec]
author: Mark-Yun
title: "📊 PM Daily Report — 2026-04-01"
---

# 📊 PM Daily Report — 2026-04-01

> Issue #928 · closed · created 2026-04-01T08:07:31Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/928

## Body

## 📊 PM Daily Report — 2026-04-01

### 🌐 기술 스택 업데이트 (External Research)
| 기술 | 최신 버전 | 우리 버전 | 주요 변경 및 시사점 |
|------|----------|----------|-------------------|
| **Supabase** | Mar 2026 Update | v2.x | **AI-Native Context 지원**: 모든 문서를 AI 에이전트용 Markdown으로 제공 중. 우리도 피처 스펙을 Markdown으로 철저히 관리하여 AI 유지보수성을 높여야 함. **Storage 성능 14.8x 향상**: 대규모 이미지 처리에 유리해짐. |
| **Flutter** | 3.41 (Stable) | 3.4x | **Impeller 2.0 기본화**: 모든 플랫폼에서 셰이더 스터터링 없이 부드러운 UI 제공. **Wasm Production Ready**: 웹 버전 성능 향상 기회. |
| **Deno** | v2.1+ | v2.0 | **Node.js 호환성 완성**: EF에서 npm 라이브러리 사용이 더 원활해짐. |

### 🏪 경쟁/유사 서비스 동향
- **Bumble & Hinge (AI for Fatigue)**: "AI 프로필 가이드"와 "실시간 프롬프트 피드백"으로 유저의 '입력 피로'를 줄여줌. 밍릿도 파티 신청 시 자기소개 입력을 AI가 도와주는 기능 고려 필요.
- **Partiful (Gen Z 소셜 픽)**: "Text Blast"와 "App-less RSVP"가 강점. 앱 설치 없이 웹에서 RSVP만 하고 나중에 앱을 깔게 하는 '점진적 전환' 전략이 유효함.
- **Luma (Immediate Payout)**: Eventbrite의 늦은 정산에 지친 주최자들이 Luma의 즉시 정산(Stripe 연동)으로 이동 중. 우리도 파트너 유입을 위해 정산 주기를 공격적으로 단축할 필요가 있음.

### 💡 신규 기능 제안

#### 1. "Minglit RSVP Link" (유저 획득 가속)
**배경**: 신규 유저가 앱을 깔기 전에도 파티 정보를 보고 RSVP를 할 수 있게 하여 전환 장벽을 낮춤. (Partiful 벤치마킹)
**제안**: 이벤트 상세 페이지의 Web-View 버전을 제공하고, SMS/카카오톡 공유 시 '간편 수락' 버튼 포함.
**기대 효과**: CAC(고객 획득 비용) 절감 및 바이럴 루프 형성.
**적용 난이도**: 보통 (Next.js 랜딩 페이지 연동 필요)

#### 2. "Zero-Click Check-in" (유저 경험 혁신)
**배경**: 파티 당일, 유저가 현장에 도착했을 때 티켓을 찾기 위해 앱을 뒤지는 번거로움 해소.
**제안**: 지오펜싱(Geofencing)과 시간 조건을 결합하여, 행사 시간/장소 근접 시 홈 화면 상단에 '입장 Pass'를 자동으로 노출 (Predictive UI).
**기대 효과**: 현장 혼잡도 감소 및 유저 만족도 향상.
**적용 난이도**: 쉬움 (기존 위치 권한 및 Event Now Bar 활용)

### 🔧 기술 추천

#### 1. "AI-Ready Feature Metadata"
**현재 문제**: 프로젝트가 커지면서 새로운 AI 워커가 컨텍스트를 파악하는 데 시간이 걸림.
**제안**: 모든 피처 구현 완료 시 `docs/features/{name}/context.md`를 자동/수동 생성하여 AI 에이전트가 즉시 읽을 수 있게 함.
**기대 효과**: 개발 및 감사 워커의 생산성 비약적 향상.
**참고 링크**: [Supabase AI-Native Docs](https://docs.supabase.com)

### 🏗️ 기능 완성도 (출시 기준)
| 기능 | IA 정의 | 구현 | 상태 |
|------|--------|------|------|
| 매칭 투표 UI | ✅ | ✅ | 구현됨 (`matching_vote_screen.dart`) |
| QR 체크인 | ✅ | 🚧 | 컨트롤러는 있으나 플레이스홀더 상태 |
| 개인정보 설정 | ✅ | ✅ | 최근 머지됨 (`PrivacyPage`) |
| 파트너 정산 관리 | ✅ | 🚧 | 화면은 있으나 자동화 여부 확인 필요 |


## Comments (1)

### Comment 1 — @Mark-Yun on 2026-04-04

2026-04-01 리포트. 확인 완료.
