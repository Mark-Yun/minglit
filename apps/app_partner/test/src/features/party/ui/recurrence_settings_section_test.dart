import 'package:app_partner/src/features/party/logic/recurrence_settings_controller.dart';
import 'package:app_partner/src/features/party/ui/recurrence_settings_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // for ProviderScope, ConsumerWidget
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

Widget _wrap({List<dynamic> overrides = const []}) {
  return ProviderScope(
    overrides: overrides.cast(),
    child: const MaterialApp(
      home: Scaffold(
        body: RecurrenceSettingsSection(),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  group('RecurrenceSettingsSection', () {
    testWidgets('renders toggle with label in collapsed state', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.text('반복 일정'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsOneWidget);
    });

    testWidgets('pattern chips hidden when toggle is off', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.text('반복 주기'), findsNothing);
      expect(find.text('매주'), findsNothing);
    });

    testWidgets('tapping toggle shows pattern chips', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();

      expect(find.text('반복 주기'), findsOneWidget);
      expect(find.text('매주'), findsOneWidget);
      expect(find.text('격주'), findsOneWidget);
      expect(find.text('매월'), findsOneWidget);
    });

    testWidgets('day-of-week chips visible for weekly pattern', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();

      expect(find.text('요일 선택'), findsOneWidget);
      // All days should be visible
      expect(find.text('월'), findsOneWidget);
      expect(find.text('화'), findsOneWidget);
      expect(find.text('수'), findsOneWidget);
    });

    testWidgets('switching to monthly shows month-day dropdown', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();

      // Tap '매월' ChoiceChip
      await tester.tap(find.text('매월'));
      await tester.pump();

      expect(find.text('매월 반복일'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
      expect(find.text('요일 선택'), findsNothing);
    });

    testWidgets('preview message shown when no day selected', (tester) async {
      await tester.pumpWidget(
        _wrap(
          overrides: [
            recurrenceSettingsControllerProvider.overrideWith(
              RecurrenceSettingsController.new,
            ),
          ],
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();

      // The default state has Monday selected, so preview dates should appear
      // Remove Monday by tapping '월' FilterChip
      await tester.tap(find.text('월'));
      await tester.pump();

      expect(
        find.text('요일 또는 날짜를 선택하면 미리보기가 표시됩니다'),
        findsOneWidget,
      );
    });

    testWidgets('end date row is visible when enabled', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();

      expect(find.text('종료일 (선택)'), findsOneWidget);
    });
  });
}
