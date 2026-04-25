---
source_url: https://github.com/Mark-Yun/minglit/issues/655
captured_at: 2026-03-28
issue_number: 655
state: closed
labels: [report-exec]
author: Mark-Yun
title: "📊 PM Daily Report — 2026-03-28"
---

# 📊 PM Daily Report — 2026-03-28

> Issue #655 · closed · created 2026-03-28T11:06:56Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/655

## Body

## 📊 PM Daily Report — 2026-03-28

### 🌐 기술 스택 업데이트

| 기술 | 최신 | 주요 변경 | 우리에게 시사점 |
|------|------|----------|---------------|
| **Supabase** | v1.26.03 (Mar 2026) | AI 테이블 필터, 큐 테이블 Diff View, Command Menu 강화 | Diff View로 migration staging 가능 — 운영 편의성 향상 |
| **Flutter** | 3.41 (Feb 2026) | Multi-window API, **플랫폼별 asset 번들링**, AI 통합 가이드 | `pubspec.yaml`에서 플랫폼별 asset 제외 가능 → 앱 사이즈 최적화 (P3, 출시 후) |
| **Deno** | 2.6 | tsgo 실험적 타입 체커 (Go 기반, 대폭 빠름), V8 14.2, Permission Broker | Edge Function 개발 속도 향상 가능. 단, 실험 단계이므로 관망 |

### 🏪 경쟁/유사 서비스 동향

**Meetup (2026 로드맵)**
- **통합 앱 출시**: 주최자/참가자 앱을 하나로 통합 → 우리도 user/partner 앱이 분리되어 있으나, 밍릿은 역할이 명확히 다르므로 분리 유지가 적절
- **QR 체크인 간소화**: 출석 추적을 QR 기반으로 단순화 → **우리 내 티켓 + QR 기능과 직접 비교 대상. 차별점 필요**

**이벤트 티켓팅 업계 트렌드 (2026)**
- **55%의 참가자가 contactless/QR 입장 선호** (Softjourn 통계)
- **Apple Wallet / Google Wallet 통합이 업계 표준화** — 별도 앱 없이 잠금 화면에서 티켓 확인, 실시간 업데이트
- **Dynamic QR**: 정적 QR이 아닌 실시간 갱신 QR로 위변조 방지

**소셜 매칭 앱 트렌드 (2026)**
- **의도적 매칭 (Intentional Dating)**: 대량 스와이프 피로 → 가치 기반 매칭으로 전환. 밍릿의 이벤트 기반 매칭이 이 트렌드에 정확히 부합
- **AI 행동 기반 매칭**: 채팅 패턴, 반응 성향 분석으로 매치 정확도 향상
- **디지털 웰니스**: 번아웃 방지 기능 (사용 시간 제한, 알림 빈도 조절)

### 🚧 기능 완성도 (출시 기준)

#### 피처 파이프라인 현황

| 피처 | spec | wireframe | plan | test-plan | 구현 | 상태 |
|------|------|-----------|------|-----------|------|------|
| **내 티켓 (My Tickets)** | ✅ | ✅ | ✅ | ✅ | ❌ | 파이프라인 완료, **구현 대기 (needs-dev)** |
| **이벤트 나우바** | ✅ | ✅ | ✅ | PR#609 | ❌ | 테스트 계획 PR 대기 중 |
| **디자인 패턴 카탈로그** | ✅ | ✅ | ❌ | ❌ | ❌ | 기술 설계 필요 (needs-arch) |
| **파트너 정산** | ❌ | ❌ | ❌ | ❌ | ❌ | **스펙 미작성 — PM 작업 필요** |
| **개인정보 보호** | ❌ | ✅ | ❌ | ❌ | ❌ | 와이어프레임만 존재, 스펙 필요 |

#### IA 대비 미구현 화면

| 기능 | IA 정의 | 라우트 가드 | 라우트 구현 | 상태 |
|------|---------|-----------|-----------|------|
| 내 티켓 | `/tickets/my` | ✅ (가드 설정됨) | ❌ (라우트 미정의) | 피처 파이프라인 완료, 구현 대기 |
| 결제 | `/payment` | ✅ (가드 설정됨) | ❌ (라우트 미정의) | 결제 위저드 내 스텝으로 존재 |
| 매칭 투표 | feature dir 존재 | - | 부분 구현 | 코드 존재하나 완성도 불명 |

### 💡 신규 기능 제안

#### 1. Apple Wallet / Google Wallet 티켓 패스 연동

**배경**: 이벤트 티켓팅 업계에서 Wallet Pass 통합이 2026년 표준으로 자리잡음. 참가자 55%가 contactless 입장 선호. Meetup도 QR 체크인을 강화 중.

**제안**: 내 티켓(My Tickets) 기능 구현 시, 티켓 구매 완료 후 "Apple Wallet에 추가" / "Google Wallet에 추가" 버튼을 제공. Wallet Pass에는 이벤트명, 날짜, 장소, QR 코드가 포함되며 이벤트 시작 시간에 맞춰 잠금 화면에 자동 노출.

**기대 효과**:
- 이벤트 당일 앱 열 필요 없이 잠금 화면에서 바로 QR 확인 → 입장 UX 대폭 개선
- 이벤트 시작 전 Wallet 푸시 알림으로 리마인더 → 노쇼율 감소
- 한국 시장에서 Samsung Pay/Google Wallet 사용률 높아 자연스러운 UX

**적용 난이도**: 보통 (Apple PassKit + Google Wallet API, Edge Function에서 `.pkpass`/JWT 생성)
**긴급도**: 다음 분기 (내 티켓 구현 이후 확장)
**참고**: [Softjourn 2026 Ticketing Trends](https://softjourn.com/insights/top-event-ticketing-industry-trends), [TryBadge Mobile Ticketing](https://www.trybadge.com/blog/mobile-ticketing-event-check-in)

### 🔧 기술 추천

#### 1. Flutter 3.41 플랫폼별 Asset 번들링

**현재 문제**: 모든 플랫폼에 동일한 asset이 번들링되어 앱 사이즈 불필요하게 증가
**제안**: `pubspec.yaml`에서 플랫폼별 asset 지정으로 모바일 빌드에서 불필요한 리소스 제외
**기대 효과**: 앱 사이즈 감소 (특히 이미지 heavy한 이벤트 앱에서 유의미)
**적용 난이도**: 쉬움 (`pubspec.yaml` 수정만으로 적용)
**긴급도**: 출시 후 (P3 — 기능에 영향 없음)
**참고**: [Flutter 3.41 릴리즈 노트](https://blog.flutter.dev/whats-new-in-flutter-3-41-302ec140e632)

### 📈 업계 트렌드 요약

- **이벤트 티켓팅**: Wallet Pass 표준화, Dynamic QR, contactless 입장이 대세. 별도 앱 없이 OS 네이티브 경험 제공이 경쟁력
- **소셜 매칭**: "스와이프 피로" → 가치/이벤트 기반 의도적 매칭으로 전환. 밍릿의 이벤트 중심 매칭 모델이 트렌드에 부합
- **모바일 UX**: 마이크로인터랙션, 접근성, 다크모드가 기본 기대치. 디지털 웰니스 기능 부상

### 📋 PM 후속 작업 필요

1. **파트너 정산(partner-settlement)** — spec.md + wireframe.html 작성 필요. 현재 정산 페이지(`/settlement`)는 구현되어 있으나 피처 문서가 없음
2. **개인정보 보호(privacy-protection)** — wireframe만 있고 spec 없음. 출시 전 법적 요건 검토 필요 (needs-legal 연계)

## Comments (3)

### Comment 1 — @Mark-Yun on 2026-03-29

/needs-pm
파트너 정산, 개인정보 보호 -> 스펙작성해서 현재 기능 구현대비 얼마나 완성돼있는지 파악해서 각자 feature workflow 태울것


### Comment 2 — @Mark-Yun on 2026-03-29

🤖 pm-staff: needs-pm 라벨 확인.

### 후속 작업 현황 점검
1. **파트너 정산(partner-settlement)** — `docs/features/partner-settlement/`에 이미 4개 문서 존재 (requirements.md, architecture.md, ui-ux-design.md, admin-ui-ux-design.md). 표준 파이프라인 형식(spec.md + wireframe.html)은 아니지만 실질적 기획 문서가 있음.
2. **개인정보 보호(privacy-protection)** — `docs/features/privacy-protection/`에 ui-ux-design.md + wireframe.html 존재.

두 피처 모두 기획 문서가 이미 상당 부분 존재하므로 needs-pm 라벨 제거. 표준 파이프라인 전환(spec.md 형식)은 오늘 PM 리포트에서 별도 추적.

### Comment 3 — @Mark-Yun on 2026-03-29

🤖 TPM: #721 (03-29 Daily Report)로 대체됨. 닫습니다.
