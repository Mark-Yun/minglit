import 'package:app_partner/src/features/party/logic/recurrence_settings_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../../../../utils/test_utils.dart';

void main() {
  group('RecurrenceSettingsController', () {
    group('initial state', () {
      test('defaults: disabled, weekly, Monday selected', () {
        final container = createContainer();
        final state = container.read(recurrenceSettingsControllerProvider);

        expect(state.isEnabled, isFalse);
        expect(state.pattern, RecurrencePattern.weekly);
        expect(state.daysOfWeek, [1]);
        expect(state.monthDay, isNull);
        expect(state.endDate, isNull);
      });
    });

    group('toggle', () {
      test('toggles isEnabled from false to true', () {
        final container = createContainer();
        final notifier =
            container.read(recurrenceSettingsControllerProvider.notifier);

        notifier.toggle();

        expect(
            container.read(recurrenceSettingsControllerProvider).isEnabled,
            isTrue);
      });

      test('toggles isEnabled from true to false', () {
        final container = createContainer();
        final notifier =
            container.read(recurrenceSettingsControllerProvider.notifier);

        notifier.toggle();
        notifier.toggle();

        expect(
            container.read(recurrenceSettingsControllerProvider).isEnabled,
            isFalse);
      });
    });

    group('setPattern', () {
      test('switches to biweekly, keeps daysOfWeek', () {
        final container = createContainer();
        final notifier =
            container.read(recurrenceSettingsControllerProvider.notifier);

        notifier.setPattern(RecurrencePattern.biweekly);

        final state = container.read(recurrenceSettingsControllerProvider);
        expect(state.pattern, RecurrencePattern.biweekly);
        expect(state.daysOfWeek, [1]); // kept
        expect(state.monthDay, isNull);
      });

      test('switches to monthly, clears daysOfWeek', () {
        final container = createContainer();
        final notifier =
            container.read(recurrenceSettingsControllerProvider.notifier);

        notifier.setPattern(RecurrencePattern.monthly);

        final state = container.read(recurrenceSettingsControllerProvider);
        expect(state.pattern, RecurrencePattern.monthly);
        expect(state.daysOfWeek, isEmpty);
        expect(state.monthDay, isNull);
      });

      test('switches from monthly back to weekly, resets daysOfWeek to empty', () {
        final container = createContainer();
        final notifier =
            container.read(recurrenceSettingsControllerProvider.notifier);

        notifier.setPattern(RecurrencePattern.monthly);
        notifier.setMonthDay(15);
        notifier.setPattern(RecurrencePattern.weekly);

        final state = container.read(recurrenceSettingsControllerProvider);
        expect(state.pattern, RecurrencePattern.weekly);
        expect(state.monthDay, isNull); // cleared
      });
    });

    group('toggleDay', () {
      test('adds a new day', () {
        final container = createContainer();
        final notifier =
            container.read(recurrenceSettingsControllerProvider.notifier);

        notifier.toggleDay(3); // Wednesday

        expect(
            container.read(recurrenceSettingsControllerProvider).daysOfWeek,
            containsAll([1, 3]));
      });

      test('removes an existing day', () {
        final container = createContainer();
        final notifier =
            container.read(recurrenceSettingsControllerProvider.notifier);

        notifier.toggleDay(1); // remove Monday (initially selected)

        expect(
            container.read(recurrenceSettingsControllerProvider).daysOfWeek,
            isEmpty);
      });

      test('keeps days sorted after adding', () {
        final container = createContainer();
        final notifier =
            container.read(recurrenceSettingsControllerProvider.notifier);

        notifier.toggleDay(5); // Friday
        notifier.toggleDay(2); // Tuesday

        expect(
            container.read(recurrenceSettingsControllerProvider).daysOfWeek,
            [1, 2, 5]);
      });

      test('ignored when pattern is monthly', () {
        final container = createContainer();
        final notifier =
            container.read(recurrenceSettingsControllerProvider.notifier);

        notifier.setPattern(RecurrencePattern.monthly);
        notifier.toggleDay(3);

        expect(
            container.read(recurrenceSettingsControllerProvider).daysOfWeek,
            isEmpty);
      });
    });

    group('setMonthDay', () {
      test('sets monthDay', () {
        final container = createContainer();
        final notifier =
            container.read(recurrenceSettingsControllerProvider.notifier);

        notifier.setMonthDay(15);

        expect(
            container.read(recurrenceSettingsControllerProvider).monthDay, 15);
      });
    });

    group('setEndDate', () {
      test('sets endDate string', () {
        final container = createContainer();
        final notifier =
            container.read(recurrenceSettingsControllerProvider.notifier);

        notifier.setEndDate('2026-12-31');

        expect(
            container.read(recurrenceSettingsControllerProvider).endDate,
            '2026-12-31');
      });

      test('clears endDate with null', () {
        final container = createContainer();
        final notifier =
            container.read(recurrenceSettingsControllerProvider.notifier);

        notifier.setEndDate('2026-12-31');
        notifier.setEndDate(null);

        expect(
            container.read(recurrenceSettingsControllerProvider).endDate,
            isNull);
      });
    });

    group('previewDates', () {
      test('returns empty list when disabled', () {
        final container = createContainer();
        final notifier =
            container.read(recurrenceSettingsControllerProvider.notifier);

        final dates = notifier.previewDates();

        expect(dates, isEmpty);
      });

      test('returns empty list when enabled but no days selected', () {
        final container = createContainer();
        final notifier =
            container.read(recurrenceSettingsControllerProvider.notifier);

        notifier.toggle();
        notifier.toggleDay(1); // remove Monday (default), leaving empty

        final dates = notifier.previewDates();

        expect(dates, isEmpty);
      });

      test('returns 5 dates for weekly pattern with Monday selected', () {
        final container = createContainer();
        final notifier =
            container.read(recurrenceSettingsControllerProvider.notifier);

        notifier.toggle(); // enable
        // default: weekly, Monday (day 1)

        final dates = notifier.previewDates(count: 5);

        expect(dates, hasLength(5));
        // All dates must be Mondays (weekday == 1)
        for (final d in dates) {
          expect(d.weekday, 1, reason: '$d should be a Monday');
        }
      });

      test('returns 5 dates for biweekly — every other week', () {
        final container = createContainer();
        final notifier =
            container.read(recurrenceSettingsControllerProvider.notifier);

        notifier.toggle();
        notifier.setPattern(RecurrencePattern.biweekly);
        // default daysOfWeek: [1] Monday

        final dates = notifier.previewDates(count: 5);

        expect(dates, hasLength(5));
        // Consecutive Mondays should be 14 days apart (not 7)
        for (int i = 1; i < dates.length; i++) {
          expect(dates[i].difference(dates[i - 1]).inDays, 14);
        }
      });

      test('returns 5 dates for monthly pattern on the 15th', () {
        final container = createContainer();
        final notifier =
            container.read(recurrenceSettingsControllerProvider.notifier);

        notifier.toggle();
        notifier.setPattern(RecurrencePattern.monthly);
        notifier.setMonthDay(15);

        final dates = notifier.previewDates(count: 5);

        expect(dates, hasLength(5));
        for (final d in dates) {
          expect(d.day, 15, reason: '$d should be on the 15th');
        }
      });

      test('returns empty list for monthly with no monthDay', () {
        final container = createContainer();
        final notifier =
            container.read(recurrenceSettingsControllerProvider.notifier);

        notifier.toggle();
        notifier.setPattern(RecurrencePattern.monthly);
        // monthDay is null

        final dates = notifier.previewDates();

        expect(dates, isEmpty);
      });

      test('previewDates are sorted ascending', () {
        final container = createContainer();
        final notifier =
            container.read(recurrenceSettingsControllerProvider.notifier);

        notifier.toggle();
        notifier.toggleDay(5); // add Friday (JS: 5)

        final dates = notifier.previewDates(count: 10);

        for (int i = 1; i < dates.length; i++) {
          expect(dates[i].isAfter(dates[i - 1]), isTrue);
        }
      });
    });
  });
}
