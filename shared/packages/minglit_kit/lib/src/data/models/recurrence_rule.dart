import 'package:freezed_annotation/freezed_annotation.dart';

part 'recurrence_rule.freezed.dart';
part 'recurrence_rule.g.dart';

/// Repeat pattern for a recurrence rule.
enum RecurrencePattern {
  /// Every week on the specified days.
  @JsonValue('weekly')
  weekly,

  /// Every other week on the specified days.
  @JsonValue('biweekly')
  biweekly,

  /// Once a month on the specified day-of-month.
  @JsonValue('monthly')
  monthly,
}

/// Status of a recurrence rule lifecycle.
enum RecurrenceStatus {
  /// Rule is active — events are being generated.
  @JsonValue('active')
  active,

  /// Rule is paused — no new events until resumed.
  @JsonValue('paused')
  paused,

  /// Rule has been permanently cancelled.
  @JsonValue('cancelled')
  cancelled,
}

/// A recurrence rule that drives automatic event generation for a party.
///
/// Maps to the `recurrence_rules` table.
@freezed
abstract class RecurrenceRule with _$RecurrenceRule {
  /// Creates a [RecurrenceRule].
  const factory RecurrenceRule({
    required String id,
    @JsonKey(name: 'party_id') required String partyId,
    required RecurrencePattern pattern,
    @JsonKey(name: 'start_time') required String startTime,
    @JsonKey(name: 'end_time') required String endTime,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'days_of_week') @Default([]) List<int> daysOfWeek,
    @JsonKey(name: 'month_day') int? monthDay,
    @JsonKey(name: 'end_date') String? endDate,
    @Default(RecurrenceStatus.active) RecurrenceStatus status,
    @JsonKey(name: 'last_generated_date') String? lastGeneratedDate,
  }) = _RecurrenceRule;

  /// Creates a [RecurrenceRule] from a JSON map.
  factory RecurrenceRule.fromJson(Map<String, dynamic> json) =>
      _$RecurrenceRuleFromJson(json);
}
