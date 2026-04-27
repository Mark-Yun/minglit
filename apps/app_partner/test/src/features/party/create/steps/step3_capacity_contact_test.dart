import 'package:app_partner/main.dart' show kPartnerLocalizationsDelegates;
import 'package:app_partner/src/features/party/create/party_create_wizard_controller.dart';
import 'package:app_partner/src/features/party/create/steps/step3_capacity_contact.dart';
import 'package:app_partner/src/features/party/widgets/party_capacity_input.dart';
import 'package:app_partner/src/features/party/widgets/party_contact_input.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

Widget _buildStep3({
  PartyCreateWizardState state = const PartyCreateWizardState(),
}) {
  return ProviderScope(
    overrides: [
      partyCreateWizardControllerProvider.overrideWith(
        () => _FakeWizardController(state),
      ),
      // Prevent network call; no autofill behavior needed in widget tests
      currentPartnerInfoProvider.overrideWith((ref) async => null),
    ],
    child: const MaterialApp(
      localizationsDelegates: kPartnerLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(child: Step3CapacityContact()),
      ),
    ),
  );
}

void main() {
  group('Step3CapacityContact', () {
    testWidgets('크래시 없이 렌더링됨', (tester) async {
      await tester.pumpWidget(_buildStep3());
      await tester.pump();

      expect(find.byType(Step3CapacityContact), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '모집 인원 / 문의 연락처 라벨, PartyCapacityInput, PartyContactInput 표시됨',
      (tester) async {
        await tester.pumpWidget(_buildStep3());
        await tester.pump();

        expect(find.text('모집 인원'), findsOneWidget);
        expect(find.text('문의 연락처'), findsOneWidget);
        expect(find.byType(PartyCapacityInput), findsOneWidget);
        expect(find.byType(PartyContactInput), findsOneWidget);
      },
    );

    testWidgets('성비 균형 off 시 허용 오차 NumberStepper 숨김', (tester) async {
      await tester.pumpWidget(
        _buildStep3(),
      );
      await tester.pump();

      expect(find.text('허용 오차'), findsNothing);
    });

    testWidgets('성비 균형 on 시 허용 오차 NumberStepper 표시', (tester) async {
      await tester.pumpWidget(
        _buildStep3(
          state: const PartyCreateWizardState(balanceEnabled: true),
        ),
      );
      await tester.pump();

      expect(find.text('허용 오차'), findsOneWidget);
    });
  });
}

class _FakeWizardController extends PartyCreateWizardController {
  _FakeWizardController(this._initialState);
  final PartyCreateWizardState _initialState;

  @override
  PartyCreateWizardState build() => _initialState;
}
