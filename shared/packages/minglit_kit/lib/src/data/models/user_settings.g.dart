// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserSettings _$UserSettingsFromJson(Map<String, dynamic> json) =>
    _UserSettings(
      userId: json['user_id'] as String,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      marketingConsent: json['marketing_consent'] as bool? ?? false,
      serviceNotification: json['service_notification'] as bool? ?? true,
    );

Map<String, dynamic> _$UserSettingsToJson(_UserSettings instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'updated_at': instance.updatedAt.toIso8601String(),
      'marketing_consent': instance.marketingConsent,
      'service_notification': instance.serviceNotification,
    };
