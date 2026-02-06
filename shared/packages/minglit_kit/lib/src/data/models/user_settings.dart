import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_settings.freezed.dart';
part 'user_settings.g.dart';

/// Stores per-user notification and consent settings.
@freezed
abstract class UserSettings with _$UserSettings {
  /// Creates a [UserSettings] record.
  const factory UserSettings({
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'marketing_consent') @Default(false) bool marketingConsent,
    @JsonKey(name: 'service_notification')
    @Default(true)
    bool serviceNotification,
  }) = _UserSettings;

  /// Creates a [UserSettings] from a JSON map.
  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsFromJson(json);
}
