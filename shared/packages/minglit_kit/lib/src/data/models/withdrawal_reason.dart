import 'package:freezed_annotation/freezed_annotation.dart';

part 'withdrawal_reason.freezed.dart';
part 'withdrawal_reason.g.dart';

/// Anonymous reason codes stored for account deletion analytics.
enum WithdrawalReasonCode {
  /// The user no longer needs Minglit.
  @JsonValue('no_longer_use')
  noLongerUse,

  /// The user could not find desired events.
  @JsonValue('no_desired_events')
  noDesiredEvents,

  /// The user is using another service instead.
  @JsonValue('using_other_service')
  usingOtherService,

  /// The user is concerned about privacy.
  @JsonValue('privacy_concern')
  privacyConcern,

  /// The user found the app difficult to use.
  @JsonValue('poor_usability')
  poorUsability,

  /// A custom free-text reason.
  @JsonValue('other')
  other,
}

/// Optional anonymous withdrawal reason payload.
@freezed
abstract class WithdrawalReason with _$WithdrawalReason {
  /// Creates a [WithdrawalReason].
  const factory WithdrawalReason({
    @JsonKey(name: 'reason_code') required WithdrawalReasonCode reasonCode,
    @JsonKey(name: 'reason_text') String? detail,
  }) = _WithdrawalReason;

  /// Creates a [WithdrawalReason] from JSON.
  factory WithdrawalReason.fromJson(Map<String, dynamic> json) =>
      _$WithdrawalReasonFromJson(json);
}
