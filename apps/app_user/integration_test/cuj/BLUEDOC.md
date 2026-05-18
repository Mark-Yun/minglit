# integration_test/cuj/

CUJ (Critical User Journey) 행위 테스트 — **실 에뮬레이터/디바이스** 위에서 mock 기반 사용자 흐름 검증.

## 왜

- spec.md 의 CUJ ↔ 테스트 1:1 트레이스 (실패 메시지에 `[1-1]` prefix 직접 노출).
- 새 CUJ 추가 = feature 파일에 `cujGroup` 한 블록 추가. 새 파일/폴더/import 없음 — 100 CUJ 도달해도 같은 마찰.
- 실 디바이스 렌더링 + 실 제스처 + 실 platform channel → host widget test 가 못 잡는 native dialog, scroll physics, 플러그인 이슈, 빌드/렌더 타이밍 버그까지 catch.
- mock 전략은 동일 — Repository/Coordinator/Supabase 는 mock (외부 의존성 차단), Material 렌더링/제스처/Navigator 는 실제.
- 알케미스트와 달리 **행위** 검증 (탭 → mock spy → assert). 시각 회귀(스크린샷 diff)는 `integration_test/mds-emulator-render/`.

## 폴더 구조

```
integration_test/cuj/
  _engine/
    cuj_test.dart        # cujGroup() + cujCase()
  <category>/
    <feature>_test.dart  # 한 feature 의 모든 CUJ
```

카테고리는 `docs/features/<category>/` 와 동일 (`account`, `event`, `discovery`, ...).

파일명은 spec.md 폴더명 기반 (대시 → 언더스코어):
- `docs/features/account/signup-consent/spec.md` ↔ `integration_test/cuj/account/signup_consent_test.dart`

## 필수 boilerplate

각 test 파일 `main()` 최상단에 `IntegrationTestWidgetsFlutterBinding.ensureInitialized()` 필수 — 디바이스 binding 활성화.

```dart
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // ... setUp, cujGroup ...
}
```

## 패턴

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockConsentRepository repo;
  late MockConsentCoordinator coordinator;

  setUp(() {
    repo = MockConsentRepository();
    coordinator = MockConsentCoordinator();
    when(() => repo.saveConsents(any(), any())).thenAnswer((_) async {});
  });

  List<dynamic> base() => [
    consentRepositoryProvider.overrideWith((_) => repo),
    consentCoordinatorProvider.overrideWith((_) => coordinator),
  ];

  cujGroup('1-1', '필수 동의 3종 체크 후 가입', () {
    cujCase('happy: 정상 가입',
      app: const SignupConsentPage(),
      overrides: base,
      body: (t) async {
        await t.tap(find.text('서비스 이용약관'));
        await t.tap(find.text('개인정보 수집·이용 동의'));
        await t.tap(find.text('만 14세 이상 확인'));
        await t.tap(find.text('동의하고 시작하기'));
        await t.pumpAndSettle();
        verify(() => repo.saveConsents(any(), any())).called(1);
        verify(() => coordinator.completeSignup(from: any(named: 'from'))).called(1);
      },
    );

    cujCase('edge: 14세 미체크 → CTA 비활성',
      app: const SignupConsentPage(),
      overrides: base,
      body: (t) async {
        await t.tap(find.text('서비스 이용약관'));
        await t.tap(find.text('개인정보 수집·이용 동의'));
        final cta = t.widget<MinglitBottomCTA>(find.byType(MinglitBottomCTA));
        expect(cta.enabled, isFalse);
      },
    );
  });

  cujGroup('1-2', '전체동의 토글로 일괄 체크', () { /* ... */ });
}
```

## CUJ ID 컨벤션

| 형식 | 의미 |
|------|------|
| `<scenario>-<cuj>` | spec.md User Journey Scenario 번호 + 그 안의 CUJ 번호 |

예) `1-1` = Scenario 1 의 첫 CUJ. spec.md 의 CUJ 테이블 행과 ID 동일.

## 케이스 prefix 컨벤션

| prefix | 의미 |
|--------|------|
| `happy:` | 정상 경로 |
| `edge:` | spec.md Edge Cases 테이블의 한 행 |
| `error:` | 에러 분기 (네트워크 / 권한 등) |

## 실행

에뮬레이터 또는 실 디바이스 연결 필요. `flutter devices` 로 확인.

**필수 플래그** — `--flavor dev` + `--dart-define-from-file` + Java 17. flavor 빠지면 Gradle 이 silently fail (APK 안 만들고 종료 → "Gradle build failed to produce an .apk file" 에러).

```bash
export JAVA_HOME="$(/usr/libexec/java_home -v 17)"

# feature 하나만
flutter test integration_test/cuj/account/signup_consent_test.dart \
  --flavor dev \
  --dart-define-from-file=../../minglit_env/dev/flutter.env \
  -d emulator-5554

# 카테고리 전체 (Flutter 가 파일별 세션 분리)
flutter test integration_test/cuj/account/ \
  --flavor dev \
  --dart-define-from-file=../../minglit_env/dev/flutter.env \
  -d emulator-5554

# 전체 CUJ
flutter test integration_test/cuj/ \
  --flavor dev \
  --dart-define-from-file=../../minglit_env/dev/flutter.env \
  -d emulator-5554
```

빌드 ~35초 (첫 실행, 캐시 후 빠름), 케이스당 ~1-2초.

실패 메시지 예시:
```
✗ [1-1] 필수 동의 3종 체크 후 가입 happy: 정상 가입
```

`[1-1]` 로 `docs/features/account/signup-consent/spec.md` CUJ 1-1 row 에 직접 점프.

## 안 하는 것

- ❌ 코드 generation — fluent builder / 자동 mock 생성 없음
- ❌ base class 상속 — `cujCase()` 함수 호출만
- ❌ 시각 회귀 (스크린샷 diff) — `mds-emulator-render/` 가 담당
- ❌ 실 Supabase / 실 router 호출 — Repository/Coordinator 는 mock

## 새 CUJ 추가 절차

1. `docs/features/<cat>/<feature>/spec.md` CUJ 테이블에 ID/Name/Details/FR/NFR 행 추가
2. (필요 시) Edge Cases 테이블에 변형 케이스 추가
3. `integration_test/cuj/<cat>/<feature>_test.dart` 에 `cujGroup('<id>', '<name>', () { ... })` 블록 추가
4. happy + edge case 별 `cujCase(...)` 작성
5. 새 feature 면 새 파일 생성, 기존 feature 면 기존 파일 안에 추가

## 관련

- 엔진 코드: [`_engine/cuj_test.dart`](./_engine/cuj_test.dart)
- spec 컨벤션: [`docs/features/BLUEDOC.md`](../../../../docs/features/BLUEDOC.md)
- 시각 회귀: [`mds-emulator-render/BLUEDOC.md`](../mds-emulator-render/BLUEDOC.md)

---
_Reviewed: 2026-05-18 03:45_
