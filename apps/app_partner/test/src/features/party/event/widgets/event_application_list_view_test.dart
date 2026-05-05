// Fix #2224: groupId 필터 — ticket.targetEntryGroupIds 기반 동작 검증.
//
// RPC가 ticket 정보를 함께 반환하므로 EventApplication.ticket이 null이 아니어야 하며,
// groupId 필터가 올바르게 동작해야 한다.
import 'package:app_partner/src/features/party/event/detail/event_application_controller.dart';
import 'package:app_partner/src/features/party/event/widgets/event_application_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  final now = DateTime(2026, 5, 1);

  Ticket _ticket({required String id, List<String> groupIds = const []}) =>
      Ticket(
        id: id,
        name: '티켓 $id',
        createdAt: now,
        updatedAt: now,
        targetEntryGroupIds: groupIds,
      );

  EventApplication _app({
    required String id,
    required String ticketId,
    Ticket? ticket,
    String status = 'pending_review',
  }) => EventApplication(
    id: id,
    eventId: 'event-1',
    ticketId: ticketId,
    userId: 'user-$id',
    status: status,
    createdAt: now,
    updatedAt: now,
    ticket: ticket,
    user: UserProfile(
      id: 'user-$id',
      name: '유저$id',
      username: 'user$id',
    ),
  );

  Widget buildWidget({
    required List<EventApplication> applications,
    String? groupId,
  }) {
    return ProviderScope(
      overrides: [
        eventApplicationsProvider('event-1').overrideWith(
          (ref) async => applications,
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: EventApplicationListView(
            eventId: 'event-1',
            groupId: groupId,
          ),
        ),
      ),
    );
  }

  group('EventApplicationListView groupId 필터 (Fix #2224)', () {
    testWidgets('groupId가 null이면 모든 신청이 표시된다', (tester) async {
      final apps = [
        _app(
          id: 'a1',
          ticketId: 't1',
          ticket: _ticket(id: 't1', groupIds: ['group-A']),
        ),
        _app(
          id: 'a2',
          ticketId: 't2',
          ticket: _ticket(id: 't2', groupIds: ['group-B']),
        ),
      ];

      await tester.pumpWidget(buildWidget(applications: apps));
      await tester.pumpAndSettle();

      expect(find.text('유저a1'), findsOneWidget);
      expect(find.text('유저a2'), findsOneWidget);
    });

    testWidgets('groupId로 필터하면 해당 그룹 신청만 표시된다', (tester) async {
      final apps = [
        _app(
          id: 'a1',
          ticketId: 't1',
          ticket: _ticket(id: 't1', groupIds: ['group-A']),
        ),
        _app(
          id: 'a2',
          ticketId: 't2',
          ticket: _ticket(id: 't2', groupIds: ['group-B']),
        ),
      ];

      await tester.pumpWidget(
        buildWidget(applications: apps, groupId: 'group-A'),
      );
      await tester.pumpAndSettle();

      expect(find.text('유저a1'), findsOneWidget);
      expect(find.text('유저a2'), findsNothing);
    });

    testWidgets('ticket이 null인 신청은 groupId 필터에서 제외된다', (tester) async {
      // Fix #2224: Before the RPC fix, ticket was always null — this test
      // ensures that null-ticket applications are not shown when groupId is set.
      final apps = [
        _app(id: 'a1', ticketId: 't1', ticket: null), // no ticket data
        _app(
          id: 'a2',
          ticketId: 't2',
          ticket: _ticket(id: 't2', groupIds: ['group-A']),
        ),
      ];

      await tester.pumpWidget(
        buildWidget(applications: apps, groupId: 'group-A'),
      );
      await tester.pumpAndSettle();

      expect(find.text('유저a1'), findsNothing);
      expect(find.text('유저a2'), findsOneWidget);
    });

    testWidgets('필터 결과가 없으면 빈 상태 메시지를 표시한다', (tester) async {
      final apps = [
        _app(
          id: 'a1',
          ticketId: 't1',
          ticket: _ticket(id: 't1', groupIds: ['group-B']),
        ),
      ];

      await tester.pumpWidget(
        buildWidget(applications: apps, groupId: 'group-A'),
      );
      await tester.pumpAndSettle();

      expect(find.text('신청 내역이 없습니다.'), findsOneWidget);
    });
  });
}
