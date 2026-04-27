import 'package:app_partner/main.dart' show kPartnerLocalizationsDelegates;
import 'package:app_partner/src/features/party/create/party_create_wizard_controller.dart';
import 'package:app_partner/src/features/party/create/steps/step2_location.dart';
import 'package:app_partner/src/features/party/widgets/party_location_detail_input.dart';
import 'package:app_partner/src/features/party/widgets/party_location_input.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

Widget _buildStep2({
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
        body: SingleChildScrollView(child: Step2Location()),
      ),
    ),
  );
}

void main() {
  group('Step2Location', () {
    testWidgets('크래시 없이 렌더링됨', (tester) async {
      await tester.pumpWidget(_buildStep2());
      await tester.pump();

      expect(find.byType(Step2Location), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('파티 장소 라벨과 PartyLocationInput 표시됨', (tester) async {
      await tester.pumpWidget(_buildStep2());
      await tester.pump();

      expect(find.text('파티 장소'), findsOneWidget);
      expect(find.byType(PartyLocationInput), findsOneWidget);
    });

    testWidgets('PartyLocationDetailInput 표시됨', (tester) async {
      await tester.pumpWidget(_buildStep2());
      await tester.pump();

      expect(find.byType(PartyLocationDetailInput), findsOneWidget);
    });

    testWidgets('장소 미선택 시 입력 필드 비활성 힌트 표시됨', (tester) async {
      // selectedLocation == null → enabled: false → hint '장소를 먼저 선택해주세요.'
      await tester.pumpWidget(_buildStep2());
      await tester.pump();

      expect(
        find.text('장소를 먼저 선택해주세요.'),
        findsWidgets,
      );
    });
  });
}

class _FakeWizardController extends PartyCreateWizardController {
  _FakeWizardController(this._initialState);
  final PartyCreateWizardState _initialState;

  @override
  PartyCreateWizardState build() => _initialState;
}
