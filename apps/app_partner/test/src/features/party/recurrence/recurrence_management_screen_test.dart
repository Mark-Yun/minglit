import 'package:app_partner/src/features/party/recurrence/recurrence_management_controller.dart';
import 'package:app_partner/src/features/party/recurrence/recurrence_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

class _MockRecurrenceRuleRepository extends Mock
    implements RecurrenceRuleRepository {}

RecurrenceRule _makeRule({RecurrenceStatus status = RecurrenceStatus.active}) {
  return RecurrenceRule(
    id: 'rule-1',
    partyId: 'party-1',
    pattern: RecurrencePattern.weekly,
    startTime: '18:00:00',
    endTime: '20:00:00',
    createdAt: DateTime(2026, 4),
    updatedAt: DateTime(2026, 4),
    daysOfWeek: [6],
    status: status,
  );
}

Widget _buildTestWidget({
  required RecurrenceRule? rule,
  _MockRecurrenceRuleRepository? repo,
}) {
  final mockRepo = repo ?? _MockRecurrenceRuleRepository();
  return ProviderScope(
    overrides: [
      recurrenceRuleRepositoryProvider.overrideWithValue(mockRepo),
      partyRecurrenceRuleProvider('party-1').overrideWith((_) async => rule),
    ],
    child: const MaterialApp(
      home: RecurrenceManagementScreen(partyId: 'party-1'),
    ),
  );
}

void main() {
  group('RecurrenceManagementScreen', () {
    testWidgets('shows empty state when no rule', (tester) async {
      await tester.pumpWidget(_buildTestWidget(rule: null));
      await tester.pumpAndSettle();
      expect(find.text('설정된 반복 규칙이 없습니다.'), findsOneWidget);
    });

    testWidgets('shows active rule with pause and cancel buttons', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestWidget(rule: _makeRule()));
      await tester.pumpAndSettle();
      expect(find.text('일시 정지'), findsOneWidget);
      expect(find.text('규칙 취소'), findsOneWidget);
    });

    testWidgets('shows paused rule with cancel and resume buttons', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestWidget(rule: _makeRule(status: RecurrenceStatus.paused)),
      );
      await tester.pumpAndSettle();
      expect(find.text('재개'), findsOneWidget);
      expect(find.text('규칙 취소'), findsOneWidget);
    });

    testWidgets('shows cancelled rule without action buttons', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(rule: _makeRule(status: RecurrenceStatus.cancelled)),
      );
      await tester.pumpAndSettle();
      expect(find.text('취소된 규칙은 재활성화할 수 없습니다.'), findsOneWidget);
      expect(find.text('일시 정지'), findsNothing);
      expect(find.text('재개'), findsNothing);
    });
  });
}
