import 'package:app_partner/src/features/home/partner_active_event_list_page.dart';
import 'package:app_partner/src/features/home/partner_dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

class _LoadedDashboardController extends PartnerDashboardController {
  @override
  PartnerDashboardState build() => _dashboardState;
}

PartnerDashboardState _dashboardState = const PartnerDashboardState(
  status: AsyncValue.data(null),
);

Widget _buildPage({
  required PartnerDashboardState dashboardState,
  String? initialFilter,
}) {
  _dashboardState = dashboardState;
  return ProviderScope(
    overrides: [
      partnerDashboardControllerProvider.overrideWith(
        _LoadedDashboardController.new,
      ),
    ],
    child: MaterialApp(
      home: PartnerActiveEventListPage(initialFilter: initialFilter),
    ),
  );
}

Event _makeEvent({
  required String id,
  required String title,
  required DateTime startTime,
  DateTime? endTime,
  int currentParticipants = 3,
  int maxParticipants = 20,
}) {
  final now = DateTime.now();
  return Event(
    id: id,
    partyId: 'party-1',
    title: title,
    startTime: startTime,
    endTime: endTime ?? startTime.add(const Duration(hours: 2)),
    createdAt: now,
    updatedAt: now,
    currentParticipants: currentParticipants,
    maxParticipants: maxParticipants,
  );
}

void main() {
  group('PartnerActiveEventListPage', () {
    testWidgets('invalid query filter falls back to all events', (
      tester,
    ) async {
      final now = DateTime.now();
      await tester.pumpWidget(
        _buildPage(
          initialFilter: 'bad-filter',
          dashboardState: PartnerDashboardState(
            status: const AsyncValue.data(null),
            recruitingEvents: [
              _makeEvent(
                id: 'recruiting',
                title: '모집 이벤트',
                startTime: now.add(const Duration(days: 9)),
              ),
            ],
            preparingEvents: [
              _makeEvent(
                id: 'upcoming',
                title: '임박 이벤트',
                startTime: now.add(const Duration(days: 3)),
              ),
            ],
            liveEvents: [
              _makeEvent(
                id: 'live',
                title: '라이브 이벤트',
                startTime: now.subtract(const Duration(hours: 1)),
                endTime: now.add(const Duration(hours: 1)),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('임박 이벤트'), findsOneWidget);
      expect(find.text('라이브 이벤트'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, '전체 3'), findsOneWidget);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(find.text('모집 이벤트'), findsOneWidget);
    });

    testWidgets('live query filter selects only live events', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(
        _buildPage(
          initialFilter: 'live',
          dashboardState: PartnerDashboardState(
            status: const AsyncValue.data(null),
            recruitingEvents: [
              _makeEvent(
                id: 'recruiting',
                title: '모집 이벤트',
                startTime: now.add(const Duration(days: 9)),
              ),
            ],
            liveEvents: [
              _makeEvent(
                id: 'live',
                title: '라이브 이벤트',
                startTime: now.subtract(const Duration(hours: 1)),
                endTime: now.add(const Duration(hours: 1)),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('라이브 이벤트'), findsOneWidget);
      expect(find.text('모집 이벤트'), findsNothing);
      final liveChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'LIVE 1'),
      );
      expect(liveChip.selected, isTrue);
    });

    testWidgets('filter chips change visible lifecycle bucket', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(
        _buildPage(
          dashboardState: PartnerDashboardState(
            status: const AsyncValue.data(null),
            recruitingEvents: [
              _makeEvent(
                id: 'recruiting',
                title: '모집 이벤트',
                startTime: now.add(const Duration(days: 9)),
              ),
            ],
            liveEvents: [
              _makeEvent(
                id: 'live',
                title: '라이브 이벤트',
                startTime: now.subtract(const Duration(hours: 1)),
                endTime: now.add(const Duration(hours: 1)),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, '모집 중 1'));
      await tester.pumpAndSettle();

      expect(find.text('모집 이벤트'), findsOneWidget);
      expect(find.text('라이브 이벤트'), findsNothing);
    });

    testWidgets('empty selected filter can reset to all', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(
        _buildPage(
          initialFilter: 'live',
          dashboardState: PartnerDashboardState(
            status: const AsyncValue.data(null),
            recruitingEvents: [
              _makeEvent(
                id: 'recruiting',
                title: '모집 이벤트',
                startTime: now.add(const Duration(days: 9)),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('LIVE 이벤트가 없어요'), findsOneWidget);
      await tester.tap(find.text('전체 보기'));
      await tester.pumpAndSettle();

      expect(find.text('모집 이벤트'), findsOneWidget);
    });
  });
}
