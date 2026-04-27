// Fix #1538 regression guard: Step1 uses kPartnerLocalizationsDelegates
// (includes FlutterQuillLocalizations.delegate) — must pumpAndSettle for Quill.
import 'package:app_partner/main.dart' show kPartnerLocalizationsDelegates;
import 'package:app_partner/src/features/party/create/party_create_wizard_controller.dart';
import 'package:app_partner/src/features/party/create/steps/step1_basic_info.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

Widget _buildStep1({
  PartyCreateWizardState state = const PartyCreateWizardState(),
}) {
  return ProviderScope(
    overrides: [
      partyCreateWizardControllerProvider.overrideWith(
        () => _FakeWizardController(state),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: kPartnerLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: SingleChildScrollView(child: Step1BasicInfo()),
      ),
    ),
  );
}

void main() {
  group('Step1BasicInfo', () {
    testWidgets('크래시 없이 렌더링됨', (tester) async {
      await tester.pumpWidget(_buildStep1());
      await tester.pumpAndSettle();

      expect(find.byType(Step1BasicInfo), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('파티 제목 / 상세 설명 / 커버 이미지 섹션 라벨 표시됨', (tester) async {
      await tester.pumpWidget(_buildStep1());
      await tester.pumpAndSettle();

      expect(find.text('파티 제목'), findsOneWidget);
      expect(find.text('상세 설명'), findsOneWidget);
      expect(find.text('커버 이미지'), findsOneWidget);
    });

    testWidgets('비공개 스위치 기본값 off (visibility == public)', (tester) async {
      await tester.pumpWidget(_buildStep1());
      await tester.pumpAndSettle();

      final switchFinder = find.byType(SwitchListTile);
      expect(switchFinder, findsOneWidget);
      final switchWidget = tester.widget<SwitchListTile>(switchFinder);
      expect(switchWidget.value, isFalse);
    });

    testWidgets('비공개 스위치 토글 → visibility private으로 변경', (tester) async {
      await tester.pumpWidget(_buildStep1());
      await tester.pumpAndSettle();

      final switchFinder = find.byType(SwitchListTile);
      await tester.ensureVisible(switchFinder);
      await tester.tap(switchFinder);
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(Step1BasicInfo)),
      );
      final state = container.read(partyCreateWizardControllerProvider);
      expect(state.visibility, 'private');
    });
  });
}

class _FakeWizardController extends PartyCreateWizardController {
  _FakeWizardController(this._initialState);
  final PartyCreateWizardState _initialState;

  @override
  PartyCreateWizardState build() => _initialState;
}
