import 'package:app_partner/main.dart' show kPartnerLocalizationsDelegates;
import 'package:app_partner/src/features/party/create/party_create_wizard_controller.dart';
import 'package:app_partner/src/features/party/create/steps/step5_tickets.dart';
import 'package:app_partner/src/features/party/ticket/widgets/party_ticket_template_input.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

TicketTemplate _makeTicket(String id) => TicketTemplate(
      id: id,
      partyId: 'party-test',
      name: '일반 티켓',
      quantity: 10,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

Widget _buildStep5({
  List<TicketTemplate> tickets = const [],
  List<EntryGroupTemplate> entryGroups = const [],
  int maxParticipants = 0,
}) {
  return ProviderScope(
    overrides: [
      partyCreateWizardControllerProvider.overrideWith(
        () => _FakeWizardController(
          PartyCreateWizardState(
            tickets: tickets,
            entryGroups: entryGroups,
            maxParticipants: maxParticipants,
          ),
        ),
      ),
    ],
    child: const MaterialApp(
      localizationsDelegates: kPartnerLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Step5Tickets()),
    ),
  );
}

void main() {
  group('Step5Tickets', () {
    testWidgets('PartyTicketTemplateInput 위젯이 렌더됨', (tester) async {
      await tester.pumpWidget(_buildStep5());
      await tester.pump();

      expect(find.byType(PartyTicketTemplateInput), findsOneWidget);
    });

    testWidgets('티켓 없이도 크래시 없이 렌더, 추가 버튼 표시', (tester) async {
      await tester.pumpWidget(_buildStep5());
      await tester.pump();

      expect(find.byType(Step5Tickets), findsOneWidget);
      expect(find.text('기본 티켓 추가하기'), findsOneWidget);
    });

    testWidgets('티켓 1개 있으면 닫기 아이콘 표시', (tester) async {
      await tester.pumpWidget(
        _buildStep5(tickets: [_makeTicket('ticket-1')]),
      );
      await tester.pump();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });
}

class _FakeWizardController extends PartyCreateWizardController {
  _FakeWizardController(this._initialState);
  final PartyCreateWizardState _initialState;

  @override
  PartyCreateWizardState build() => _initialState;
}
