import 'package:app_partner/src/features/verification/manage/verification_manage_controller.dart';
import 'package:app_partner/src/features/verification/manage/verification_manage_page.dart';
import 'package:app_partner/src/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../utils/mocks.dart';

void main() {
  late MockGoRouter mockRouter;

  setUp(() {
    mockRouter = MockGoRouter();
    when(() => mockRouter.push(any())).thenAnswer((_) async => null);
  });

  Widget buildSubject({
    VerificationManageState state = const VerificationManageState(),
  }) {
    return ProviderScope(
      overrides: [
        verificationManageControllerProvider.overrideWith(
          () => _StubVerificationManageController(state),
        ),
        goRouterProvider.overrideWithValue(mockRouter),
      ],
      child: MaterialApp(
        theme: MinglitTheme.materialTheme,
        home: const VerificationManagePage(),
      ),
    );
  }

  // Fix #2281: regression test — "새로운 인증 만들기" must navigate via goRouterProvider,
  // not context.push, which fails silently in StatefulShellRoute branch navigators.
  testWidgets(
    '새로운 인증 만들기 tap navigates via goRouter (not context.push)',
    (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('새로운 인증 만들기'));
      await tester.pump();

      verify(() => mockRouter.push(any())).called(1);
    },
  );
}

class _StubVerificationManageController extends VerificationManageController {
  _StubVerificationManageController(this._state);

  final VerificationManageState _state;

  @override
  Future<VerificationManageState> build() async => _state;

  @override
  Future<void> archiveVerification(String id) async {}

  @override
  Future<void> restoreVerification(String id) async {}
}
