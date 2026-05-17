// CUJ test framework — 최소 엔진.
//
// 디자인 원칙:
//   - 엔진은 얇게 (testWidgets 두 번 감싼 정도).
//   - 모든 feature 별 mock 은 feature `<feature>_test.dart` 안에 자유롭게.
//   - 새 CUJ 추가 = 한 블록 추가. 새 파일/폴더/import 없음.
//
// 한 CUJ (spec.md CUJ 테이블 row) = `cujGroup('<id>', '<name>')` 하나.
// 그 안에 happy / edge / error 케이스를 `cujCase(...)` 로 N개 등록.
//
// 사용 패턴:
//
//   void main() {
//     late MockConsentRepository repo;
//     late MockConsentCoordinator coordinator;
//
//     setUp(() {
//       repo = MockConsentRepository();
//       coordinator = MockConsentCoordinator();
//     });
//
//     List<dynamic> base() => [
//       consentRepositoryProvider.overrideWithValue(repo),
//       consentCoordinatorProvider.overrideWithValue(coordinator),
//     ];
//
//     cujGroup('1-1', '필수 동의 3종 체크 후 가입', () {
//       cujCase('happy: 정상 가입',
//         app: const SignupConsentPage(),
//         overrides: base,
//         body: (t) async {
//           // tap checkboxes, tap CTA, verify mock calls
//         },
//       );
//
//       cujCase('edge: 14세 미체크 → CTA 비활성',
//         app: const SignupConsentPage(),
//         overrides: base,
//         body: (t) async { /* ... */ },
//       );
//     });
//   }
//
// ⚠ overrides 가 함수인 이유:
//   group() body 는 declaration time 에 실행됨 (setUp 보다 먼저).
//   setUp 안에서 만든 mock 인스턴스를 캡처하려면 lazy 평가 필요.
//   List 로 받으면 declaration time 의 null repo 가 캡처됨 → NPE.
//
// ⚠ List<dynamic> + .cast() 패턴:
//   Riverpod 3.x 의 Override 는 sealed — public 으로 type 명시 불가.
//   mds-emulator-render 의 builder.dart 와 동일 우회.
//   런타임 동작은 strict 와 동일 (cast 실패 시 즉시 throw).
//
// ⚠ provider override 중복:
//   Riverpod 는 같은 provider 두 번 override 되면 throw
//   ("Tried to override a provider twice"). base 와 extra override 가
//   같은 provider 를 set 하면 author 가 한 쪽만 남기도록 책임진다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// CUJ group — spec.md CUJ 테이블의 한 row 에 대응.
///
/// [id] 는 spec.md 의 CUJ ID (예: '1-1'). 그룹 description prefix 로 들어가
/// 실패 메시지에서 spec.md 로 직접 트레이스 가능.
@isTestGroup
void cujGroup(String id, String name, void Function() body) {
  group('[$id] $name', body);
}

/// CUJ 안의 한 테스트 케이스. happy / edge / error 등 prefix 컨벤션.
///
/// [overrides] 는 lazy — group body 는 declaration time 실행이므로 setUp 안에서
/// 만든 mock 캡처하려면 함수 형태. 없으면 빈 list.
///
/// [app] 은 ProviderScope + MaterialApp 안의 home 위젯. MinglitTheme 자동 적용.
@isTest
void cujCase(
  String name, {
  required Widget app,
  List<dynamic> Function()? overrides,
  required Future<void> Function(WidgetTester) body,
}) {
  testWidgets(name, (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: (overrides?.call() ?? const <dynamic>[]).cast(),
        child: MaterialApp(
          theme: MinglitTheme.materialTheme,
          debugShowCheckedModeBanner: false,
          home: app,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await body(tester);
  });
}
