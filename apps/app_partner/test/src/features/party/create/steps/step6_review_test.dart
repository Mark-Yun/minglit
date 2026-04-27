import 'package:app_partner/main.dart' show kPartnerLocalizationsDelegates;
import 'package:app_partner/src/features/party/create/party_create_wizard_controller.dart';
import 'package:app_partner/src/features/party/create/steps/step6_review.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:app_partner/src/ui/widgets/common/minglit_editable_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

Widget _buildStep6({
  PartyCreateWizardState state = const PartyCreateWizardState(),
}) {
  return ProviderScope(
    overrides: [
      partyCreateWizardControllerProvider.overrideWith(
        () => _FakeWizardController(state),
      ),
    ],
    child: const MaterialApp(
      localizationsDelegates: kPartnerLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(child: Step6Review()),
      ),
    ),
  );
}

void main() {
  group('Step6Review', () {
    testWidgets('리뷰 섹션 5개 모두 표시됨 (MinglitEditableSection)', (tester) async {
      await tester.pumpWidget(_buildStep6());
      await tester.pump();

      expect(find.byType(MinglitEditableSection), findsNWidgets(5));
    });

    testWidgets('기본 상태에서 validation 에러 카드 표시 (누락된 정보)', (tester) async {
      await tester.pumpWidget(_buildStep6());
      await tester.pump();

      // Default empty state triggers all validation errors
      expect(find.text('누락된 정보를 입력해주세요.'), findsOneWidget);
    });

    testWidgets('섹션 제목 5개 모두 표시됨', (tester) async {
      await tester.pumpWidget(_buildStep6());
      await tester.pump();

      expect(find.text('기본 정보'), findsOneWidget);
      expect(find.text('장소 정보'), findsOneWidget);
      expect(find.text('인원 및 연락처'), findsOneWidget);
      expect(find.text('입장 규칙'), findsOneWidget);
      expect(find.text('티켓 정보'), findsOneWidget);
    });

    testWidgets('기본 정보 섹션 탭 시 currentStep이 basicInfo로 변경됨', (tester) async {
      await tester.pumpWidget(_buildStep6());
      await tester.pump();

      await tester.tap(find.text('기본 정보'));
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(Step6Review)),
      );
      final state = container.read(partyCreateWizardControllerProvider);
      expect(state.currentStep, PartyCreateStep.basicInfo);
    });
  });
}

class _FakeWizardController extends PartyCreateWizardController {
  _FakeWizardController(this._initialState);
  final PartyCreateWizardState _initialState;

  @override
  PartyCreateWizardState build() => _initialState;
}
