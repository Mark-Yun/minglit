// Fix #1644: RecurrenceRuleSummaryCard 위젯 렌더링 테스트
import 'package:app_partner/src/features/party/widgets/recurrence_rule_summary_card.dart';
import 'package:app_partner/src/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';

RecurrenceRule _makeRule({
  RecurrenceStatus status = RecurrenceStatus.active,
  RecurrencePattern pattern = RecurrencePattern.weekly,
  List<int> daysOfWeek = const [6],
  int? monthDay,
}) {
  return RecurrenceRule(
    id: 'rule-1',
    partyId: 'party-1',
    pattern: pattern,
    startTime: '19:00:00',
    endTime: '21:00:00',
    createdAt: DateTime(2026, 4),
    updatedAt: DateTime(2026, 4),
    daysOfWeek: daysOfWeek,
    monthDay: monthDay,
    status: status,
  );
}

Widget _buildTestWidget({
  required RecurrenceRule? rule,
  MockGoRouter? router,
}) {
  final mockRouter = router ?? MockGoRouter();
  when(() => mockRouter.push(any())).thenAnswer((_) => Future.value());

  return ProviderScope(
    overrides: [
      goRouterProvider.overrideWithValue(mockRouter),
      partyRecurrenceRuleProvider('party-1').overrideWith((_) async => rule),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: RecurrenceRuleSummaryCard(partyId: 'party-1'),
      ),
    ),
  );
}

void main() {
  group('RecurrenceRuleSummaryCard', () {
    testWidgets('renders nothing when rule is null', (tester) async {
      await tester.pumpWidget(_buildTestWidget(rule: null));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsNothing);
      expect(find.byIcon(Icons.event_repeat), findsNothing);
    });

    testWidgets('renders nothing when rule is cancelled', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(rule: _makeRule(status: RecurrenceStatus.cancelled)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsNothing);
    });

    testWidgets('renders card for active weekly rule', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          rule: _makeRule(
            daysOfWeek: [6, 0],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('매주 토, 일 · 19:00'), findsOneWidget);
      expect(find.text('활성'), findsOneWidget);
      expect(find.byIcon(Icons.event_repeat), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('renders card for paused rule', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(rule: _makeRule(status: RecurrenceStatus.paused)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('일시 정지'), findsOneWidget);
    });

    testWidgets('renders monthly rule with monthDay', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          rule: _makeRule(
            pattern: RecurrencePattern.monthly,
            daysOfWeek: [],
            monthDay: 15,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('매월 15일 · 19:00'), findsOneWidget);
    });

    testWidgets('tapping card navigates to recurrence management', (
      tester,
    ) async {
      final mockRouter = MockGoRouter();
      when(() => mockRouter.push(any())).thenAnswer((_) => Future.value());

      await tester.pumpWidget(
        _buildTestWidget(rule: _makeRule(), router: mockRouter),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      verify(
        () => mockRouter.push(
          any(that: contains('/recurrence')),
        ),
      ).called(1);
    });
  });
}
