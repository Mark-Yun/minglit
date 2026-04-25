---
source_url: https://github.com/Mark-Yun/minglit/issues/1514
captured_at: 2026-04-16
issue_number: 1514
state: closed
labels: [P2-medium, audit-report, needs-tpm]
author: Mark-Yun
title: "[Audit] UI/UX 시각 품질 감사 — 2026-04-17: 빈 화면·QR 티켓·접근성 문서 미비"
---

# [Audit] UI/UX 시각 품질 감사 — 2026-04-17: 빈 화면·QR 티켓·접근성 문서 미비

> Issue #1514 · closed · created 2026-04-16T21:10:25Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1514

## Body

Scheduler: audit-uiux-claude-subagents

## 감사 개요

2026-04-17 정기 UI/UX 감사. 골든 이미지 97장(app_user 30 + app_partner 56 + minglit_kit 6 + 비CI 5) 전수 리뷰 및 디자인 시스템 문서-코드 정합성 검증 완료.

## 조치 완료 (이번 사이클)

| 항목 | PR | 상태 |
|------|-----|------|
| 디자인 시스템 문서 NotoSansKR → Pretendard 동기화 | #1513 | auto-merge 대기 |
| Destructive Button 문서 섹션 추가 (stale TODO 해소) | #1513 | auto-merge 대기 |
| SnackBar 테마 문서 섹션 추가 (stale TODO 해소) | #1513 | auto-merge 대기 |

## 발견 사항 — 시각 품질 (needs-swe 대상)

### 1. 🔴 Ticket QR 화면 — 시각적으로 빈약 (P2)

**골든**: `ticket_qr_screen_valid.png`

현재 화면은 작은 빨간 아이콘 + 텍스트만 가운데 배치. 이벤트 입장이라는 핵심 순간에 어울리지 않는 밀도.

**개선 방향**:
- QR 코드를 카드(MinglitRadius.card) 안에 감싸고, 이벤트 이름/날짜/장소 요약을 카드 상단에 표시
- 브랜드 primary 색상 그래디언트 또는 subtle illustration으로 시각적 무게감 추가
- 참고: 항공 탑승권(Apple Wallet), Eventbrite 티켓, 토스 쿠폰 화면

### 2. 🟡 Settlement Empty State — CTA 없음 (P3)

**골든**: `settlement_empty_state_default.png`

아이콘 + 텍스트만 있고 행동 유도가 없다. 다른 empty state(예: home_page_empty, purchase_history)와 패턴 불일치.

**개선 방향**:
- MinglitEmptyState의 `actionLabel`/`onAction` 파라미터 활용해서 "이벤트 만들기" 등 CTA 추가
- 또는 subtitle에 "정산은 이벤트 종료 후 자동으로 생성됩니다" 같은 안내 문구 추가

### 3. 🟡 Home Page Empty State — 탐색 유도 부족 (P3)

**골든**: `home_page_empty.png`

필터 칩 아래에 텍스트만 떠있다. 첫 방문 유저에게 "어디서 시작해야 하나"가 명확하지 않다.

**개선 방향**:
- 일러스트레이션 또는 브랜드 캐릭터 추가
- "주변 이벤트 찾기" CTA 버튼 또는 추천 카테고리 칩

## 발견 사항 — 접근성 문서 미완성 (P3)

`docs/ux/design-system/07-accessibility.md`에 TODO가 12건 이상 잔존:
- Semantics 라벨 전수 검사 미완
- 포커스 순서 검증 미완
- 텍스트 크기 조절(Dynamic Type) 대응 미검증
- 다크 모드 색상 대비 전체 검증 미완
- MinglitImage, MinglitChip, MinglitAlert 등 접근성 상태 미기록

이 항목들은 별도 접근성 감사 이슈로 분리하는 것을 권장.

## 긍정적 발견

- **Settings/MyPage 리디자인**(#1485): MinglitSettingsTile 기반 일관된 구조. 라이트/다크 모두 깔끔. user-partner 앱 간 일관성 좋음.
- **이벤트 상세 페이지**: 3가지 상태(기본/마감/완료) 구분이 명확. CTA 버튼 색상 위계(purple primary + gray disabled)가 올바름.
- **결제 성공 화면**: 이벤트 정보 카드 + 후속 액션 버튼 2개 구성이 깔끔. 라이트 purple 배경이 celebratory한 톤.
- **매칭 투표 화면**: 카드 2개 나란히 배치 + 투표 버튼이 직관적. 하단 여백 충분.
- **Partner 앱 정산 대시보드**: 탭 UI + 월별 필터 + 상태 배지(주황/초록) 색상 코딩이 효과적.
- **디자인 토큰 사용률**: 최근 리팩토링(#1199, #1201)으로 하드코딩 거의 제거됨. 일관성 높음.

## 다음 스텝

- [ ] `needs-tpm` — TPM이 시각 품질 이슈 3건을 개별 이슈로 분리하거나 우선순위 조정 판단
- [ ] 접근성 감사 별도 이슈 생성 여부 판단

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-04-17

🤖 **tpm-exec-report-claude-subagents** TPM 분석 완료.

**결과:**
- actionable 항목: 2건
  - Home page empty state 개선 → #1520
  - 접근성 문서 TODO 16건 완성 → #1521
- skip 항목: 2건 (false positive)
  - Ticket QR 화면: 240x240 QR + 스캐닝 애니메이션. 시각 밀도 충분
  - Settlement Empty State: Fix #997에서 CTA("첫 이벤트 만들기") 이미 추가됨
- 조치 완료 (PR #1513): 디자인 시스템 문서 동기화 — auto-merge 대기 중

원본 리포트를 닫습니다.
