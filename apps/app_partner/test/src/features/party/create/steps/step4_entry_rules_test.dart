import 'package:app_partner/main.dart' show kPartnerLocalizationsDelegates;
import 'package:app_partner/src/features/party/create/party_create_wizard_controller.dart';
import 'package:app_partner/src/features/party/create/steps/step4_entry_rules.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

EntryGroupTemplate _makeGroup(String id) => EntryGroupTemplate(
  id: id,
  partyId: 'party-test',
);

Widget _buildStep4({List<EntryGroupTemplate> entryGroups = const []}) {
  return ProviderScope(
    overrides: [
      partyCreateWizardControllerProvider.overrideWith(
        () => _FakeWizardController(
          PartyCreateWizardState(entryGroups: entryGroups),
        ),
      ),
    ],
    child: const MaterialApp(
      localizationsDelegates: kPartnerLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Step4EntryRules()),
    ),
  );
}

void main() {
  group('Step4EntryRules', () {
    testWidgets('입장 그룹 없으면 MinglitEmptyState 표시, AddActionCard 표시', (
      tester,
    ) async {
      await tester.pumpWidget(_buildStep4());
      await tester.pump();

      expect(find.byType(MinglitEmptyState), findsOneWidget);
      expect(find.byType(AddActionCard), findsOneWidget);
    });

    testWidgets('입장 그룹 2개이면 카드 2개 렌더, 빈 상태 없음', (tester) async {
      await tester.pumpWidget(
        _buildStep4(
          entryGroups: [_makeGroup('eg-1'), _makeGroup('eg-2')],
        ),
      );
      await tester.pump();

      expect(find.byType(MinglitEmptyState), findsNothing);
      // Each group renders one Card + header close IconButton
      expect(find.byIcon(Icons.close), findsNWidgets(2));
    });

    testWidgets('닫기 버튼 탭 시 해당 그룹이 목록에서 제거됨', (tester) async {
      await tester.pumpWidget(
        _buildStep4(
          entryGroups: [_makeGroup('eg-1'), _makeGroup('eg-2')],
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.close), findsNWidgets(2));

      // Remove first group
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pump();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('그룹 모두 삭제하면 MinglitEmptyState로 돌아감', (tester) async {
      await tester.pumpWidget(
        _buildStep4(entryGroups: [_makeGroup('eg-1')]),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pump();

      expect(find.byType(MinglitEmptyState), findsOneWidget);
    });
  });
}

class _FakeWizardController extends PartyCreateWizardController {
  _FakeWizardController(this._initialState);
  final PartyCreateWizardState _initialState;

  @override
  PartyCreateWizardState build() => _initialState;
}
