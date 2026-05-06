import 'package:app_partner/src/features/party/event/detail/event_application_list_page.dart';
import 'package:app_partner/src/logic/event_application_logic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  final now = DateTime(2026, 5, 10, 20);

  final testEvent = Event(
    id: 'event_1',
    partyId: 'party_1',
    title: '스피드 데이팅',
    startTime: now.add(const Duration(hours: 2)),
    endTime: now.add(const Duration(hours: 4)),
    createdAt: now,
    updatedAt: now,
    maxParticipants: 20,
    currentParticipants: 5,
    entryGroups: const [
      EntryGroup(
        id: 'eg_female',
        eventId: 'event_1',
        label: '여성 그룹',
        gender: 'female',
        createdAt: null,
        updatedAt: null,
      ),
      EntryGroup(
        id: 'eg_male',
        eventId: 'event_1',
        label: '남성 그룹',
        gender: 'male',
        createdAt: null,
        updatedAt: null,
      ),
    ],
  );

  EventApplication makeApp({
    required String id,
    required String status,
    String? userName,
    String? username,
    String? gender,
    int? birthYear,
    String refundStatus = 'none',
    String? rejectionReason,
    String? cancellationReason,
    String? groupId,
  }) {
    return EventApplication(
      id: id,
      eventId: 'event_1',
      ticketId: 'ticket_1',
      userId: 'user_$id',
      status: status,
      refundStatus: refundStatus,
      rejectionReason: rejectionReason,
      cancellationReason: cancellationReason,
      createdAt: now.subtract(const Duration(hours: 1)),
      updatedAt: now,
      user: userName != null
          ? UserProfile(
              id: 'user_$id',
              name: userName,
              username: username ?? userName.toLowerCase(),
              gender: gender,
              birthYear: birthYear,
            )
          : null,
      ticket: groupId == null
          ? null
          : Ticket(
              id: 'ticket_$id',
              name: '티켓 $id',
              eventId: 'event_1',
              targetEntryGroupIds: [groupId],
              createdAt: now,
              updatedAt: now,
            ),
    );
  }

  Widget buildPage({
    required EventApplicationBundle bundle,
    String? groupId,
  }) {
    return ProviderScope(
      overrides: [
        eventApplicationBundleProvider(bundle.event.id).overrideWith(
          (ref) async => bundle,
        ),
      ],
      child: MaterialApp(
        home: EventApplicationListPage(
          eventId: bundle.event.id,
          groupId: groupId,
        ),
      ),
    );
  }

  EventApplicationBundle makeBundle({
    List<EventApplication> applications = const [],
    List<Map<String, dynamic>> groupCounts = const [],
  }) {
    return (
      event: testEvent,
      applications: applications,
      groupCounts: groupCounts,
    );
  }

  // Fix #2126: verify 4-tab structure is present
  group('EventApplicationListPage tab structure', () {
    testWidgets('renders 4 tabs: 대기중 승인됨 거절됨 환불', (tester) async {
      await tester.pumpWidget(buildPage(bundle: makeBundle()));
      await tester.pumpAndSettle();

      expect(find.text('대기중'), findsOneWidget);
      expect(find.text('승인됨'), findsOneWidget);
      expect(find.text('거절됨'), findsOneWidget);
      expect(find.text('환불'), findsOneWidget);
    });

    testWidgets('AppBar title is 참가 신청', (tester) async {
      await tester.pumpWidget(buildPage(bundle: makeBundle()));
      await tester.pumpAndSettle();

      expect(find.text('참가 신청'), findsOneWidget);
    });
  });

  // Fix #2126: 대기중 tab shows event hero and capacity bar
  group('대기중 tab content', () {
    testWidgets('shows event title in hero card', (tester) async {
      await tester.pumpWidget(buildPage(bundle: makeBundle()));
      await tester.pumpAndSettle();

      expect(find.text('스피드 데이팅'), findsOneWidget);
    });

    testWidgets('shows capacity bar section', (tester) async {
      final bundle = makeBundle(
        applications: [
          makeApp(id: 'app_1', status: 'approved', userName: '홍길동'),
          makeApp(id: 'app_2', status: 'pending_review', userName: '김영희'),
        ],
      );
      await tester.pumpWidget(buildPage(bundle: bundle));
      await tester.pumpAndSettle();

      expect(find.text('신청 현황'), findsOneWidget);
    });

    testWidgets('shows entry group cards', (tester) async {
      await tester.pumpWidget(buildPage(bundle: makeBundle()));
      await tester.pumpAndSettle();

      // skipOffstage: false — groups may be below fold in ListView
      expect(find.text('여성 그룹', skipOffstage: false), findsOneWidget);
      expect(find.text('남성 그룹', skipOffstage: false), findsOneWidget);
    });
  });

  // Fix #2126: payment_failed applications are excluded from all tabs
  testWidgets('payment_failed apps are not shown in any tab', (tester) async {
    final bundle = makeBundle(
      applications: [
        makeApp(id: 'app_1', status: 'payment_failed', userName: '결제실패유저'),
      ],
    );
    await tester.pumpWidget(buildPage(bundle: bundle));
    await tester.pumpAndSettle();

    expect(find.text('결제실패유저'), findsNothing);

    // Check approved tab
    await tester.tap(find.text('승인됨'));
    await tester.pumpAndSettle();
    expect(find.text('결제실패유저'), findsNothing);

    // Check rejected tab
    await tester.tap(find.text('거절됨'));
    await tester.pumpAndSettle();
    expect(find.text('결제실패유저'), findsNothing);

    // Check refunded tab
    await tester.tap(find.text('환불'));
    await tester.pumpAndSettle();
    expect(find.text('결제실패유저'), findsNothing);
  });

  // Fix #2272: spec State 6 — 승인됨 tab shows paid-only; approved = 결제대기
  group('승인됨 tab', () {
    testWidgets('shows paid applications in 승인됨 tab', (tester) async {
      final bundle = makeBundle(
        applications: [
          makeApp(id: 'app_1', status: 'paid', userName: '홍길동'),
        ],
      );
      await tester.pumpWidget(buildPage(bundle: bundle));
      await tester.pumpAndSettle();

      await tester.tap(find.text('승인됨'));
      await tester.pumpAndSettle();

      expect(find.text('홍길동'), findsOneWidget);
    });

    // Fix #2272: approved status is 결제대기 — must NOT appear in 승인됨 tab
    testWidgets('approved-only applications do not appear in 승인됨 tab', (
      tester,
    ) async {
      final bundle = makeBundle(
        applications: [
          makeApp(id: 'app_1', status: 'approved', userName: '결제대기유저'),
        ],
      );
      await tester.pumpWidget(buildPage(bundle: bundle));
      await tester.pumpAndSettle();

      await tester.tap(find.text('승인됨'));
      await tester.pumpAndSettle();

      expect(find.text('결제대기유저'), findsNothing);
    });

    // Fix #2272: confirmedCount = paid only (spec State 6)
    testWidgets('paid apps are counted in confirmed capacity', (tester) async {
      final bundle = makeBundle(
        applications: [
          makeApp(id: 'app_1', status: 'paid', userName: '결제1'),
          makeApp(id: 'app_2', status: 'approved', userName: '승인1'),
          makeApp(id: 'app_3', status: 'pending_review', userName: '심사중1'),
        ],
      );
      await tester.pumpWidget(buildPage(bundle: bundle));
      await tester.pumpAndSettle();

      // confirmed=1 (paid only), pending=1 (pending_review), total=20
      expect(find.text('확정 1명 · 대기 1명 · 정원 20명'), findsOneWidget);
    });

    testWidgets('shows empty state when no approved applications', (
      tester,
    ) async {
      await tester.pumpWidget(buildPage(bundle: makeBundle()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('승인됨'));
      await tester.pumpAndSettle();

      expect(find.text('승인된 신청이 없습니다'), findsOneWidget);
    });
  });

  // Fix #2126: rejected tab shows applications with rejected status
  group('거절됨 tab', () {
    testWidgets('shows rejected applications', (tester) async {
      final bundle = makeBundle(
        applications: [
          makeApp(id: 'app_1', status: 'rejected', userName: '김철수'),
        ],
      );
      await tester.pumpWidget(buildPage(bundle: bundle));
      await tester.pumpAndSettle();

      await tester.tap(find.text('거절됨'));
      await tester.pumpAndSettle();

      expect(find.text('김철수'), findsOneWidget);
    });

    testWidgets('shows rejection reason line when rejectionReason is set', (
      tester,
    ) async {
      final bundle = makeBundle(
        applications: [
          makeApp(
            id: 'app_1',
            status: 'rejected',
            userName: '김철수',
            rejectionReason: '연령 조건이 맞지 않습니다',
          ),
        ],
      );
      await tester.pumpWidget(buildPage(bundle: bundle));
      await tester.pumpAndSettle();

      await tester.tap(find.text('거절됨'));
      await tester.pumpAndSettle();

      expect(find.text('연령 조건이 맞지 않습니다'), findsOneWidget);
    });

    testWidgets('shows entry group sub-section header', (tester) async {
      final bundle = makeBundle(
        applications: [
          makeApp(
            id: 'app_1',
            status: 'rejected',
            userName: '김철수',
            groupId: 'eg_female',
          ),
        ],
      );
      await tester.pumpWidget(buildPage(bundle: bundle));
      await tester.pumpAndSettle();

      await tester.tap(find.text('거절됨'));
      await tester.pumpAndSettle();

      expect(find.text('여성 그룹'), findsOneWidget);
    });
  });

  // Fix #2272: spec State 8 — 환불 tab shows apps where status == 'cancelled'
  group('환불 tab', () {
    testWidgets('shows cancelled applications in 환불 tab', (tester) async {
      final bundle = makeBundle(
        applications: [
          makeApp(
            id: 'app_1',
            status: 'cancelled',
            userName: '이환불',
            username: 'refund@test.com',
          ),
        ],
      );
      await tester.pumpWidget(buildPage(bundle: bundle));
      await tester.pumpAndSettle();

      await tester.tap(find.text('환불'));
      await tester.pumpAndSettle();

      expect(find.text('이환불'), findsNothing);
      expect(find.text('r***@test.com'), findsOneWidget);
    });

    testWidgets('non-cancelled apps are not in 환불 tab', (tester) async {
      final bundle = makeBundle(
        applications: [
          makeApp(id: 'app_1', status: 'approved', userName: '정상유저'),
        ],
      );
      await tester.pumpWidget(buildPage(bundle: bundle));
      await tester.pumpAndSettle();

      await tester.tap(find.text('환불'));
      await tester.pumpAndSettle();

      expect(find.text('정상유저'), findsNothing);
    });

    testWidgets('shows masked username, not real name', (tester) async {
      final bundle = makeBundle(
        applications: [
          makeApp(
            id: 'app_1',
            status: 'cancelled',
            userName: '홍길동',
            username: 'hong@test.com',
          ),
        ],
      );
      await tester.pumpWidget(buildPage(bundle: bundle));
      await tester.pumpAndSettle();

      await tester.tap(find.text('환불'));
      await tester.pumpAndSettle();

      expect(find.text('홍길동'), findsNothing);
      expect(find.text('h***@test.com'), findsOneWidget);
    });
  });
}
