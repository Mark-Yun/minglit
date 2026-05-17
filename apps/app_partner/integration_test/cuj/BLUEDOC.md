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

## 폴더 구조 (예정)

```
integration_test/cuj/
  _engine/
    cuj_test.dart            # app_user 와 동일
  settlement/
    settlement_test.dart
  event-operation/
    application_review_test.dart
  ...
```

현재는 엔진만 — 첫 partner CUJ 추가 시 spec.md ↔ 테스트 매핑.

---
_Reviewed: 2026-05-17 22:32_
