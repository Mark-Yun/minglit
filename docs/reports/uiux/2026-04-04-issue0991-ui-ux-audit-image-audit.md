---
source_url: https://github.com/Mark-Yun/minglit/issues/991
captured_at: 2026-04-04
issue_number: 991
state: closed
labels: [P2-medium, audit-report, needs-review]
author: Mark-Yun
title: "[UI/UX Audit] 2026-04-04 골든 이미지 기반 디자인 품질 감사"
---

# [UI/UX Audit] 2026-04-04 골든 이미지 기반 디자인 품질 감사

> Issue #991 · closed · created 2026-04-04T09:21:12Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/991

## Body

Scheduler: audit-uiux-claude-subagents

## 1. 개요 및 비즈니스 임팩트 (Executive Summary)

**감사 일자:** 2026-04-04 | **대상:** app_user, app_partner, minglit_kit 전체 골든 이미지
**담당 디자이너:** audit-uiux-claude-subagents
**핵심 가치:** #HeuristicEvaluation #Accessibility #MinglitKit_Standards

- **전반적 건강도 진단:** 개선필요
- **예상 비즈니스 임팩트:** Empty state 개선으로 신규 유저 온보딩 이탈률 감소, 파트너 정산 페이지 안내 추가로 CS 문의 감소 기대

### Top 3 시급 과제

1. **Empty State 부재** — app_user 로그아웃 마이페이지, 검색 페이지, app_partner 정산 페이지의 빈 상태가 아이콘+텍스트 1줄로만 구성. 유저에게 다음 행동을 안내하지 않음
2. **Dark Mode 대비율 부족** — app_user 홈 skeleton loader, 뱃지 텍스트 등에서 WCAG AA 미달 가능성
3. **Event Card 만석 상태 시각 피드백 부족** — 게이지만으로 "만석"을 전달하며, 텍스트/뱃지 등 접근성 보조 수단 없음

---

## 2. 10대 휴리스틱 상세 분석

### H1. 시스템 상태의 가시성 — 심각도 3

**위반:** Event card 만석 상태에서 참여 불가를 시각적으로 명확히 전달하지 않음. 게이지 3칸 채움만으로는 "마감" 의미가 불명확.

**해결 제안:** "만석" 뱃지 오버레이 추가 또는 이미지 desaturation으로 시각적 불가 상태 표현. 접근성(스크린 리더) 대응도 포함.

### H6. 재인지보다 인지 — 심각도 3

**위반:** app_user 홈 이벤트 카드의 색상 코딩(마젠타/오렌지/시안 뱃지)에 대한 범례가 없음. 사용자가 색상 의미를 기억해야 함.

**해결 제안:** 첫 사용 시 툴팁으로 색상 의미 안내하거나, 뱃지에 텍스트 라벨을 병기.

### H8. 미학적이고 최소한의 디자인 — 심각도 2

**위반:** 파트너 앱 대시보드의 "이번 주 성과" 섹션에서 데이터 없을 때 "-" 표시가 3개 나열됨. 정보 없음을 효과적으로 전달하지 못하고 시각적 노이즈만 발생.

**해결 제안:** 데이터 없을 때 별도 안내 문구로 대체하거나, 아직 데이터가 쌓이지 않았음을 설명하는 empty state 패턴 적용.

---

## 3. 디자인 시스템 건전성

### 토큰 준수 — 양호 (개선 중)

- PR #972, #971에서 하드코딩된 alpha/spacing/radius 값을 디자인 토큰으로 전환 완료
- `MinglitSpacing`, `MinglitRadius`, `MinglitOpacity` 토큰 체계가 잘 정립됨
- **Gap:** Shadow/elevation 토큰 미비. 오버레이가 flat opacity로만 구현되어 깊이감 부족
- **Gap:** Interactive state 토큰(hover, pressed, disabled) 미정의

### 컴포넌트별 평가

| 컴포넌트 | 평점 | 비고 |
|----------|------|------|
| EventCard (minglit_kit) | 4.5/5 | 토큰 준수 우수, skeleton 구현 모범적. 만석 상태 시각 피드백만 보강 필요 |
| Partner Home (onboarding) | 3.5/5 | 체크리스트 구조 명확, 프로그레스바 직관적. 하단 프로세스 설명 섹션 좋음 |
| Partner Home (with data) | 3/5 | 대시보드 구조 ok, 성과 섹션 빈 데이터 처리 미흡 |
| Party List | 3/5 | 카드 레이아웃 기능적이나 이미지 영역이 어둡고 단조로움 |
| Settlement Empty State | 1.5/5 | 아이콘 + 텍스트 1줄만. 가이드/CTA 전무 |
| User My Page (logged out) | 1.5/5 | CTA 버튼만 덩그러니. 로그인 유도 메시지 없음 |
| User Search (empty) | 3/5 | 검색바 스타일 적절하나 빈 상태에 추천/인기 검색어 없음 |

### Dark Mode

- **app_partner:** 잘 구현됨. surface 대비, 뱃지 색상 유지 등 양호
- **app_user:** skeleton loader 대비 부족, 뱃지 텍스트 WCAG 미달 가능성

---

## 4. 인지 부하 분석

- **파트너 홈 (empty):** 온보딩 4단계 체크리스트는 적절한 정보량. 힉의 법칙 위반 없음
- **파트너 홈 (with data):** "다음 이벤트" 카드에 3개 CTA 버튼(신청 현황 보기, 이벤트 수정, 공유/홍보)이 있지만 시각적 위계가 명확하여 수용 가능
- **유저 홈 (with events):** 이벤트 카드 내 정보 밀도 적절. 단, 색상 코딩 범례 없이 뱃지가 남용되면 인지 부하 증가 우려

---

## 5. 개선 로드맵

### Quick Wins (저비용 고효율)

- [ ] **Settlement empty state에 안내 문구 추가**: "이벤트 운영 후 정산이 생성됩니다" + "첫 이벤트 만들기" CTA 버튼
- [ ] **User logged-out 마이페이지 개선**: 로그인 유도 헤드라인 + 서비스 혜택 요약
- [ ] **Event card 만석 뱃지 추가**: 게이지 옆에 "만석" 텍스트 표시
- [ ] **Dark mode skeleton loader 대비율 수정**: 최소 #4A4A4A 이상으로 밝기 조정

### Deep UX Redesign

- [ ] **Shadow/Elevation 토큰 시스템 구축**: flat opacity → Material elevation 기반 깊이 체계 전환
- [ ] **Interactive state 토큰 정의**: hover, pressed, focused, disabled 상태별 토큰
- [ ] **Empty state 패턴 표준화**: 모든 빈 상태에 아이콘 + 제목 + 설명 + CTA 구조 적용 (디자인 시스템 03-patterns.md에 패턴 추가)
- [ ] **색상 코딩 범례 시스템**: 첫 사용자 온보딩 또는 설정 내 범례 제공

---

## 6. 참고

- Golden images: `apps/app_user/test/goldens/`, `apps/app_partner/test/goldens/`, `shared/packages/minglit_kit/test/goldens/`
- Design system docs: `docs/ux/design-system/`
- 관련 이슈: #448 (디자인 시스템 문서), #578 (Dialog UI), #711 (디자인 패턴 카탈로그)
- 최근 PR: #985 (consent 재설계), #972 (토큰 전환), #971 (토큰 전환)

## Comments (2)

### Comment 1 — @Mark-Yun on 2026-04-04

🤖 **needs-tpm-claude-1** 작업 시작합니다.

### Comment 2 — @Mark-Yun on 2026-04-04

🤖 **needs-tpm-claude-1** TPM 분석 완료.

## 결과

### Actionable 항목: 3건 → 이슈 생성

| 이슈 | 우선순위 | 내용 |
|------|---------|------|
| #995 | P2-medium | Dark mode skeleton loader WCAG AA 대비율 미달 |
| #996 | P2-medium | Event card 만석 상태 시각 피드백 보강 |
| #997 | P3-low | Empty state 패턴 개선 (Settlement, Search) |

### Skip 항목: 6건

| 항목 | 사유 |
|------|------|
| User logged-out 마이페이지 | **False positive** — 실제 코드 확인 결과 이미 "로그인" CTA 버튼 있음 |
| Badge 색상 코딩 범례 | MVP 단계에서 낮은 우선순위. 색상+게이지 조합으로 충분히 직관적 |
| 파트너 대시보드 "-" 표시 | TODO #519로 이미 인지됨. API 연동 대기 중 |
| Shadow/Elevation 토큰 | 디자인 시스템 부채. MVP 이후 개선 |
| Interactive state 토큰 | 디자인 시스템 부채. MVP 이후 개선 |
| Empty state 패턴 표준화 | 개별 화면 수정(#997)으로 커버. 패턴 표준화는 이후 단계 |

원본 리포트를 닫습니다.
