---
source_url: https://github.com/Mark-Yun/minglit/issues/948
captured_at: 2026-04-03
issue_number: 948
state: closed
labels: [P3-low, report-exec]
author: Mark-Yun
title: "📊 PM Daily Report — 2026-04-03"
---

# 📊 PM Daily Report — 2026-04-03

> Issue #948 · closed · created 2026-04-03T08:15:00Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/948

## Body

## 📊 PM Daily Report — 2026-04-03

### 🌐 기술 스택 업데이트
| 기술 | 최신 버전 | 우리 버전 | 주요 변경 |
|------|----------|----------|----------|
| Flutter | 4.0 / 3.41 | 3.3x (추정) | Impeller 2.0 기본 탑재 (iOS/Android 120fps), GenUI SDK (LLM 기반 UI 생성 지원) |
| Supabase | 2026.04 | 2025.12 | **Stripe Sync Engine** (SQL로 직접 결제 데이터 조회), New API Key Model (보안 강화) |
| Deno | 2.7.11 | 2.5 (LTS) | 4월 30일 LTS 종료 예정, Deno Compile (단일 바이너리 빌드) 지원 강화 |

### 🏪 경쟁/유사 서비스 동향
- **Hinge** — "Shalant" (정성) 트렌드 주도: 보이스 노트, 상세 프로필 작성 유저에게 알고리즘 가중치 부여.
- **Bumble** — "Opening Move" 개편: 여성이 질문을 던지면 남성이 먼저 답할 수 있게 하여 첫 대화의 피로도 감소.
- **Eventbrite** — "Private Event Networks": 이벤트 당일 참여자끼리만 공유하는 닫힌 소셜 피드 도입 (리텐션 핵심).

### 🚧 기능 완성도 및 공백 분석 (출시 기준)
| 기능 | IA 정의 | 현재 상태 | 분석 결과 |
|------|--------|----------|----------|
| **매칭 투표** | ✅ | ⚠️ 고립됨 | `MatchingVoteScreen`은 구현되었으나 `EventDetailPage`와 연결되지 않음 (P0) |
| **체크인 스캔** | ⚠️ Placeholder | ✅ 구현 완료 | `QRScannerScreen`이 이미 동작 중. IA 및 라우트 명칭 업데이트 필요 (P2) |
| **이벤트 피드** | ❌ 미정의 | ❌ 미구현 | 오프라인 이벤트의 현장감을 살릴 실시간 소통 창구 부재 (Hinge/Eventbrite 트렌드 반영 필요) |

### 💡 신규 기능 제안

#### 1. [P1] "Minglit Moment" (이벤트 전용 프라이빗 피드)
**배경**: Eventbrite의 Private Event Network 트렌드. 현재 밍릿은 이벤트 '신청'과 '매칭'은 있으나, 이벤트 '진행 중'의 휘발성 경험을 잡아둘 장치가 부족함.
**제안**: 이벤트 체크인 완료 후부터 종료 1시간 뒤까지 활성화되는 참여자 전용 사진/메모 공유 피드 도입.
**기대 효과**: 이벤트 현장 참여 유도, 참여자 간 아이스브레이킹 촉진, 서비스 체류 시간 증대.
**적용 난이도**: 보통 (Supabase Realtime 기반)

#### 2. [P2] "Shalant Profile" 가점 시스템
**배경**: 2026년 매칭 시장의 "귀찮음 탈피(Effort over Nonchalance)" 트렌드.
**제안**: 프로필 정보 80% 이상 입력, 목소리 인증, 또는 상세 소개글 작성 유저에게 '정성 유저' 뱃지를 부여하고 매칭 알고리즘 노출 빈도 상향.
**기대 효과**: 유저 데이터 품질 향상, 매칭 성공률 제고.
**적용 난이도**: 쉬움 (DB Trigger/Function 수준)

### 🔧 기술 추천

#### 1. Supabase Stripe Sync Engine 도입
**현재 문제**: 파트너 정산(Settlement) 로직이 복잡하고 수동 검증 단계가 많음.
**제안**: 신규 Stripe Sync를 통해 SQL로 직접 정산 상태를 확인하고 파트너 대시보드에 실시간 매출 반영.
**기대 효과**: 정산 투명성 확보, 백엔드 로직 단순화.
**적용 난이도**: 보통

### 📈 업계 트렌드 요약
- **Anticipatory UX**: 사용자가 행동하기 전(예: 목요일 저녁)에 '주말 이벤트 제안' 모듈을 상단에 배치하는 예측형 설계 대세.
- **Haptic/Micro-interactions**: 매칭 성공 시의 강렬한 햅틱 피드백을 통해 보상 심리 극대화.

---
Scheduler: pm-staff-gemini-1

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-04-04

2026-04-03 리포트. 확인 완료.
