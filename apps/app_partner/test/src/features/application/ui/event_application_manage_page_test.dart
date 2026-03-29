import 'package:app_partner/src/features/application/event_application_manage_page.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';

// ---------------------------------------------------------------------------
// Test data helpers
// ---------------------------------------------------------------------------

Partner _makePartner({String id = 'p1', String name = 'Test Partner'}) {
  return Partner(id: id, name: name);
}

Event _makeEvent({
  String id = 'e1',
  String partyId = 'party1',
  String? title,
  int maxParticipants = 20,
  int currentParticipants = 0,
}) {
  final now = DateTime.now();
  return Event(
    id: id,
    partyId: partyId,
    title: title,
    startTime: now.add(const Duration(days: 1)),
    endTime: now.add(const Duration(days: 1, hours: 2)),
    createdAt: now,
    updatedAt: now,
    maxParticipants: maxParticipants,
    currentParticipants: currentParticipants,
  );
}

EventApplication _makeApplication({
  String id = 'a1',
  String eventId = 'e1',
  String status = 'pending',
  UserProfile? user,
}) {
  final now = DateTime.now();
  return EventApplication(
    id: id,
    eventId: eventId,
    ticketId: 'ticket1',
    userId: 'u1',
    status: status,
    createdAt: now.subtract(const Duration(minutes: 30)),
    updatedAt: now,
    user: user,
  );
}

UserProfile _makeUser({
  String id = 'u1',
  String name = '홍길동',
  String username = 'hong',
  int? birthYear = 1995,
  String? gender = 'male',
}) {
  return UserProfile(
    id: id,
    name: name,
    username: username,
    birthYear: birthYear,
    gender: gender,
  );
}

// ---------------------------------------------------------------------------
// Widget pump helper
// ---------------------------------------------------------------------------

/// Builds the page wrapped in ProviderScope + MaterialApp with the given
/// provider overrides.
Widget _buildPage({
  Partner? partner,
  bool partnerLoading = false,
  Exception? partnerError,
  Map<Event, List<EventApplication>> pendingData = const {},
  Map<Event, List<EventApplication>> approvedData = const {},
  Map<Event, List<EventApplication>> rejectedData = const {},
  bool applicationsLoading = false,
}) {
  return ProviderScope(
    overrides: [
      // Partner provider
      if (partnerLoading)
        currentPartnerInfoProvider.overrideWith(
          (ref) => Future<Partner?>.delayed(
            const Duration(days: 1),
            () => partner,
          ),
        )
      else if (partnerError != null)
        currentPartnerInfoProvider.overrideWith(
          (ref) => Future<Partner?>.error(partnerError),
        )
      else
        currentPartnerInfoProvider.overrideWith((ref) async => partner),

      // Pending tab provider
      eventApplicationsGroupedProvider((
        partnerId: partner?.id ?? 'p1',
        statusFilter: const ['pending', 'pending_review'],
      )).overrideWith(
        (ref) => applicationsLoading
            ? Future<Map<Event, List<EventApplication>>>.delayed(
                const Duration(days: 1),
                () => pendingData,
              )
            : Future.value(pendingData),
      ),

      // Approved tab provider
      eventApplicationsGroupedProvider((
        partnerId: partner?.id ?? 'p1',
        statusFilter: const ['approved', 'paid'],
      )).overrideWith(
        (ref) => applicationsLoading
            ? Future<Map<Event, List<EventApplication>>>.delayed(
                const Duration(days: 1),
                () => approvedData,
              )
            : Future.value(approvedData),
      ),

      // Rejected tab provider
      eventApplicationsGroupedProvider((
        partnerId: partner?.id ?? 'p1',
        statusFilter: const ['rejected'],
      )).overrideWith(
        (ref) => applicationsLoading
            ? Future<Map<Event, List<EventApplication>>>.delayed(
                const Duration(days: 1),
                () => rejectedData,
              )
            : Future.value(rejectedData),
      ),
    ],
    child: const MaterialApp(
      home: EventApplicationManagePage(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  group('EventApplicationManagePage', () {
    // ------------------------------------------------------------------
    // Tab structure
    // ------------------------------------------------------------------
    group('tab structure', () {
      testWidgets('shows 3 tabs with correct labels', (tester) async {
        await tester.pumpWidget(
          _buildPage(partner: _makePartner()),
        );
        await tester.pumpAndSettle();

        expect(find.text('대기중'), findsOneWidget);
        expect(find.text('승인됨'), findsOneWidget);
        expect(find.text('거절됨'), findsOneWidget);
      });

      testWidgets('shows app bar title', (tester) async {
        await tester.pumpWidget(
          _buildPage(partner: _makePartner()),
        );
        await tester.pumpAndSettle();

        expect(find.text('신청관리'), findsOneWidget);
      });
    });

    // ------------------------------------------------------------------
    // Loading state
    // ------------------------------------------------------------------
    group('loading state', () {
      testWidgets('shows CircularProgressIndicator while partner loads', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildPage(partner: _makePartner(), partnerLoading: true),
        );
        // Only pump once — do NOT settle so the future stays pending.
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets(
        'shows CircularProgressIndicator while applications load',
        (tester) async {
          await tester.pumpWidget(
            _buildPage(
              partner: _makePartner(),
              applicationsLoading: true,
            ),
          );
          // Pump once to build Scaffold + tabs, then once more for the tab
          // content. Don't settle — the future should remain pending.
          await tester.pump();
          await tester.pump();

          expect(
            find.byType(CircularProgressIndicator),
            findsAtLeast(1),
          );
        },
      );
    });

    // ------------------------------------------------------------------
    // Partner null / error
    // ------------------------------------------------------------------
    group('partner null state', () {
      testWidgets('shows error message when partner is null', (tester) async {
        await tester.pumpWidget(
          _buildPage(partner: null),
        );
        await tester.pumpAndSettle();

        expect(find.text('파트너 정보를 불러올 수 없습니다'), findsOneWidget);
      });

      testWidgets('shows error message when partner provider errors', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildPage(partnerError: Exception('network error')),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('오류'), findsOneWidget);
      });
    });

    // ------------------------------------------------------------------
    // Empty state
    // ------------------------------------------------------------------
    group('empty state', () {
      testWidgets('pending tab shows "대기 중인 신청이 없습니다" when empty', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildPage(partner: _makePartner()),
        );
        await tester.pumpAndSettle();

        // Default tab is pending — should show empty message.
        expect(find.text('대기 중인 신청이 없습니다'), findsOneWidget);
      });

      testWidgets('approved tab shows "해당 신청이 없습니다" when empty', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildPage(partner: _makePartner()),
        );
        await tester.pumpAndSettle();

        // Navigate to approved tab.
        await tester.tap(find.text('승인됨'));
        await tester.pumpAndSettle();

        expect(find.text('해당 신청이 없습니다'), findsOneWidget);
      });

      testWidgets('rejected tab shows "해당 신청이 없습니다" when empty', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildPage(partner: _makePartner()),
        );
        await tester.pumpAndSettle();

        // Navigate to rejected tab.
        await tester.tap(find.text('거절됨'));
        await tester.pumpAndSettle();

        expect(find.text('해당 신청이 없습니다'), findsOneWidget);
      });

      testWidgets('empty state shows assignment icon', (tester) async {
        await tester.pumpWidget(
          _buildPage(partner: _makePartner()),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.assignment_outlined), findsOneWidget);
      });
    });

    // ------------------------------------------------------------------
    // Event grouping
    // ------------------------------------------------------------------
    group('event grouping', () {
      testWidgets('shows applications grouped by event', (tester) async {
        final event1 = _makeEvent(id: 'e1', title: '이벤트 A');
        final event2 = _makeEvent(id: 'e2', title: '이벤트 B');

        final app1 = _makeApplication(
          id: 'a1',
          eventId: 'e1',
          user: _makeUser(id: 'u1', name: '김철수'),
        );
        final app2 = _makeApplication(
          id: 'a2',
          eventId: 'e2',
          user: _makeUser(id: 'u2', name: '이영희', gender: 'female'),
        );

        await tester.pumpWidget(
          _buildPage(
            partner: _makePartner(),
            pendingData: {
              event1: [app1],
              event2: [app2],
            },
          ),
        );
        await tester.pumpAndSettle();

        // Both event headers should appear.
        expect(find.textContaining('이벤트 A'), findsOneWidget);
        expect(find.textContaining('이벤트 B'), findsOneWidget);

        // Both user names should appear.
        expect(find.text('김철수'), findsOneWidget);
        expect(find.text('이영희'), findsOneWidget);
      });

      testWidgets('shows application count per event group', (tester) async {
        final event = _makeEvent(
          id: 'e1',
          title: '파티',
          maxParticipants: 10,
          currentParticipants: 3,
        );
        final apps = [
          _makeApplication(
            id: 'a1',
            user: _makeUser(id: 'u1', name: '김철수'),
          ),
          _makeApplication(
            id: 'a2',
            user: _makeUser(id: 'u2', name: '이영희'),
          ),
        ];

        await tester.pumpWidget(
          _buildPage(
            partner: _makePartner(),
            pendingData: {event: apps},
          ),
        );
        await tester.pumpAndSettle();

        // "2건 · 3/10명"
        expect(find.textContaining('2건'), findsOneWidget);
        expect(find.textContaining('3/10명'), findsOneWidget);
      });
    });

    // ------------------------------------------------------------------
    // Approve / Reject buttons (pending tab)
    // ------------------------------------------------------------------
    group('action buttons in pending tab', () {
      testWidgets('approve button is visible', (tester) async {
        final event = _makeEvent(id: 'e1', title: '파티');
        final app = _makeApplication(
          id: 'a1',
          user: _makeUser(),
        );

        await tester.pumpWidget(
          _buildPage(
            partner: _makePartner(),
            pendingData: {
              event: [app],
            },
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.check), findsOneWidget);
        expect(find.byTooltip('승인'), findsOneWidget);
      });

      testWidgets('reject button is visible', (tester) async {
        final event = _makeEvent(id: 'e1', title: '파티');
        final app = _makeApplication(
          id: 'a1',
          user: _makeUser(),
        );

        await tester.pumpWidget(
          _buildPage(
            partner: _makePartner(),
            pendingData: {
              event: [app],
            },
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.close), findsOneWidget);
        expect(find.byTooltip('거절'), findsOneWidget);
      });

      testWidgets('shows approve and reject for each application', (
        tester,
      ) async {
        final event = _makeEvent(id: 'e1', title: '파티');
        final apps = [
          _makeApplication(
            id: 'a1',
            user: _makeUser(id: 'u1', name: '김철수'),
          ),
          _makeApplication(
            id: 'a2',
            user: _makeUser(id: 'u2', name: '이영희'),
          ),
        ];

        await tester.pumpWidget(
          _buildPage(
            partner: _makePartner(),
            pendingData: {event: apps},
          ),
        );
        await tester.pumpAndSettle();

        // Two approve buttons and two reject buttons.
        expect(find.byIcon(Icons.check), findsNWidgets(2));
        expect(find.byIcon(Icons.close), findsNWidgets(2));
      });
    });

    // ------------------------------------------------------------------
    // Status badges (approved / rejected tabs)
    // ------------------------------------------------------------------
    group('status badges', () {
      testWidgets('approved tab shows 승인 badge instead of action buttons', (
        tester,
      ) async {
        final event = _makeEvent(id: 'e1', title: '파티');
        final app = _makeApplication(
          id: 'a1',
          status: 'approved',
          user: _makeUser(),
        );

        await tester.pumpWidget(
          _buildPage(
            partner: _makePartner(),
            approvedData: {
              event: [app],
            },
          ),
        );
        await tester.pumpAndSettle();

        // Navigate to approved tab.
        await tester.tap(find.text('승인됨'));
        await tester.pumpAndSettle();

        // Badge text should appear.
        expect(find.text('승인'), findsOneWidget);

        // Action buttons should NOT be present.
        expect(find.byTooltip('승인'), findsNothing);
        expect(find.byTooltip('거절'), findsNothing);
      });

      testWidgets('rejected tab shows 거절 badge instead of action buttons', (
        tester,
      ) async {
        final event = _makeEvent(id: 'e1', title: '파티');
        final app = _makeApplication(
          id: 'a1',
          status: 'rejected',
          user: _makeUser(),
        );

        await tester.pumpWidget(
          _buildPage(
            partner: _makePartner(),
            rejectedData: {
              event: [app],
            },
          ),
        );
        await tester.pumpAndSettle();

        // Navigate to rejected tab.
        await tester.tap(find.text('거절됨'));
        await tester.pumpAndSettle();

        // Badge text should appear.
        expect(find.text('거절'), findsOneWidget);

        // Action buttons should NOT be present.
        expect(find.byTooltip('승인'), findsNothing);
        expect(find.byTooltip('거절'), findsNothing);
      });

      testWidgets('paid status also shows 승인 badge', (tester) async {
        final event = _makeEvent(id: 'e1', title: '파티');
        final app = _makeApplication(
          id: 'a1',
          status: 'paid',
          user: _makeUser(),
        );

        await tester.pumpWidget(
          _buildPage(
            partner: _makePartner(),
            approvedData: {
              event: [app],
            },
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('승인됨'));
        await tester.pumpAndSettle();

        expect(find.text('승인'), findsOneWidget);
      });
    });

    // ------------------------------------------------------------------
    // Bulk approve
    // ------------------------------------------------------------------
    group('bulk approve', () {
      testWidgets('shows bulk approve button with total count', (
        tester,
      ) async {
        final event1 = _makeEvent(id: 'e1', title: '이벤트 A');
        final event2 = _makeEvent(id: 'e2', title: '이벤트 B');

        await tester.pumpWidget(
          _buildPage(
            partner: _makePartner(),
            pendingData: {
              event1: [
                _makeApplication(
                  id: 'a1',
                  user: _makeUser(id: 'u1', name: '김철수'),
                ),
                _makeApplication(
                  id: 'a2',
                  user: _makeUser(id: 'u2', name: '이영희'),
                ),
              ],
              event2: [
                _makeApplication(
                  id: 'a3',
                  user: _makeUser(id: 'u3', name: '박민수'),
                ),
              ],
            },
          ),
        );
        await tester.pumpAndSettle();

        // "전체 승인 (3건)" button
        expect(find.text('전체 승인 (3건)'), findsOneWidget);
        expect(find.widgetWithText(FilledButton, '전체 승인 (3건)'), findsOneWidget);
      });

      testWidgets('does not show bulk approve button on approved tab', (
        tester,
      ) async {
        final event = _makeEvent(id: 'e1', title: '파티');
        final app = _makeApplication(
          id: 'a1',
          status: 'approved',
          user: _makeUser(),
        );

        await tester.pumpWidget(
          _buildPage(
            partner: _makePartner(),
            approvedData: {
              event: [app],
            },
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('승인됨'));
        await tester.pumpAndSettle();

        expect(find.textContaining('전체 승인'), findsNothing);
      });

      testWidgets('does not show bulk approve when pending list is empty', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildPage(partner: _makePartner()),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('전체 승인'), findsNothing);
      });

      testWidgets('tapping bulk approve shows confirmation dialog', (
        tester,
      ) async {
        final event = _makeEvent(id: 'e1', title: '파티');

        await tester.pumpWidget(
          _buildPage(
            partner: _makePartner(),
            pendingData: {
              event: [
                _makeApplication(
                  id: 'a1',
                  user: _makeUser(id: 'u1', name: '김철수'),
                ),
              ],
            },
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('전체 승인 (1건)'));
        await tester.pumpAndSettle();

        expect(find.text('전체 승인'), findsAtLeast(1));
        expect(find.textContaining('모두 승인하시겠습니까'), findsOneWidget);
        expect(find.text('취소'), findsOneWidget);
      });
    });

    // ------------------------------------------------------------------
    // User info display
    // ------------------------------------------------------------------
    group('user info display', () {
      testWidgets('shows user name and demographics', (tester) async {
        final event = _makeEvent(id: 'e1', title: '파티');
        final app = _makeApplication(
          id: 'a1',
          user: _makeUser(
            name: '홍길동',
            birthYear: 1995,
            gender: 'male',
          ),
        );

        await tester.pumpWidget(
          _buildPage(
            partner: _makePartner(),
            pendingData: {
              event: [app],
            },
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('홍길동'), findsOneWidget);
        // Age calculation: current year - 1995
        final expectedAge = DateTime.now().year - 1995;
        expect(find.textContaining('${expectedAge}세'), findsOneWidget);
        expect(find.textContaining('남'), findsOneWidget);
      });

      testWidgets('shows "이름 없음" when user is null', (tester) async {
        final event = _makeEvent(id: 'e1', title: '파티');
        final app = _makeApplication(id: 'a1', user: null);

        await tester.pumpWidget(
          _buildPage(
            partner: _makePartner(),
            pendingData: {
              event: [app],
            },
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('이름 없음'), findsOneWidget);
      });

      testWidgets('shows avatar with first character of name', (tester) async {
        final event = _makeEvent(id: 'e1', title: '파티');
        final app = _makeApplication(
          id: 'a1',
          user: _makeUser(name: '김철수'),
        );

        await tester.pumpWidget(
          _buildPage(
            partner: _makePartner(),
            pendingData: {
              event: [app],
            },
          ),
        );
        await tester.pumpAndSettle();

        // CircleAvatar should show '김' (first char)
        expect(find.text('김'), findsOneWidget);
        expect(find.byType(CircleAvatar), findsOneWidget);
      });
    });
  });
}
