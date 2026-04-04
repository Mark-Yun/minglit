import 'package:app_partner/src/features/party/event/create/event_create_controller.dart'
    show EventCreateController;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recurrence_settings_controller.freezed.dart';
part 'recurrence_settings_controller.g.dart';

@freezed
abstract class RecurrenceSettingsState with _$RecurrenceSettingsState {
  const factory RecurrenceSettingsState({
    /// Whether recurrence is enabled for the event being created.
    @Default(false) bool isEnabled,

    /// Repeat pattern (weekly / biweekly / monthly).
    @Default(RecurrencePattern.weekly) RecurrencePattern pattern,

    /// Days of week to generate events on (0=Sun … 6=Sat, JavaScript convention).
    /// Used for weekly and biweekly patterns.
    @Default([1]) List<int> daysOfWeek,

    /// Day of month (1–31) for monthly pattern.
    int? monthDay,

    /// Optional rule end date in YYYY-MM-DD format.
    String? endDate,
  }) = _RecurrenceSettingsState;
}

/// Manages the recurrence settings UI state for the event creation flow.
///
/// The controller is scoped to the event-create screen via [ProviderScope.overrides]
/// or via its auto-dispose lifetime. It computes preview dates without any
/// repository calls — submission is handled by [EventCreateController.submit].
@riverpod
class RecurrenceSettingsController extends _$RecurrenceSettingsController {
  @override
  RecurrenceSettingsState build() => const RecurrenceSettingsState();

  /// Toggles recurrence on or off.
  void toggle() => state = state.copyWith(isEnabled: !state.isEnabled);

  /// Changes the repeat pattern. Resets conflicting fields.
  void setPattern(RecurrencePattern pattern) {
    state = state.copyWith(
      pattern: pattern,
      // Clear monthly-specific field when switching away from monthly.
      monthDay: pattern == RecurrencePattern.monthly ? state.monthDay : null,
      // Keep at least one day selected for weekly/biweekly.
      daysOfWeek: pattern == RecurrencePattern.monthly ? [] : state.daysOfWeek,
    );
  }

  /// Adds or removes [day] (0=Sun … 6=Sat) from the selected days.
  /// Ignored when the active pattern is monthly.
  void toggleDay(int day) {
    if (state.pattern == RecurrencePattern.monthly) return;
    final days = List<int>.from(state.daysOfWeek);
    if (days.contains(day)) {
      days.remove(day);
    } else {
      days.add(day);
    }
    days.sort();
    state = state.copyWith(daysOfWeek: days);
  }

  /// Sets the day-of-month for monthly pattern (1–31).
  void setMonthDay(int day) => state = state.copyWith(monthDay: day);

  /// Sets the optional rule end date in YYYY-MM-DD format. Pass `null` to clear.
  void setEndDate(String? date) => state = state.copyWith(endDate: date);

  /// Returns the next [count] dates (from today) that match the current settings.
  ///
  /// Returns an empty list when recurrence is disabled or settings are invalid.
  List<DateTime> previewDates({int count = 5}) {
    if (!state.isEnabled) return [];
    if (state.pattern != RecurrencePattern.monthly &&
        state.daysOfWeek.isEmpty) {
      return [];
    }
    if (state.pattern == RecurrencePattern.monthly && state.monthDay == null) {
      return [];
    }

    final dates = <DateTime>[];
    final today = DateTime.now();
    final refDay = DateTime(today.year, today.month, today.day);
    var current = refDay;

    while (dates.length < count) {
      if (current.difference(refDay).inDays > 365) break;
      if (_matches(current, refDay)) dates.add(current);
      current = current.add(const Duration(days: 1));
    }
    return dates;
  }

  bool _matches(DateTime date, DateTime refDay) {
    // Flutter weekday: 1=Mon … 7=Sun  →  JS convention: 0=Sun … 6=Sat
    final jsDay = date.weekday % 7;

    switch (state.pattern) {
      case RecurrencePattern.weekly:
        return state.daysOfWeek.contains(jsDay);

      case RecurrencePattern.biweekly:
        if (!state.daysOfWeek.contains(jsDay)) return false;
        final diffDays = date.difference(refDay).inDays;
        return ((diffDays % 14) + 14) % 14 < 7;

      case RecurrencePattern.monthly:
        return state.monthDay != null && date.day == state.monthDay;
    }
  }
}
