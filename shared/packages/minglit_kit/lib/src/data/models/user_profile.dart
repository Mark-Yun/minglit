import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    required String name,
    required String username,
    @JsonKey(name: 'phone_number') String? phoneNumber,
    String? gender,
    @JsonKey(name: 'birth_date') DateTime? birthDate,
    @Default(false) @JsonKey(name: 'is_verified') bool isVerified,
    @JsonKey(name: 'birth_year') int? birthYear,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}
