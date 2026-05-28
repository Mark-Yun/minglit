# mds-emulator-render (app_partner)

MDS spec 의 각 화면을 실제 Flutter 앱으로 에뮬레이터에서 렌더링하여 PNG 캡처. 결과는 `docs/infra/mds-emulator-render/<screen>/state-*.png` 로, MDS HTML 디자인과 1:1 비교 대상.

app_user 의 동일 인프라(`apps/app_user/integration_test/mds-emulator-render/`)를 app_partner 용으로 미러링. 엔진 코드는 동일, mock 및 builder 는 app_partner 전용.

## 빠른 실행 (단일 화면)

```bash
cd apps/app_partner
export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
flutter drive \
  --driver=test_driver/mds_emulator_render_driver.dart \
  --target=integration_test/mds-emulator-render/<screen>/<screen>_test.dart \
  --flavor dev \
  --dart-define-from-file=../../minglit_env/dev/flutter.env \
  -d <device>
```

## 등록된 화면 (카탈로그 완료)

| 화면 | states |
|------|--------|
| `bank_account_page` | loading · no-account · with-account · dark |
| `checkin_placeholder_page` | loading · error · empty · selection · selection-dark |
| `create_verification_page` | empty · with-fields · dark |
| `location_guide_page` | default · loading |
| `more_page` | default · limited-permissions |
| `party_list_page` | default · empty · loading · error · help |
| `partner_login_page` | default-ios · default-android · loading · auth-error |
| `recurrence_management_screen` | active · paused · cancelled · no-rule · action-loading · loading · active-dark |
| `settlement_detail_page` | completed · pending · failed · hold · loading |
| `settlement_page` | loading · empty · error |
| `verification_manage_page` | loading · active-empty · active-with-items · archived-with-items · dark |

## 구조

```
mds-emulator-render/
├── BLUEDOC.md              # ← 본 문서
├── _engine/                # 공통 framework (app_user 와 동일)
│   ├── builder.dart
│   ├── catalog.dart
│   ├── state.dart
│   ├── runner.dart
│   └── manifest.dart
├── _mocks/
│   └── data.dart           # mockPartner(), mockVerification(), mockBankAccount(), mockRecurrenceRule(), mockEvents()
├── _registry.dart          # 등록된 모든 catalog (알파벳 순)
├── bank_account_page/
│   ├── builder.dart
│   └── bank_account_page_test.dart
├── checkin_placeholder_page/
│   ├── builder.dart
│   └── checkin_placeholder_page_test.dart
├── create_verification_page/
│   ├── builder.dart
│   └── create_verification_page_test.dart
├── location_guide_page/
│   ├── builder.dart
│   └── location_guide_page_test.dart
├── more_page/
│   ├── builder.dart
│   └── more_page_test.dart
├── party_list_page/
│   ├── builder.dart
│   └── party_list_page_test.dart
├── partner_login_page/
│   ├── builder.dart
│   └── partner_login_page_test.dart
├── recurrence_management_screen/
│   ├── builder.dart
│   └── recurrence_management_screen_test.dart
├── settlement_detail_page/
│   ├── builder.dart
│   └── settlement_detail_page_test.dart
├── settlement_page/
│   ├── builder.dart
│   └── settlement_page_test.dart
└── verification_manage_page/
    ├── builder.dart
    └── verification_manage_page_test.dart
```

## 관련

- [app_user mds-emulator-render](../../../app_user/integration_test/mds-emulator-render/BLUEDOC.md)
- [architecture.md](../../../app_user/integration_test/mds-emulator-render/architecture.md)

_Reviewed: 2026-05-29 03:18_
