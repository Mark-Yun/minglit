import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_settings.freezed.dart';
part 'user_settings.g.dart';

@freezed
abstract class UserSettings with _$UserSettings {
  const factory UserSettings({
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'marketing_consent') @Default(false) bool marketingConsent,
    @JsonKey(name: 'service_notification') @Default(true) bool serviceNotification,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _UserSettings;

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsFromJson(json);
}
