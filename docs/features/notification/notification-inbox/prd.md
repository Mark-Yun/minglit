# PRD: 알림 인박스 (Notification Inbox)

## Summary

푸시 알림을 놓친 유저가 앱 안에서 과거 알림을 재확인할 수 있는 인박스 + 미읽음 배지 + 페이지네이션 / 카테고리 / 상대 시간 등 UX 강화. 현재 화면 / API / 라우트는 구현돼 있으나 entry point (app_user 벨 배지) 부재와 UX 완성도가 부족하다.

## Motivation / Problem to Solve

- 이슈 #1688 — 알림 인박스 UX gap (실제 구현은 부분 완료, 진입점 / UX 완성도가 부족)
- app_user 홈 벨 아이콘에 미읽음 배지 부재 → 유저가 새 알림 인지 불가 (페르소나 "지수")
- 페이지네이션 미지원 (`limit: 20` hardcoded) → 헤비 유저(페르소나 "민재")의 과거 알림 접근 불가
- 카테고리 시각 구분 부재 → 이벤트 / 매칭 / 티켓 / 시스템 알림이 혼재되어 인지 부하
- 절대 시간(`MM/dd HH:mm`) 만 표시 → "방금 전" / "3시간 전" 등 최근 알림의 시간 감각 저하
- 파트너 헤비 유저(페르소나 "현수") — 앱 포그라운드 상태에서 새 알림 실시간 반영 부재

## Goals

### Target Users

- **이벤트 신청자 (지수)**: 푸시를 놓치는 일반 유저 — 벨 배지로 알림 인지 + 인박스에서 재확인
- **헤비 유저 (민재)**: 주당 15 ~ 20건 알림 누적 — 페이지네이션 + 안 읽음 필터로 효율적 탐색
- **파트너 (현수)**: 앱을 켜놓고 대기 중인 운영자 — 실시간 인박스 갱신

### Key Goals

- **P0 (v1)**: app_user 홈 벨 아이콘에 미읽음 배지 + `NotificationBellWithBadge` 공용 위젯으로 partner 와 통합
- **P0 (v1)**: 무한 스크롤 페이지네이션 (limit 20, offset 기반)
- **P0 (v1)**: 알림 카드 UX 강화 (카테고리 아이콘 + 상대 시간 + 미읽음 좌측 바)
- **P1 (v1)**: 에러 / 실패 처리 강화 (markAsRead 실패 rollback, 삭제 실패 재조회, 재시도 UI)
- **P1 (v1)**: 빈 상태 일러스트 + CTA, 삭제 확인 다이얼로그
- **P2 (v2)**: Supabase Realtime — 앱 포그라운드일 때 새 알림 자동 prepend
- **P2 (v2)**: 카테고리 필터 탭 (이벤트 / 매칭 / 티켓 / 시스템) — notification-worker 카테고리 주입 후

### Non-Goals

- 알림 전송 자체 변경 (notification-worker 카테고리 주입은 별도 후속 이슈)
- 푸시 / DM / 채팅 통합 (Meetup unified updates 패턴은 스코프 과다)
- Slack / Linear 스타일 mention / reaction 그룹핑 (밍릿 알림 카테고리 단순)
- Flagged / Archive 액션 (Instagram 패턴 — 본 PRD 스코프 과다)
- Glassmorphism 등 2026 비주얼 트렌드 (스코프 과다)

## Product Principles

1. **인지 우선**: 벨 배지로 새 알림 유무를 한눈에 인지, 인박스 진입은 부담 없게.
2. **카테고리 시각화**: 텍스트가 아닌 아이콘으로 카테고리 구분, 한눈에 분류 가능하게.
3. **시간 감각**: 최근 알림은 상대 시간 ("방금 전" / "N시간 전"), 7일 이상은 절대 시간 (`yyyy-MM-dd`).
4. **실패 복구**: optimistic update 는 실패 시 rollback + 사용자 인지 가능한 피드백 (스낵바).

## Technical Approach

- **화면**: 홈 AppBar 벨 아이콘 (배지 포함) + 인박스 화면 (페이지네이션 + 필터 + 카드 개량)
- **저장**: `user_notifications` 테이블 (기존). 스키마 변경 없음. notification-worker 의 `notification_category` enum 주입 일관성만 후속 정비.
- **외부 의존성**: Supabase Realtime (v2), 기존 알림 인박스 API (`getNotifications` / `markAsRead` / `markAllAsRead` / `deleteNotification`)
- **가드 / 정책**: 인박스 RLS 로 본인 알림만 조회 (기존), deep_link 검증 (`startsWith('/')` 기존 적용)

## User Journey

### Scenario 1: 미읽음 인지 → 인박스 진입 → 딥링크 (CUJ 1-x)

푸시를 놓친 유저가 앱 진입 → 홈 벨 배지로 새 알림 인지 → 탭 → 인박스 → 알림 탭 → deep_link 이동.

### Scenario 2: 누적 알림 탐색 (CUJ 2-x)

헤비 유저가 인박스 진입 → 무한 스크롤로 과거 알림 로드 → (v2) 안 읽음 / 카테고리 필터로 탐색.

### Scenario 3: 실시간 / 에러 / 빈 상태 (CUJ 3-x)

파트너가 앱 포그라운드 대기 → 새 알림 자동 prepend (v2). markAsRead / 삭제 실패 시 rollback + 스낵바. 신규 유저 빈 상태에서 CTA 로 이벤트 둘러보기 진입.

## Data Flow

### Scenario 1

푸시 수신 → `user_notifications` 레코드 + FCM → 유저 푸시 dismiss → 앱 진입 → 홈 벨 배지에 미읽음 카운트 노출 → 탭 → 인박스 (초기 20건 fetch) → 알림 탭 → markAsRead optimistic + deep_link push → 인박스 재방문 시 읽음 처리 확인

### Scenario 2

인박스 진입 → 초기 20건 → 스크롤 하단 도달 → `getNotifications(limit: 20, offset: loaded)` → 다음 20건 prepend → (v2) 필터 탭 변경 시 클라이언트 측 필터 또는 query param 추가

### Scenario 3

(v2) 인박스 진입 → `user_notifications` realtime channel 구독 → INSERT 이벤트 시 prepend → 백그라운드 진입 시 unsubscribe. markAsRead 실패 시 → state rollback + 스낵바 "읽음 처리에 실패했어요". 빈 상태 → 일러스트 + CTA → 홈 이동

## KPIs / Success Metrics

- **벨 아이콘 탭 CTR**: 푸시 받은 유저 중 인박스 진입률 — baseline + 15%p
- **딥링크 전환**: 인박스 → 딥링크 진입 / 인박스 진입 ≥ 40%
- **무한 스크롤 발동**: offset ≥ 20 fetch 이벤트 수 — 헤비 유저 분류 시그널
- **markAllAsRead 사용률**: 활성 유저 중 / 주 — 참고 지표
- **실시간 (v2) 자동 prepend**: realtime 활성 유저 중 새 알림 발생 시 자동 노출 비율 ≥ 90%

## Launch Strategy

- **v1**: 배지 + 페이지네이션 + UX 개량 + 빈 상태 + 삭제 확인 + 에러 처리 — 한 번에 ship
- **v2**: Realtime (StreamNotifier 전환) + 카테고리 필터 (notification-worker 카테고리 주입 선행) — 별도 이슈

## References

- **Instagram (Professional Inbox)**: Unread 필터 패턴 (Flagged / Archive 는 스코프 과다)
- **Meetup (2025 UX redesign)**: 알림 빈도 조절 — 밍릿은 카테고리 설정으로 사전 차단
- **Material Design 2026**: 적게 보내고 인박스에서 재조회 + Avatar on right 패턴
- **Slack / Linear**: 카테고리 그룹핑 — 밍릿은 아이콘 배지 (탭 보다 단순)
- 관련 이슈: #1688
