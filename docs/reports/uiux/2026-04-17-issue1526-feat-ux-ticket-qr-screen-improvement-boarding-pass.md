---
source_url: https://github.com/Mark-Yun/minglit/issues/1526
captured_at: 2026-04-17
issue_number: 1526
state: closed
labels: [report-exec, needs-swe]
author: Mark-Yun
title: "feat(ux): 티켓 QR 화면 입장 경험 개선 (Boarding Pass 메타포 적용)"
---

# feat(ux): 티켓 QR 화면 입장 경험 개선 (Boarding Pass 메타포 적용)

> Issue #1526 · closed · created 2026-04-17T00:49:20Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1526

## Body

Scheduler: needs-uiux-gemini-1

### 배경
현재 티켓 QR 화면은 흰 배경에 QR 코드만 노출되어, 유저가 이벤트를 '소유'하고 '입장'한다는 핵심 순간의 시각적 밀도가 낮습니다. 또한 입장 직전 필요한 맥락 정보(이벤트명, 시간 등)가 부족하여 불안감을 줄 수 있습니다.

### 개선 제안
항공권/입장권 형태의 **Boarding Pass 메타포**를 적용하여 시각적 완성도와 브랜드 아이덴티티를 강화합니다.

**주요 개선 사항:**
1. **티켓 카드 디자인**: 절취선(Perforation) 효과가 적용된 카드 UI 채택.
2. **맥락 정보 배치**: 카드 상단에 이벤트 제목, 일시, 장소를 요약 배치하여 편의성 증대.
3. **브랜드 컬러 적용**: Primary Gradient를 활용하여 서비스 아이덴티티 강조.
4. **안정성 문구**: '사용 가능' 상태 배지 및 위조 방지 주의 문구 추가.

### 산출물 (Wireframe)
- [Wireframe 확인하기](https://github.com/Mark-Yun/minglit/blob/main/docs/features/ticket-qr-improvement/wireframe.html)

### 다음 단계
-  — Mark 승인 후  단계로 진행 희망.

## Comments (11)

### Comment 1 — @Mark-Yun on 2026-04-17

/needs-pm 굿 아이디어 이벤트 정보만 담는게 아니라 진짜 보딩패스 느낌이 나는 감성 대한항공 비행기 티켓이나 아시아나 비행기 티켓의 디자인을 오마쥬 했으면 좋겠음

디자인은 진짜로 티켓 느낌이 나야함. 그래야 사람들이 입장하면서 진짜 입장 승인 받는 다는 느낌을 가져야함

### Comment 2 — @Mark-Yun on 2026-04-17

🤖 **needs-pm-claude-1** 작업 시작합니다.

Mark의 피드백 반영하여 실제 항공 보딩패스 디자인 레퍼런스를 조사하고, spec.md + wireframe.html을 작성하겠습니다.

### Comment 3 — @Mark-Yun on 2026-04-17

🤖 **needs-pm-claude-1** PR 생성 완료: #1530

Mark의 피드백 반영하여 대한항공/아시아나 보딩패스 디자인을 오마주한 spec.md + wireframe.html 작성했습니다.

### 핵심 변경 사항
- **4영역 보딩패스 구조**: 브랜드 헤더 → 이벤트 정보(DATE/VENUE) → 절취선 노치 → QR stub
- **항공편 스타일 레이아웃**: 좌측 날짜/시간, 우측 장소 — 대한항공 보딩패스 형식 차용
- **상태 표시**: 오늘 이벤트 시 `● BOARDING` (녹색 pulse), 미래 `CONFIRMED`, 종료 `USED`
- **절취선 디테일**: semicircle cutout 노치 + dashed line — 진짜 티켓 느낌의 핵심
- **와이어프레임 5개 화면**: AS-IS 대비, BOARDING, CONFIRMED, USED, 로딩 skeleton

`report-exec` 라벨 유지합니다. Mark 승인 후 `needs-uiux`로 진행 예정.

### Comment 4 — @Mark-Yun on 2026-04-17

🤖 **needs-pm-claude-1** 사이클 종료.

**완료된 작업:**
- spec.md 작성 (대한항공/아시아나 보딩패스 오마주, 4영역 구조, 4명 유저 시뮬레이션)
- wireframe.html ��성 (5개 화면: AS-IS, BOARDING, CONFIRMED, USED, skeleton)
- PR #1530 생성 + auto-merge 활성화 + needs-review ���벨 부착

**현재 상태:**
- `report-exec` 라벨 유지 중 — Mark 승인 대기
- PR #1530 CI 통과 (ci-result ✅), 코드 리뷰 대기 중
- Mark 승인 후 `needs-uiux` 이슈 생성하여 다음 단계로 진행 예정

### Comment 5 — @Mark-Yun on 2026-04-17

/needs-uiux 승인

### Comment 6 — @Mark-Yun on 2026-04-17

🤖 **needs-uiux-gemini-1** 작업 시작합니다.

### Comment 7 — @Mark-Yun on 2026-04-17

🤖 **needs-uiux-gemini-1** UX 리뷰 완료.

PR #1530의 보딩패스 메타포 적용을 승인합니다. 

### 리뷰 요약
1. **메타포 적절성**: 항공 보딩패스 디자인을 차용하여 '입장'이라는 경험에 특별한 감성을 더함. AS-IS 대비 시각적 밀도와 신뢰도가 대폭 향상됨.
2. **디테일**: 절취선(Perforation) 노치와 'BOARDING' 펄스 상태 표시 등 물리적 감각을 살린 디테일이 훌륭함.
3. **정보 계층**: DATE/VENUE를 명확히 분리하여 입장 직전 유저가 필요한 정보를 즉시 확인할 수 있게 함.

### 구현 단계 권고 사항 (Polishing)
- **VIP 대응**: 티켓 타입에 따라 헤더 그라데이션을 골드/실버 등으로 변형하여 프리미엄 경험 강화 제안.
- **반응형 대응**: 소형 기기(iPhone SE 등)에서 카드가 잘리지 않도록 레이아웃 대응 필요.
- **햅틱 피드백**: 티켓 화면 진입 시  햅틱을 트리거하여 '티켓을 수령하는' 감각 부여 제안.

UX 관점에서 승인하며, 테스트 계획 수립을 위해 QA 리드에게 넘깁니다. 
에 해당 패턴을 공식 추가할 예정입니다.

### Comment 8 — @Mark-Yun on 2026-04-17

🤖 **needs-qa-claude-1** 작업 시작합니다.

### Comment 9 — @Mark-Yun on 2026-04-17

🤖 **needs-qa-claude-1** 테스트 계획 완료.

PR #1531 생성했습니다. 39 test cases (P1: 24, P2: 12, P3: 3) — 5계층 테스트 전략.

`needs-qa` 제거, `needs-swe` 부착하여 구현 단계로 넘깁니다. test-plan.md 기반으로 구현 + 테스트 작성 부탁드립니다.

### Comment 10 — @onlyhyeok-cmd on 2026-04-17

🤖 **needs-review-codex-1** 상태 정정합니다.

PR #1531은 테스트 계획 문서만 머지된 상태인데, PR 본문의 `Closes #1526` 때문에 이슈가 자동 종료되었습니다. 이슈의 최종 목표인 Boarding Pass UI 구현은 아직 완료되지 않았으므로 이슈를 다시 열었습니다.

현재 라벨 기준으로 `needs-swe` 구현 단계가 계속 진행되면 됩니다.

### Comment 11 — @Mark-Yun on 2026-04-17

🤖 **needs-swe-sonnet-1** 작업 시작합니다.
