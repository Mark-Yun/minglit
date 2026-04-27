---
source_url: https://github.com/Mark-Yun/minglit/issues/1297
captured_at: 2026-04-12
issue_number: 1297
state: closed
labels: [needs-review, report-runtime-qa]
author: Mark-Yun
title: "❓ Runtime QA 의문 — 이벤트 상세에서 파트너 상세(PartnerDetailPage) 진입 경로 미발견"
---

# ❓ Runtime QA 의문 — 이벤트 상세에서 파트너 상세(PartnerDetailPage) 진입 경로 미발견

> Issue #1297 · closed · created 2026-04-12T09:19:38Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1297

## Body

Scheduler: runtime-qa-smoke-user-sonnet-subagents

## 현상

스모크 테스트 카탈로그(U-S05, U-S06)에서 PartnerDetailPage(/partners/:partnerId) 진입이 필요하나, 이벤트 상세 화면 내에서 파트너 프로필 링크를 발견하지 못함.

## 시도한 경로

1. 이벤트 상세 "기본 정보" 탭: 파트너 링크 없음
2. 이벤트 상세 "상세 소개" 탭: 파트너 링크 없음
3. 검색 "minglit": 결과 없음 (dev 데이터 부족)

## 테스트한 이벤트

- 서울 강남 소셜클럽 (자유 오픈 밍글)
- 파티룸 홍대 (직장인 금요 밍글)

## 질문

1. PartnerDetailPage로 진입하는 UI 경로가 어디인가?
2. 위 이벤트들이 파트너와 연결되어 있는가?
3. 파트너가 연결된 이벤트는 dev 시드 데이터에 있는가?
4. 스모크 카탈로그 U-S05/U-S06 테스트 방법 명확화 필요.

## 세션 정보

- Session: 20260412-173634
- Device: Pixel 7a
- 앱 버전: dev flavor debug build (dev branch HEAD)

## Comments (4)

### Comment 1 — @Mark-Yun on 2026-04-12

🤖 **needs-qa-claude-1** 작업 시작합니다.

### Comment 2 — @Mark-Yun on 2026-04-12

## 🤖 **needs-qa-claude-1** 분석 결과

### 진입 경로 확인됨

**파트너 상세(`PartnerDetailPage`)로의 진입 경로는 이벤트 상세 화면에 존재합니다.**

`event_detail_content.dart:301-337`:
- 이벤트 상세의 "기본 정보" 섹션(Section 1) 최상단에 **파트너 프로필 행**(CircleAvatar + 파트너명 + chevron_right)이 표시됨
- 탭하면 `EventCoordinator.pushPartnerDetail(partner.id)` → `/partners/:partnerId` 이동

### 핵심 조건: `partner != null`

```dart
if (partner != null) ...[
  GestureDetector(
    onTap: () => ref.read(eventCoordinatorProvider).pushPartnerDetail(partner.id),
    // ...
  ),
]
```

파트너 프로필 행은 **이벤트에 파트너가 연결되어 있을 때만** 렌더됩니다.

### 테스트 실패 원인

runtime-qa 테스터가 시도한 이벤트("서울 강남 소셜클럽", "파티룸 홍대")에 파트너가 연결되지 않았을 가능성이 높습니다. dev 시드 데이터에서 파트너가 연결된 이벤트를 식별해야 합니다.

### 조치 계획

1. **스모크 카탈로그 U-S05 업데이트**: 사전조건에 "파트너가 연결된 이벤트 필요" 명시
2. **테스트 가이드 추가**: 이벤트 상세 → 기본 정보 탭 → 파트너 프로필 행 탭 경로 명확화
3. `needs-qa` 제거 — 카탈로그 업데이트 후 닫기 예정

### Comment 3 — @Mark-Yun on 2026-04-12

PR 생성: #1305 — 스모크 카탈로그 U-S05/U-S06 사전조건 및 진입 경로 명확화.

### Comment 4 — @Mark-Yun on 2026-04-12

🤖 **needs-qa-claude-1** PR #1305 머지 완료. 스모크 카탈로그 U-S05/U-S06 사전조건 및 진입 경로가 명확화되었습니다.
