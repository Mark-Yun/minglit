---
source_url: https://github.com/Mark-Yun/minglit/issues/2063
captured_at: 2026-04-30
issue_number: 2063
state: open
labels: [audit-report]
author: Mark-Yun
title: "[Audit] 파트너 앱 더보기 — CircleAvatar+NetworkImage 직접 사용 (MinglitAvatarImage 미적용)"
---

# [Audit] 파트너 앱 더보기 — CircleAvatar+NetworkImage 직접 사용 (MinglitAvatarImage 미적용)

> Issue #2063 · open · created 2026-04-30 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2063

## Body

Scheduler: audit-uiux-claude-subagents

## 발견

PR #2035 (app_user 5 call site 마이그레이션), PR #1936 (MinglitAvatarImage MDS 신설)에서 유저 앱은 모두 정리됐지만, **파트너 앱은 원래 스코프에서 제외**되어 있었습니다. 이번 감사에서 파트너 앱 더보기 화면의 핵심 프로필 카드에 동일 안티패턴이 남아 있는 것을 확인했습니다.

## 위치

| 파일 | 라인 | 설명 |
|------|------|------|
| `apps/app_partner/lib/src/features/more/more_page.dart` | 222–231 | 파트너 프로필 카드(가게/대표 아바타) |

```dart
// 현재 — anti-pattern
CircleAvatar(
  radius: 24,
  backgroundColor: colorScheme.primaryContainer,
  backgroundImage: avatarUrl != null
      ? NetworkImage(avatarUrl!)
      : null,
  child: avatarUrl == null
      ? Icon(Icons.store, color: colorScheme.primary)
      : null,
),
```

## 영향

#1936에서 이미 정리된 그대로:
- **캐시 미적용** — rebuild·재진입 때마다 풀 해상도 URL 재다운로드. 파트너의 더보기 페이지는 진입 빈도가 높아 누적 트래픽·배터리 부담.
- **에러 폴백 미작동** — avatarUrl이 있지만 토큰/네트워크 실패 시 `onBackgroundImageError`가 없어 빈 원으로 표시. 가게 아이콘 폴백(`Icons.store`)이 화면에 안 나옴.
- **Supabase URL transform 우회** — 향후 #1918류의 transform 정책 변경 시 이 call site만 별도 hotfix가 필요. MinglitImage가 약속한 "단일 update surface" 가치가 깨짐.

## 권장 조치

```dart
MinglitAvatarImage(
  radius: 24,
  url: avatarUrl,
  fallbackIcon: Icons.store,
  backgroundColor: colorScheme.primaryContainer,
  fallbackIconColor: colorScheme.primary,
)
```

`MinglitAvatarImage`는 이미 MDS(`shared/packages/mds/core/lib/src/ui/widgets/common/minglit_avatar_image.dart`)에 있고 user 앱에서 검증되어 그대로 재사용 가능.

## 비대상 (검증 완료)

다음 파일들도 `CircleAvatar`가 등장하지만 NetworkImage를 쓰지 않는 아이콘/이니셜 아바타라 마이그레이션 대상이 아님:
- `app_partner/.../checkin/manual/manual_checkin_sheet.dart:340`
- `app_partner/.../application/event_application_detail_page.dart:128`, `event_application_manage_widgets.dart:174`
- `app_partner/.../member/partner_member_list_page.dart:106`
- `app_partner/.../party/event/widgets/event_application_list_view.dart:87`, `event_application_review_dialog.dart:68`
- `app_user/.../home/widgets/event_now_phases/checked_in_content.dart:132`
- `app_user/.../event/admission/wizard_widgets.dart:54`

`apps/app_partner/.../party/widgets/party_image_editor.dart:182,193`은 `DecorationImage` 기반 파티 배너 프리뷰로 use case가 다름 — 별도 판단 필요.

## 회귀 방지

- `apps/app_user/test/src/common/widgets/minglit_avatar_image_test.dart` 패턴을 partner more_page에도 위젯 테스트로 추가.
- (선택) `CircleAvatar.*backgroundImage:.*NetworkImage` 패턴을 막는 lint 또는 CI grep guard를 추가하면 재발 차단.

## 우선순위 의견

- **P2** 권장. 크래시·기능 결손 아님. 성능·UX 일관성 이슈.
- 기대 효과: 파트너 더보기 화면 반복 진입 시 트래픽/배터리 절약, 아바타 로드 실패 시 가게 아이콘 폴백이 정상 노출.

## 이전 컨텍스트
- 원본 이슈: #1936 (closed 2026-04-28, 5개 user 앱 call site 한정 스코프)
- 마이그레이션 PR: #2035, #1936
