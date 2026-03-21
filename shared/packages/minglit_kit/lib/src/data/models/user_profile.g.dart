// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => _UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      username: json['username'] as String,
      phoneNumber: json['phone_number'] as String?,
      gender: json['gender'] as String?,
      birthDate: json['birth_date'] == null
          ? null
          : DateTime.parse(json['birth_date'] as String),
      isVerified: json['is_verified'] as bool? ?? false,
      birthYear: (json['birth_year'] as num?)?.toInt(),
      avatarUrl: json['avatar_url'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$UserProfileToJson(_UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'username': instance.username,
      'phone_number': instance.phoneNumber,
      'gender': instance.gender,
      'birth_date': instance.birthDate?.toIso8601String(),
      'is_verified': instance.isVerified,
      'birth_year': instance.birthYear,
      'avatar_url': instance.avatarUrl,
      'profile_image_url': instance.profileImageUrl,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
