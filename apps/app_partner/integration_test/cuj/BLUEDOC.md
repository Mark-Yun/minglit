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
  event-operation/
    ...
  ...
```

## 커버리지 범위 (Flutter integration test)

| 파일 | spec | 커버 CUJ |
|------|------|----------|
| `account/partner_terms_privacy_test.dart` | `docs/features/account/partner-terms-privacy/spec.md` | 1-1 (이용약관 탭+URL), 2-1 (개인정보처리방침 탭+URL) |

Flutter 범위 외 CUJ (landing_partner 웹 기능 또는 미구현): 1-2, 1-3, 2-2~2-4, 3-1~3-2.

---
_Reviewed: 2026-05-20 00:00_
