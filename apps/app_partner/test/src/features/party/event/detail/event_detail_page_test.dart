import 'dart:async';

import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:app_partner/src/features/party/event/detail/event_detail_controller.dart';
import 'package:app_partner/src/features/party/event/detail/event_detail_page.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:app_partner/src/logic/event_application_logic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  final now = DateTime(2026, 5, 6, 12);

  Event buildEvent({
    String status = 'scheduled',
    int currentParticipants = 4,
    int maxParticipants = 12,
  }) {
    return Event(
      id: 'event-1',
      partyId: 'party-1',
      title: '금요일 와인 클래스',
      startTime: now.add(const Duration(days: 3)),
      endTime: now.add(const Duration(days: 3, hours: 2)),
      createdAt: now,
      updatedAt: now,
      status: status,
      currentParticipants: currentParticipants,
      maxParticipants: maxParticipants,
    );
  }

  final party = Party(
    id: 'party-1',
    partnerId: 'partner-1',
    title: '테스트 파티',
    createdAt: now,
    updatedAt: now,
  );

  EventApplication buildApplication({
    required String id,
    required String status,
    String refundStatus = 'none',
    int paymentAmount = 35000,
  }) {
    return EventApplication(
      id: id,
      eventId: 'event-1',
      ticketId: 'ticket-1',
      userId: 'user-$id',
      status: status,
      createdAt: now,
      updatedAt: now,
      paymentAmount: paymentAmount,
      refundStatus: refundStatus,
    );
  }

  Ticket buildTicket() {
    return Ticket(
      id: 'ticket-1',
      name: '일반 입장권',
      createdAt: now,
      updatedAt: now,
      price: 35000,
      quantity: 12,
    );
  }

  Widget buildPage({
    Event? event,
    Exception? eventError,
    Completer<Event>? eventCompleter,
    List<EventApplication> applications = const [],
    List<Ticket>? tickets,
  }) {
    return ProviderScope(
      overrides: [
        eventDetailProvider('event-1').overrideWith((ref) async {
          if (eventError != null) {
            throw eventError;
          }
          if (eventCompleter != null) {
            return eventCompleter.future;
          }
          return event ?? buildEvent();
        }),
        partyDetailProvider('party-1').overrideWith((ref) async => party),
        eventApplicationsProvider('event-1').overrideWith(
          (ref) async => applications,
        ),
        eventTicketsProvider('event-1').overrideWith(
          (ref) async => tickets ?? [buildTicket()],
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('ko'),
        home: EventDetailPage(eventId: 'event-1'),
      ),
    );
  }

  testWidgets('cancelled state shows refund card instead of participation card', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildPage(
        event: buildEvent(status: 'cancelled'),
        applications: [
          buildApplication(
            id: '1',
            status: 'approved',
            refundStatus: 'completed',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('환불 완료'), findsWidgets);
    expect(find.text('참가 현황'), findsNothing);
  });

  testWidgets('0-applications hides review link', (tester) async {
    await tester.pumpWidget(
      buildPage(
        event: buildEvent(currentParticipants: 0),
        applications: const [],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('처리하기'), findsNothing);
  });

  testWidgets('loading state shows spinner', (tester) async {
    final completer = Completer<Event>();

    await tester.pumpWidget(buildPage(eventCompleter: completer));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('error state shows retry button', (tester) async {
    await tester.pumpWidget(
      buildPage(eventError: Exception('load error')),
    );
    await tester.pumpAndSettle();

    expect(find.text('다시 시도'), findsOneWidget);
  });

  testWidgets('정보 수정 hidden when confirmed participants >= 1', (tester) async {
    // Fix #2275: confirmedCount >= 1 must lock editing per spec #2109
    await tester.pumpWidget(
      buildPage(
        event: buildEvent(currentParticipants: 2),
        applications: [
          buildApplication(id: '1', status: 'approved'),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('정보 수정'), findsNothing);
  });

  testWidgets('정보 수정 visible when no confirmed participants', (tester) async {
    await tester.pumpWidget(
      buildPage(
        event: buildEvent(currentParticipants: 0),
        applications: const [],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('정보 수정'), findsOneWidget);
  });

  testWidgets('cancelled state shows no capacity bar in revenue section', (tester) async {
    // Fix #2275: capacity bar always 100% in cancelled state — should be hidden
    await tester.pumpWidget(
      buildPage(
        event: buildEvent(status: 'cancelled', currentParticipants: 1),
        applications: [
          buildApplication(
            id: '1',
            status: 'approved',
            refundStatus: 'completed',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MinglitCapacityBar), findsNothing);
  });

  testWidgets('ticketsAsync loading shows spinner when no fallback tickets', (tester) async {
    // Fix #2275: ticketsAsync isLoading must surface the spinner when event.tickets is null
    final ticketsCompleter = Completer<List<Ticket>>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventDetailProvider('event-1').overrideWith(
            (ref) async => buildEvent(currentParticipants: 0),
          ),
          partyDetailProvider('party-1').overrideWith((ref) async => party),
          eventApplicationsProvider('event-1').overrideWith((ref) async => []),
          eventTicketsProvider('event-1').overrideWith(
            (ref) => ticketsCompleter.future,
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('ko'),
          home: EventDetailPage(eventId: 'event-1'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    ticketsCompleter.complete([buildTicket()]);
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
