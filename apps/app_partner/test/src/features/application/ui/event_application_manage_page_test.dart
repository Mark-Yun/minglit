import 'package:app_partner/src/features/application/event_application_manage_page.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  final now = DateTime(2026, 3, 29, 14);

  const testPartner = Partner(id: 'partner_1', name: 'Test Partner');

  final testEvent = Event(
    id: 'event_1',
    partyId: 'party_1',
    title: '테스트 이벤트',
    startTime: now.add(const Duration(hours: 2)),
    endTime: now.add(const Duration(hours: 5)),
    createdAt: now,
    updatedAt: now,
    currentParticipants: 5,
  );

  EventApplication makeApp({
    required String id,
    required String status,
    String? userName,
    String? gender,
    int? birthYear,
  }) {
    return EventApplication(
      id: id,
      eventId: 'event_1',
      ticketId: 'ticket_1',
      userId: 'user_$id',
      status: status,
      createdAt: now.subtract(const Duration(hours: 1)),
      updatedAt: now,
      user: userName != null
          ? UserProfile(
              id: 'user_$id',
              name: userName,
              username: userName.toLowerCase(),
              gender: gender,
              birthYear: birthYear,
            )
          : null,
    );
  }

  Widget createTestWidget({
    Partner? partner,
    Map<Event, List<EventApplication>>? pendingGrouped,
    Map<Event, List<EventApplication>>? approvedGrouped,
    Map<Event, List<EventApplication>>? rejectedGrouped,
  }) {
    return ProviderScope(
      overrides: [
        currentPartnerInfoProvider.overrideWith(
          (ref) async => partner ?? testPartner,
        ),
        eventApplicationsGroupedProvider.overrideWith(
          (ref, params) async {
            if (params.statusFilter.contains('pending')) {
              return pendingGrouped ?? {};
            }
            if (params.statusFilter.contains('approved')) {
              return approvedGrouped ?? {};
            }
            if (params.statusFilter.contains('rejected')) {
              return rejectedGrouped ?? {};
            }
            return {};
          },
        ),
      ].cast(),
      child: const MaterialApp(
        home: EventApplicationManagePage(),
      ),
    );
  }

  group('EventApplicationManagePage', () {
    testWidgets('renders tab bar with 3 tabs', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('신청관리'), findsOneWidget);
      expect(find.text('대기중'), findsOneWidget);
      expect(find.text('승인됨'), findsOneWidget);
      expect(find.text('거절됨'), findsOneWidget);
    });

    testWidgets('shows empty state when no pending applications', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('대기 중인 신청이 없습니다'), findsOneWidget);
      expect(find.byIcon(Icons.assignment_outlined), findsOneWidget);
    });

    testWidgets('shows applications grouped by event', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          pendingGrouped: {
            testEvent: [
              makeApp(
                id: 'app_1',
                status: 'pending',
                userName: '홍길동',
                gender: 'male',
                birthYear: 2000,
              ),
              makeApp(
                id: 'app_2',
                status: 'pending',
                userName: '김영희',
                gender: 'female',
                birthYear: 1998,
              ),
            ],
          },
        ),
      );
      await tester.pumpAndSettle();

      // Event header
      expect(find.textContaining('테스트 이벤트'), findsOneWidget);
      expect(find.textContaining('2건 · 5/20명'), findsOneWidget);

      // Application items
      expect(find.text('홍길동'), findsOneWidget);
      expect(find.text('김영희'), findsOneWidget);
    });

    testWidgets('shows approve/reject buttons for pending tab', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          pendingGrouped: {
            testEvent: [
              makeApp(id: 'app_1', status: 'pending', userName: '홍길동'),
            ],
          },
        ),
      );
      await tester.pumpAndSettle();

      // Approve button (check icon)
      expect(find.byIcon(Icons.check), findsOneWidget);
      // Reject button (close icon)
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('shows bulk approve button when pending applications exist', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          pendingGrouped: {
            testEvent: [
              makeApp(id: 'app_1', status: 'pending', userName: '홍길동'),
              makeApp(id: 'app_2', status: 'pending', userName: '김영희'),
            ],
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('전체 승인 (2건)'), findsOneWidget);
    });

    testWidgets('approved tab shows status badge without action buttons', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          approvedGrouped: {
            testEvent: [
              makeApp(id: 'app_1', status: 'approved', userName: '홍길동'),
            ],
          },
        ),
      );
      await tester.pumpAndSettle();

      // Switch to approved tab
      await tester.tap(find.text('승인됨'));
      await tester.pumpAndSettle();

      expect(find.text('홍길동'), findsOneWidget);
      expect(find.text('승인'), findsOneWidget);
      // No action buttons
      expect(find.byIcon(Icons.check), findsNothing);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('rejected tab shows status badge', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          rejectedGrouped: {
            testEvent: [
              makeApp(id: 'app_1', status: 'rejected', userName: '김철수'),
            ],
          },
        ),
      );
      await tester.pumpAndSettle();

      // Switch to rejected tab
      await tester.tap(find.text('거절됨'));
      await tester.pumpAndSettle();

      expect(find.text('김철수'), findsOneWidget);
      expect(find.text('거절'), findsOneWidget);
    });

    testWidgets('shows partner error when partner is null', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentPartnerInfoProvider.overrideWith((ref) async => null),
          ].cast(),
          child: const MaterialApp(
            home: EventApplicationManagePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('파트너 정보를 불러올 수 없습니다'), findsOneWidget);
    });

    testWidgets('shows user info with age and gender', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          pendingGrouped: {
            testEvent: [
              makeApp(
                id: 'app_1',
                status: 'pending',
                userName: '홍길동',
                gender: 'male',
                birthYear: 2000,
              ),
            ],
          },
        ),
      );
      await tester.pumpAndSettle();

      // Age: 2026 - 2000 = 26
      expect(find.textContaining('26세'), findsOneWidget);
      expect(find.textContaining('남'), findsOneWidget);
    });
  });
}
