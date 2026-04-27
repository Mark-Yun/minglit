---
source_url: https://github.com/Mark-Yun/minglit/issues/1137
captured_at: 2026-04-07
issue_number: 1137
state: closed
labels: [report-exec, needs-arch]
author: Mark-Yun
title: "📊 PM Strategic Update — 2026-04-07: Trust Badge UI (당근모임 대응 전략)"
---

# 📊 PM Strategic Update — 2026-04-07: Trust Badge UI (당근모임 대응 전략)

> Issue #1137 · closed · created 2026-04-07T08:07:45Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1137

## Body

Scheduler: pm-exec-report-gemini

## 🎯 Strategic Deep Dive: Trust Badge UI (당근모임 대응 전략)

오늘자 PM 보고서(#1133)의 후속 조치로, 당근모임(YoY +125% 성장)에 대응하기 위한 **'Hard Trust' 시각화** 전략 스펙을 제안합니다.

### 1. 배경
당근모임은 '하이퍼로컬 + 매너온도'라는 강력한 Soft Trust 자산을 가지고 있습니다. Minglit은 이에 맞서 플랫폼이 직접 검증한 '데이터 기반의 Hard Trust'를 시각화하여 프리미엄 소셜 매칭 시장에서의 우위를 점해야 합니다.

### 2. [P1] Trust Badge UI 설계 (Draft)
- **신규 스펙 위치**: `docs/features/trust-badge/spec.md`
- **핵심 메커니즘**:
    1. **Identity (Base Layer)**: 본인확인 완료 시 🛡️ 아이콘 노출.
    2. **Qualification (Add-on Layer)**: 직장/학력 등 파트너 인증 완료 시 ✨ 아이콘으로 업그레이드.
    3. **Reliability (Activity Layer)**: 출석률 95% 이상 시 💎 엘리트 배지 부여.
- **Trust Sheet**: 배지 클릭 시 해당 유저가 인증한 항목(예: 삼성전자 재직, 서울대 졸업 등)을 투명하게 공개하여 신뢰 근거 제공.

### 3. 기대 효과
- **전환율**: 자격 인증 유도를 통해 플랫폼 내 '신뢰 자산' 축적 가속화.
- **안전성**: 불투명한 소셜 매칭 시장에서 '검증된 연결'이라는 브랜드 포지셔닝 강화.

---

## 🚀 액션 아이템

| # | 담당 | 액션 |
|---|------|------|
| 1 | `needs-uiux` | 등급별 아이콘 및 'Trust Sheet' 바텀 시트 디자인 |
| 2 | `needs-arch` | Layer 3(출석률 등) 통계 데이터 캐싱 전략 수립 |
| 3 | `needs-swe` | `minglit_kit` 공통 위젯 구현 |

---

*Spec drafted by pm-exec-report-gemini. 2026-04-07.*
*Related: #1133 (PM Report — 2026-04-07)*

## Comments (5)

### Comment 1 — @Mark-Yun on 2026-04-07

🤖 **needs-uiux-claude-1** 작업 시작합니다.

### Comment 2 — @Mark-Yun on 2026-04-07

🤖 **needs-uiux-gemini-1** 작업 시작합니다.

### Comment 3 — @Mark-Yun on 2026-04-07

## 🤖 **needs-uiux-claude-1** UX 리뷰 및 디자인 제안

### Trust Badge wireframe 완료

PR #1139 에서 Trust Badge UI wireframe을 제출했습니다.
브라우저에서 바로 확인 가능: `docs/features/trust-badge/wireframe.html`

### 디자인 개요 (6개 스크린)

| # | 스크린 | 핵심 |
|---|--------|------|
| 1 | Badge 시스템 개요 | 3-tier 소개 (온보딩/교육) |
| 2 | 프로필 카드 | 이름 옆 인라인 배지 |
| 3 | 참가자 목록 | 배지별 시각적 위계 |
| 4 | Trust Sheet (Tier 2) | 인증 항목 바텀시트 |
| 5 | Trust Sheet (Tier 3) | 엘리트 + 활동 지표 |
| 6 | 이벤트 카드 | 피드에서 신뢰 정보 |

### 3-Tier 배지 설계

- **Tier 1 인증됨**: outlined purple pill — 본인인증만 완료한 기본 상태
- **Tier 2 자격인증**: solid purple pill — 직장/학력 등 파트너 인증 추가
- **Tier 3 엘리트**: gradient purple→gold with glow — 95%+ 출석률 + 자격인증

### UX 의견

1. **Trust Sheet가 핵심 차별점**입니다. 당근의 '매너온도'는 주관적 피드백이지만, Trust Sheet는 파트너가 직접 확인한 객관적 데이터를 보여줍니다. 이 투명성이 프리미엄 포지셔닝의 근거가 됩니다.

2. **이벤트 카드의 "참가자 62%가 자격인증 완료" 지표**는 전환율에 직접 영향을 줄 것으로 보입니다. 신뢰도 높은 이벤트를 한눈에 식별할 수 있게 해줍니다.

3. **주의**: Elite 배지의 gradient 처리는 앱 전체 톤과 이질감이 없도록 Flutter 구현 시 세밀한 조정이 필요합니다.

### 다음 단계

이 이슈는 `report-exec` 라벨이 함께 붙어 있어 전략적 방향에 대한 사람의 승인이 필요합니다. UX 측 wireframe은 준비되었으므로 `needs-uiux`를 제거합니다. 승인 후 `needs-arch` → `needs-swe` 순서로 진행하면 됩니다.

### Comment 4 — @Mark-Yun on 2026-04-07

🤖 **needs-uiux-claude-1** PR #1139 머지 완료. Trust Badge wireframe이 dev에 반영되었습니다. 전략 승인 후 `needs-arch` → `needs-swe` 순서로 진행해주세요.

### Comment 5 — @Mark-Yun on 2026-04-07

🤖 **needs-uiux-gemini-1** 작업 완료.

### 작업 결과
1. **기능 명세서**: [spec.md](docs/features/trust-badge/spec.md) 작성. 3단계 신뢰 계층 (Verified, Certified, Elite) 정의.
2. **디자인 가이드**: [ui-ux-design.md](docs/features/trust-badge/ui-ux-design.md) 작성. 레벨별 아이콘 및 Trust Sheet 구조 정의.
3. **와이어프레임**: [wireframe.html](docs/features/trust-badge/wireframe.html) 작성.

### 다음 단계 (Handover to Architect)
- 유저별 신뢰 등급 산출 로직 및 인증 내역 스냅샷 조회를 위한 DB/API 설계 부탁드립니다.
- PR: #1145 (Merged)
