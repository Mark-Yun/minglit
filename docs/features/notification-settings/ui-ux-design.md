# 알림 설정 화면 — UI/UX 디자인

> **이슈**: #1689 [Notification] 알림 카테고리별 on/off 설정 UI — user_settings 연동
> **작성자**: needs-uiux-claude-1 (UX Designer)
> **작성일**: 2026-04-22
> **관련**: #1686, #1687, #1688 ([notification-inbox spec](../notification-inbox/spec.md))

## 목적

현재 `/my/notification-settings`는 **서비스 알림 / 마케팅 동의** 2개 토글뿐이다. 이벤트가 13종으로 늘어났고 인박스(#1688)까지 연결되는 지금, 카테고리별 세밀한 on/off 제어를 노출해야 유저 알림 피로도를 관리할 수 있다. 이 문서는 새 화면의 IA·컴포넌트·인터랙션·접근성 기준을 정의한다.

## 현재 구현 실태

| 요소 | 상태 | 위치 |
|------|------|------|
| 라우트 | ✅ `/my/notification-settings` 양쪽 앱 연결 | `apps/app_user/lib/src/routing/app_routes.dart`, `apps/app_partner/...` |
| 화면 | ⚠️ 2개 토글만 · legacy `SwitchListTile` | `shared/packages/minglit_kit/lib/src/features/notification/notification_settings_screen.dart` |
| Controller | ✅ Riverpod · optimistic + rollback 구현 | `.../notification_settings_controller.dart` |
| Repository | ✅ `getSettings` / `updateSettings` via `user-manage-settings` EF | `.../notification_repository.dart:77-108` |
| DB 스키마 | ⚠️ `user_settings`에 `service_notification`, `marketing_consent` 2개 컬럼만 | `supabase/migrations/20260301000005_05_schema_system.sql:56-62` |
| EF allowlist | ⚠️ 위 2개 필드만 sanitize 통과 | `supabase/functions/user-manage-settings/index.ts:111-127` |

## 설계 원칙

1. **4-tier 정보 구조** — 시스템 권한 → 서비스 마스터 → 카테고리 → 마케팅(별도 동의). 단일 flat 리스트로 던지지 않는다. 법적 의미(마케팅 동의)와 기능적 선호(카테고리)가 다름을 구조로 전달.
2. **푸시만 제어, 인박스는 유지** — 카테고리 OFF 시 **푸시만 skip**, `user_notifications` insert는 계속 진행. 설정 해제해도 놓친 알림 추적 가능 → 유저가 안심하고 OFF할 수 있음.
3. **OS 권한과 앱 설정 분리** — OS 알림 차단 상태를 배너로 명시하고, 앱 내 설정은 "OS가 허용됐을 때만 작동한다"는 전제를 숨기지 않는다.
4. **Cascade disabled, never hidden** — master OFF 시 하위 토글을 숨기지 않고 **잠금(disabled)** 처리. 유저가 자기 선택 기억을 잃지 않도록 값은 보존.
5. **법정 필수 알림 고지** — 본인확인·결제 완료 등 법정 필수는 설정과 무관하게 송신됨을 footer에 명시 (개인정보 고지 의무).
6. **기본값 전부 ON** — 첫 진입 시 누락 알림이 없도록. 마케팅만 기본 OFF.

## 정보 구조 (IA)

```
[AppBar] 알림 설정

[시스템 권한]
  • OS 알림 권한          [허용됨/거부됨] ›   → 시스템 설정 열기
  
  (거부 시) ⚠️ 권한 배너 + "설정 열기" CTA

[서비스 알림]
  • 서비스 알림 받기                      [●]    (master)
  helper: "OFF 하면 모든 서비스 알림 푸시가 꺼집니다. 인박스에는 계속 쌓입니다."

[카테고리]
  • 🎫 이벤트 신청   승인 · 거절 · 새 신청      [●]
  • 📅 이벤트 변경   일정/장소 · 취소 · 리마인드  [●]
  • 💜 매칭 결과    매칭 성사 및 상대 알림       [●]
  • ✨ 활동 알림    파트너 새 이벤트 · 유저 활동  [●]
  • ✓ 인증 알림    프로필 인증 결과           [●]
  • 💰 정산·결제    (Partner 앱만) 준비/완료/실패 [●]

[마케팅]
  • 마케팅 정보 수신   이벤트 · 할인 · 큐레이션  [ ]
  helper: "별도 동의 항목입니다. OFF해도 서비스 이용에 지장 없습니다."

[Footer]
  "법정 필수 알림(본인확인·결제 완료 등)은 위 설정과 무관하게 수신됩니다."
```

### 이벤트 타입 ↔ 카테고리 매핑

`notification-worker`는 이 매핑 테이블로 카테고리 플래그를 조회해 skip 판단한다.

| 카테고리 | 포함 이벤트 (enum) | 노출 앱 |
|---|---|---|
| 이벤트 신청 | `application_approved`, `application_rejected`, `new_application` | User + Partner |
| 이벤트 변경 | `event_updated`, `event_cancelled`, `event_reminder` | User + Partner |
| 매칭 결과 | `match_result` | User + Partner |
| 활동 알림 | `party_created`, `user_interaction` | User + Partner |
| 인증 알림 | `verification_result` | User + Partner |
| 정산·결제 | `settlement_ready`, `settlement_completed`, `settlement_failed` | **Partner only** |

이벤트 enum 위치: `supabase/migrations/20260301000001_01_extensions_enums.sql:30-40` + `20260316000005_settlement_phase5_partner_access.sql` + `20260322000008_add_match_result_enum.sql`.

## 상태별 인터랙션

### State 1 — 정상 (OS 허용 + master ON)
- 모든 카테고리 토글 활성. 개별 toggle 즉시 반영.

### State 2 — OS 권한 거부
- 최상단 warning 배너 표시 (`#FEF3C7` bg / `#78350F` text / `#FDE68A` border).
- 배너 CTA "설정 열기" → `AppSettings.openNotificationSettings()` (app_settings 패키지).
- **모든 앱 내 토글 disabled** (값 유지). 색상 알파 0.38, 스위치 알파 0.3.
- 헬퍼 텍스트: "OS 권한이 차단되어 모든 푸시 알림이 전송되지 않습니다." (error 톤).
- Lifecycle `resumed` 이벤트 시 권한 재조회 → 복귀 시 배너 자동 사라짐.

### State 3 — Master OFF
- "서비스 알림 받기" OFF → 하위 카테고리 **cascade disabled** (값 보존).
- 마케팅은 **독립**. master OFF여도 마케팅 토글 정상 동작.
- 잠긴 child tap 시 SnackBar: "서비스 알림 받기를 먼저 켜주세요".

### State 4 — 저장 실패
- Optimistic update → EF 실패 시 UI 롤백 + 상단 SnackBar "설정 저장에 실패했어요. 다시 시도해주세요."
- 기존 `NotificationSettingsController`의 rollback 패턴 재활용.

## 컴포넌트 매핑

| UI 요소 | 컴포넌트 | 비고 |
|---|---|---|
| Group 헤더 | `textTheme.labelSmall` + `onSurfaceVariant` + uppercase + 0.5px letter-spacing | 기존 my_page.dart 패턴 |
| Group 컨테이너 | `MinglitSettingsGroup` | 기존 재사용 |
| 토글 row | `MinglitSettingsTile(trailing: SettingsTileTrailing.toggle)` | **variant 확장 필요 → 아래 참고** |
| 값 표시 row (OS 권한) | `MinglitSettingsTile(trailing: SettingsTileTrailing.value, onTap: openSystemSettings)` | 기존 패턴 |
| 권한 배너 | **NEW** `OsPermissionBanner` widget | warning surface, icon + body + CTA |
| Helper text (group 하단) | Plain `Text` · `textTheme.bodySmall` · `textTheme.onSurfaceVariant` 70% | 신규 스타일 |

### ⚠️ MinglitSettingsTile variant 확장

현재 `MinglitSettingsTile`은 `height: 48` 고정 + subtitle 1-line. 이번 화면에선 카테고리 설명이 subtitle로 들어가는데 12개 카테고리 모두 1줄로 압축 시 정보 손실이 큼. 아래 둘 중 하나:

- **옵션 A (권장)**: `MinglitSettingsTile`에 `compact: bool = true` 파라미터 추가 → `false`일 때 `height: 56~64` 가변 허용 + subtitle line-height 개선.
- **옵션 B**: 새 variant `MinglitSettingsToggleTile` 추가 (height 유연).

설계 최소 수정 범위 + 재사용성을 위해 **옵션 A** 권장. 변경은 `shared/packages/minglit_kit/lib/src/ui/widgets/common/minglit_settings_tile.dart`.

## 디자인 토큰

모두 기존 `MinglitDesignTokens`·`ColorScheme` 활용. 새 토큰은 없음.

| 용도 | Light | Dark |
|---|---|---|
| Screen background | `surface` (#F9FAFB) | `surface` (dark theme) |
| Group container bg | `surfaceContainerLowest` (#FFFFFF) | `surfaceContainerHigh` |
| Divider (tile 간) | 0.5px · `outlineVariant` (#E5E7EB) | `outlineVariant` (#3D3D3D) |
| Title text | `onSurface` | `onSurface` |
| Subtitle text | `onSurfaceVariant` | `onSurfaceVariant` |
| Section header | `onSurfaceVariant` · `labelSmall` · uppercase | 동일 |
| Switch active | `colorScheme.primary` (#9900FF) · `Switch.adaptive` | 동일 |
| Disabled | 알파 0.38 (text) / 0.3 (switch) | 동일 |
| Warning banner bg | `#FEF3C7` | `#422006` |
| Warning banner text | `#78350F` | `#FCD34D` |

## 접근성 (a11y)

- 토글: `Semantics(label: title, toggled: value)` — Flutter Switch 기본으로 제공되나 라벨 명시 권장.
- Disabled 토글: `Semantics(enabled: false, hint: '서비스 알림 받기를 먼저 켜야 변경 가능')`.
- 배너: `Semantics(label: '알림 권한 경고', container: true)` 로 그룹화.
- 터치 타겟 ≥ 48×48dp. 현재 56/64px height로 여유 충족.
- 색상뿐 아니라 **위치·문구**로 상태 전달 (disabled row는 helper text + switch opacity 조합).
- 최소 폰트 12px (`bodySmall` 이상).
- 다크모드 대비율 모두 WCAG AA (4.5:1) 이상 verify 필요 — QA 체크리스트 포함.

## 구현 이슈 분할 (SWE 인계)

v1 (MVP) — 현재 이슈 #1689 하위 또는 별도 분리:

| # | 제목 | 의존성 | 복잡도 |
|---|---|---|---|
| 1 | DB: `user_settings`에 `notification_preferences JSONB` 추가 + migration | 없음 | S |
| 2 | EF `user-manage-settings`: `notification_preferences` 필드 sanitize 확장 | 1 | S |
| 3 | `NotificationRepository` / Controller: preferences getter/setter 추가 | 2 | S |
| 4 | `MinglitSettingsTile` compact=false variant | 없음 | XS |
| 5 | `NotificationSettingsScreen` 리디자인 (MinglitSettingsGroup 패턴 전환) | 3, 4 | M |
| 6 | `OsPermissionBanner` + 권한 상태 provider (`permission_handler`) | 없음 | S |
| 7 | `notification-worker`: 카테고리 매핑 + preferences 조회 skip 로직 | 1 | M |

v2:
- 시간대 방해금지(조용한 시간)
- 카테고리별 인박스 필터 딥링크 (inbox 필터 이슈 #1688 후속 통합)
- 주/월 요약 이메일

## 스키마 제안 (architect 검토 포인트)

**방안 A (컬럼 6개)**
```sql
ALTER TABLE user_settings
  ADD COLUMN notify_application boolean DEFAULT true,
  ADD COLUMN notify_event_change boolean DEFAULT true,
  ADD COLUMN notify_match boolean DEFAULT true,
  ADD COLUMN notify_activity boolean DEFAULT true,
  ADD COLUMN notify_verification boolean DEFAULT true,
  ADD COLUMN notify_settlement boolean DEFAULT true;
```
- 장점: 타입 안정성, SQL 쿼리 명확
- 단점: 카테고리 추가 시 migration 필요

**방안 B (JSONB) — 권장**
```sql
ALTER TABLE user_settings
  ADD COLUMN notification_preferences jsonb NOT NULL
  DEFAULT '{"application": true, "event_change": true, "match": true, "activity": true, "verification": true, "settlement": true}'::jsonb;
```
- 장점: 카테고리 추가 무중단, 클라이언트 변경만으로 확장
- 단점: 스키마 검증을 EF/클라이언트에서 관리

설계 재량이지만, 카테고리 구조가 변동 가능성이 있고 notification-inbox 스펙의 `notification_category` enum과도 정합을 고려하면 **방안 B 권장**.

## 체크리스트 (PR 리뷰 시)

**UX**
- [ ] 4-tier IA 유지 (시스템 / 서비스 마스터 / 카테고리 / 마케팅)
- [ ] 카테고리 아이콘 6종 컬러 일관성
- [ ] Master OFF 시 child cascade disabled
- [ ] OS 권한 거부 배너 렌더 + CTA 동작
- [ ] 잠긴 child tap 시 SnackBar 안내
- [ ] Footer 법정 알림 고지 문구 존재

**시각 품질**
- [ ] Light/Dark 모두 골든 테스트
- [ ] 다양한 폰트 크기(small~xxlarge)에서 subtitle 잘림 없음
- [ ] 카테고리 아이콘 색상 대비율 통과
- [ ] Switch active color = primary (#9900FF)

**상태 처리**
- [ ] Optimistic + rollback (기존 패턴 유지)
- [ ] Lifecycle resumed 시 OS 권한 재조회
- [ ] 저장 실패 SnackBar

**접근성**
- [ ] 터치 타겟 ≥ 48dp
- [ ] Semantics 라벨 + toggled 상태
- [ ] WCAG AA 대비율 (4.5:1) 전체 통과

**데이터**
- [ ] Partner 앱에서만 정산 카테고리 노출
- [ ] 기본값 모두 ON (마케팅 제외)
- [ ] `user_notifications` insert는 카테고리 OFF에도 유지

## Open Questions

1. **스키마**: 방안 A(boolean 6개) vs 방안 B(JSONB) — architect 판단 필요.
2. **Partner 앱 마케팅 라벨**: "마케팅 정보 수신" vs "파트너 뉴스·혜택" — PM 확인.
3. **"법정 필수"의 실제 기준**: 어느 이벤트 타입이 OFF해도 강제 송신인지 — legal-reviewer 확인.
4. **카테고리 아이콘**: 와이어프레임은 이모지. 프로덕션은 `Icons` 세트 정식 매핑 (ux-designer follow-up).

## 와이어프레임

- `wireframe.html` (이 폴더 내) — 4개 상태(정상 / OS 거부 / master OFF / Partner) 시각화.

## Workflow

- [x] ux-designer: ui-ux-design.md + wireframe.html 작성
- [ ] **Mark 승인** 불필요 (기존 화면 리디자인, 신규 피처 게이트 해당 없음)
- [ ] architect: 스키마 방안 선택 + migration
- [ ] swe: v1 이슈 #1~#7 순차 구현
- [ ] qa-lead: 골든 테스트 (4 states × 2 themes = 8 golden)
- [ ] legal-reviewer: 법정 필수 알림 기준 확인
