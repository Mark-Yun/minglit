---
source_url: https://github.com/Mark-Yun/minglit/issues/1688
captured_at: 2026-04-21
issue_number: 1688
state: closed
labels: [enhancement, P2-medium, report-exec]
author: Mark-Yun
title: "[Notification] 알림 인박스 화면 구현 — 과거 알림 확인 경로 부재"
---

# [Notification] 알림 인박스 화면 구현 — 과거 알림 확인 경로 부재

> Issue #1688 · closed · created 2026-04-21T07:44:31Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1688

## Body

## 문제

`user_notifications` 테이블에 notification-worker가 매 푸시마다 레코드를 저장하고 있고, `NotificationRepository.getNotifications()` / `markAsRead()` / `markAllAsRead()` / `deleteNotification()` API도 전부 구현돼 있음. **그러나 어떤 화면에서도 호출하지 않음** → 사용자가 푸시를 놓치면 지난 알림을 앱에서 다시 볼 방법이 없음.

## 근거

- `shared/packages/minglit_kit/lib/src/data/repositories/notification_repository.dart:44-74` — 구현 존재
- `apps/app_user/lib/` / `apps/app_partner/lib/` 하위에 `user_notifications` 참조 0건 (검색 결과)

## 수정안

### 1. 화면 추가
`app_user`, `app_partner` 양쪽 모두:
- 경로: `/notifications` (또는 홈/마이 탭 하위)
- 리스트: 시간순 정렬, 읽음/미읽음 구분 스타일
- 탭 → `markAsRead()` + `deep_link`가 있으면 해당 경로로 이동
- 스와이프 삭제 → `deleteNotification()`
- 우상단 "모두 읽음" → `markAllAsRead()`

### 2. 진입 경로
- 홈 AppBar 또는 My 탭에 종 아이콘 + 미읽음 배지 (count)
- 미읽음 카운트는 `user_notifications.is_read = false` 개수 (실시간 구독 권장: Supabase Realtime)

### 3. Riverpod provider
```dart
final notificationListProvider = FutureProvider.autoDispose.family(...);
final unreadCountProvider = StreamProvider.autoDispose(...);
```

## 관련
- #1686 / #1687 권한·초기화 이슈가 선행 (푸시 자체가 안 뜨는 문제 먼저 해결)

## Comments (3)

### Comment 1 — @Mark-Yun on 2026-04-21

/needs-pm 워크플로우 진행

### Comment 2 — @Mark-Yun on 2026-04-21

🤖 **needs-pm-claude-1** 작업 시작합니다.

알림 인박스 화면 구현 관련 피처 기획 (spec + wireframe) 착수 예정. 먼저 경쟁사 리서치 + 현재 IA 분석 후 `docs/features/notification-inbox/` 에 산출물 생성하겠습니다.

### Comment 3 — @Mark-Yun on 2026-04-21

🤖 **needs-pm-claude-1** 1단계 완료 — spec + wireframe PR 제출

## 산출물

- **PR**: #1694
- **파일**:
  - `docs/features/notification-inbox/spec.md`
  - `docs/features/notification-inbox/wireframe.html` (6 화면)

## 핵심 조사 결과

이슈 본문은 "어떤 화면에서도 호출하지 않음"이라고 기술돼 있으나 **실제로는 상당 부분 구현돼 있음**:

| 요소 | 상태 |
|------|------|
| `/notifications` 라우트 (양쪽 앱) | ✅ |
| `NotificationListScreen` (읽음/삭제/모두읽음/딥링크) | ✅ |
| `NotificationRepository` CRUD | ✅ |
| `HomeCoordinator.pushNotificationCenter()` | ✅ |
| app_partner 홈 벨 배지 | ✅ |
| **app_user 홈 벨 배지** | ❌ (P1 gap) |
| **페이지네이션** | ❌ (P1 gap, limit 20 hardcoded) |
| **카테고리 시각화 / 상대 시간 / 실시간 / 필터 / 빈 상태 개선 / 삭제 확인** | ❌ (P2~P3 gap) |

## 승인 필요 — report-exec 전환

PR 머지 후 `needs-pm` → `report-exec` 라벨 전환합니다. 아래 4가지 판단이 필요합니다:

1. **v1 범위 묶기**: 6개 개선(배지 + 페이지네이션 + 카테고리 아이콘 + 상대 시간 + 빈 상태 + 삭제 확인)을 한 번에? 아니면 배지/페이지네이션만 먼저 ship?
2. **실시간(G5)**: v2로 미뤄도 OK? 파트너 현수 페르소나가 실시간 니즈 가장 강함
3. **notification-worker 카테고리 주입**: 별도 이슈로 분리 vs 현재 범위 포함
4. **빈 상태 일러스트**: ux-designer에게 asset 요청 vs emoji 임시본으로 v1 진행

## 후속 파이프라인

승인 후 `needs-uiux` → `needs-qa` → `needs-swe` 순으로 진행.

v1 구현 이슈 6개 (의존성 순): 벨 배지(공용 위젯 승격) → 페이지네이션 → 카드 UX → 빈 상태 → 에러/실패 처리 → 삭제 확인
