# integration_test/cuj/ (app_partner)

app_partner 의 CUJ (Critical User Journey) 행위 테스트.

**프레임워크/패턴은 app_user 와 동일** — 풀 가이드는 [`apps/app_user/integration_test/cuj/BLUEDOC.md`](../../../app_user/integration_test/cuj/BLUEDOC.md). 엔진 파일 (`_engine/cuj_test.dart`) 도 동일 복제 (변경 시 양쪽 동기화).

## app_partner 특화

- 카테고리 매핑: `docs/features/<cat>/<feat>/` 중 partner-side 가 있는 feature (settlement, event-operation 등)
- 파일명: `<feature>_test.dart` — user 와 같은 dash→underscore 룰
- mock 대상: partner 의 Repository/Coordinator (`PartnerOnboardingRepository`, `SettlementCoordinator` 등)

## 실행

```bash
export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
cd apps/app_partner
flutter test integration_test/cuj/ \
  --flavor dev \
  --dart-define-from-file=../../minglit_env/dev/flutter.env \
  -d emulator-5554
```

## 폴더 구조

```
integration_test/cuj/
  _engine/
    cuj_test.dart            # app_user 와 동일
  account/
    partner_terms_privacy_test.dart   # CUJ 1-1, 2-1 (Flutter 범위 내)
    partner_account_deletion_test.dart
  checkin/
    partner_qr_checkin_ux_test.dart  # CUJ 1-1~1-4, 2-1~2-3, 3-1~3-6
  event/
    event_edit_cancel_test.dart      # CUJ 1-1~4-2
    recurring_events_test.dart       # CUJ 1-1, 1-2, 1-4, 3-1, 3-2, 3-4
    partner_dashboard_test.dart      # CUJ 1-1~1-5, 2-1~2-5, 3-1~3-3, 4-2~4-3, 5-1~5-2
  event-operation/
    partner_qr_checkin_ux_test.dart  # CUJ 1-1, 1-2, 1-3, 3-1, 3-2, 5-4 (6/13)
    manual_checkin_test.dart         # CUJ 3-1, 3-2 (수동 체크인)
  ...
```

## 커버리지 범위 (Flutter integration test)

| 파일 | spec | 커버 CUJ |
|------|------|----------|
| `account/partner_terms_privacy_test.dart` | `docs/features/account/partner-terms-privacy/spec.md` | 1-1 (이용약관 탭+URL), 2-1 (개인정보처리방침 탭+URL) |
| `account/partner_account_deletion_test.dart` | `docs/features/account/partner-account-deletion/spec.md` | 탈퇴 사유 화면 |
| `checkin/partner_qr_checkin_ux_test.dart` | `docs/features/event-operation/partner-qr-checkin-ux/spec.md` | 1-1~1-4 (스캔 결과 배너), 2-1~2-3 (체크인 탭 진입), 3-1~3-6 (수동 체크인) |
| `event/event_edit_cancel_test.dart` | `docs/features/event/event-edit-cancel/spec.md` | 1-1~4-2 (13개 그룹) |
| `event/recurring_events_test.dart` | `docs/features/event/recurring-events/spec.md` | 1-1, 1-2, 1-4, 3-1, 3-2, 3-4 |
| `event/partner_dashboard_test.dart` | `docs/features/event/partner-dashboard/spec.md` | 1-1~1-5, 2-1~2-5, 3-1~3-3, 4-2~4-3, 5-1~5-2 |
| `event-operation/partner_qr_checkin_ux_test.dart` | `docs/features/event-operation/partner-qr-checkin-ux/spec.md` | 1-1, 1-2, 1-3, 3-1, 3-2, 5-4 (6/13) |
| `event-operation/manual_checkin_test.dart` | `docs/features/event-operation/partner-qr-checkin-ux/spec.md` | 3-1 (수동 체크인 시트 진입 + 참가자 목록), 3-2 (수동 체크인 처리) |

Flutter 범위 외 CUJ (landing_partner 웹 기능 또는 미구현): 1-2, 1-3, 2-2~2-4, 3-1~3-2.

---
_Reviewed: 2026-05-20 07:50_
