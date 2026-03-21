// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserProfile {
  String get id;
  String get name;
  String get username;
  @JsonKey(name: 'phone_number')
  String? get phoneNumber;
  String? get gender;
  @JsonKey(name: 'birth_date')
  DateTime? get birthDate;
  @JsonKey(name: 'is_verified')
  bool get isVerified;
  @JsonKey(name: 'birth_year')
  int? get birthYear;
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl;
  @JsonKey(name: 'profile_image_url')
  String? get profileImageUrl;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $UserProfileCopyWith<UserProfile> get copyWith =>
      _$UserProfileCopyWithImpl<UserProfile>(this as UserProfile, _$identity);

  /// Serializes this UserProfile to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is UserProfile &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.phoneNumber, phoneNumber) ||
                other.phoneNumber == phoneNumber) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.birthDate, birthDate) ||
                other.birthDate == birthDate) &&
            (identical(other.isVerified, isVerified) ||
                other.isVerified == isVerified) &&
            (identical(other.birthYear, birthYear) ||
                other.birthYear == birthYear) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.profileImageUrl, profileImageUrl) ||
                other.profileImageUrl == profileImageUrl) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      username,
      phoneNumber,
      gender,
      birthDate,
      isVerified,
      birthYear,
      avatarUrl,
      profileImageUrl,
      createdAt,
      updatedAt);

  @override
  String toString() {
    return 'UserProfile(id: $id, name: $name, username: $username, phoneNumber: $phoneNumber, gender: $gender, birthDate: $birthDate, isVerified: $isVerified, birthYear: $birthYear, avatarUrl: $avatarUrl, profileImageUrl: $profileImageUrl, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $UserProfileCopyWith<$Res> {
  factory $UserProfileCopyWith(
          UserProfile value, $Res Function(UserProfile) _then) =
      _$UserProfileCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String name,
      String username,
      @JsonKey(name: 'phone_number') String? phoneNumber,
      String? gender,
      @JsonKey(name: 'birth_date') DateTime? birthDate,
      @JsonKey(name: 'is_verified') bool isVerified,
      @JsonKey(name: 'birth_year') int? birthYear,
      @JsonKey(name: 'avatar_url') String? avatarUrl,
      @JsonKey(name: 'profile_image_url') String? profileImageUrl,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class _$UserProfileCopyWithImpl<$Res> implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._self, this._then);

  final UserProfile _self;
  final $Res Function(UserProfile) _then;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? username = null,
    Object? phoneNumber = freezed,
    Object? gender = freezed,
    Object? birthDate = freezed,
    Object? isVerified = null,
    Object? birthYear = freezed,
    Object? avatarUrl = freezed,
    Object? profileImageUrl = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      username: null == username
          ? _self.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      phoneNumber: freezed == phoneNumber
          ? _self.phoneNumber
          : phoneNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      gender: freezed == gender
          ? _self.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String?,
      birthDate: freezed == birthDate
          ? _self.birthDate
          : birthDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isVerified: null == isVerified
          ? _self.isVerified
          : isVerified // ignore: cast_nullable_to_non_nullable
              as bool,
      birthYear: freezed == birthYear
          ? _self.birthYear
          : birthYear // ignore: cast_nullable_to_non_nullable
              as int?,
      avatarUrl: freezed == avatarUrl
          ? _self.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      profileImageUrl: freezed == profileImageUrl
          ? _self.profileImageUrl
          : profileImageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// Adds pattern-matching-related methods to [UserProfile].
extension UserProfilePatterns on UserProfile {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_UserProfile value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _UserProfile() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_UserProfile value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UserProfile():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_UserProfile value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UserProfile() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String id,
            String name,
            String username,
            @JsonKey(name: 'phone_number') String? phoneNumber,
            String? gender,
            @JsonKey(name: 'birth_date') DateTime? birthDate,
            @JsonKey(name: 'is_verified') bool isVerified,
            @JsonKey(name: 'birth_year') int? birthYear,
            @JsonKey(name: 'avatar_url') String? avatarUrl,
            @JsonKey(name: 'profile_image_url') String? profileImageUrl,
            @JsonKey(name: 'created_at') DateTime? createdAt,
            @JsonKey(name: 'updated_at') DateTime? updatedAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _UserProfile() when $default != null:
        return $default(
            _that.id,
            _that.name,
            _that.username,
            _that.phoneNumber,
            _that.gender,
            _that.birthDate,
            _that.isVerified,
            _that.birthYear,
            _that.avatarUrl,
            _that.profileImageUrl,
            _that.createdAt,
            _that.updatedAt);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String id,
            String name,
            String username,
            @JsonKey(name: 'phone_number') String? phoneNumber,
            String? gender,
            @JsonKey(name: 'birth_date') DateTime? birthDate,
            @JsonKey(name: 'is_verified') bool isVerified,
            @JsonKey(name: 'birth_year') int? birthYear,
            @JsonKey(name: 'avatar_url') String? avatarUrl,
            @JsonKey(name: 'profile_image_url') String? profileImageUrl,
            @JsonKey(name: 'created_at') DateTime? createdAt,
            @JsonKey(name: 'updated_at') DateTime? updatedAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UserProfile():
        return $default(
            _that.id,
            _that.name,
            _that.username,
            _that.phoneNumber,
            _that.gender,
            _that.birthDate,
            _that.isVerified,
            _that.birthYear,
            _that.avatarUrl,
            _that.profileImageUrl,
            _that.createdAt,
            _that.updatedAt);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String id,
            String name,
            String username,
            @JsonKey(name: 'phone_number') String? phoneNumber,
            String? gender,
            @JsonKey(name: 'birth_date') DateTime? birthDate,
            @JsonKey(name: 'is_verified') bool isVerified,
            @JsonKey(name: 'birth_year') int? birthYear,
            @JsonKey(name: 'avatar_url') String? avatarUrl,
            @JsonKey(name: 'profile_image_url') String? profileImageUrl,
            @JsonKey(name: 'created_at') DateTime? createdAt,
            @JsonKey(name: 'updated_at') DateTime? updatedAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UserProfile() when $default != null:
        return $default(
            _that.id,
            _that.name,
            _that.username,
            _that.phoneNumber,
            _that.gender,
            _that.birthDate,
            _that.isVerified,
            _that.birthYear,
            _that.avatarUrl,
            _that.profileImageUrl,
            _that.createdAt,
            _that.updatedAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _UserProfile implements UserProfile {
  const _UserProfile(
      {required this.id,
      required this.name,
      required this.username,
      @JsonKey(name: 'phone_number') this.phoneNumber,
      this.gender,
      @JsonKey(name: 'birth_date') this.birthDate,
      @JsonKey(name: 'is_verified') this.isVerified = false,
      @JsonKey(name: 'birth_year') this.birthYear,
      @JsonKey(name: 'avatar_url') this.avatarUrl,
      @JsonKey(name: 'profile_image_url') this.profileImageUrl,
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'updated_at') this.updatedAt});
  factory _UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String username;
  @override
  @JsonKey(name: 'phone_number')
  final String? phoneNumber;
  @override
  final String? gender;
  @override
  @JsonKey(name: 'birth_date')
  final DateTime? birthDate;
  @override
  @JsonKey(name: 'is_verified')
  final bool isVerified;
  @override
  @JsonKey(name: 'birth_year')
  final int? birthYear;
  @override
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @override
  @JsonKey(name: 'profile_image_url')
  final String? profileImageUrl;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$UserProfileCopyWith<_UserProfile> get copyWith =>
      __$UserProfileCopyWithImpl<_UserProfile>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$UserProfileToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _UserProfile &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.phoneNumber, phoneNumber) ||
                other.phoneNumber == phoneNumber) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.birthDate, birthDate) ||
                other.birthDate == birthDate) &&
            (identical(other.isVerified, isVerified) ||
                other.isVerified == isVerified) &&
            (identical(other.birthYear, birthYear) ||
                other.birthYear == birthYear) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.profileImageUrl, profileImageUrl) ||
                other.profileImageUrl == profileImageUrl) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      username,
      phoneNumber,
      gender,
      birthDate,
      isVerified,
      birthYear,
      avatarUrl,
      profileImageUrl,
      createdAt,
      updatedAt);

  @override
  String toString() {
    return 'UserProfile(id: $id, name: $name, username: $username, phoneNumber: $phoneNumber, gender: $gender, birthDate: $birthDate, isVerified: $isVerified, birthYear: $birthYear, avatarUrl: $avatarUrl, profileImageUrl: $profileImageUrl, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$UserProfileCopyWith<$Res>
    implements $UserProfileCopyWith<$Res> {
  factory _$UserProfileCopyWith(
          _UserProfile value, $Res Function(_UserProfile) _then) =
      __$UserProfileCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String username,
      @JsonKey(name: 'phone_number') String? phoneNumber,
      String? gender,
      @JsonKey(name: 'birth_date') DateTime? birthDate,
      @JsonKey(name: 'is_verified') bool isVerified,
      @JsonKey(name: 'birth_year') int? birthYear,
      @JsonKey(name: 'avatar_url') String? avatarUrl,
      @JsonKey(name: 'profile_image_url') String? profileImageUrl,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class __$UserProfileCopyWithImpl<$Res> implements _$UserProfileCopyWith<$Res> {
  __$UserProfileCopyWithImpl(this._self, this._then);

  final _UserProfile _self;
  final $Res Function(_UserProfile) _then;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? username = null,
    Object? phoneNumber = freezed,
    Object? gender = freezed,
    Object? birthDate = freezed,
    Object? isVerified = null,
    Object? birthYear = freezed,
    Object? avatarUrl = freezed,
    Object? profileImageUrl = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_UserProfile(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      username: null == username
          ? _self.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      phoneNumber: freezed == phoneNumber
          ? _self.phoneNumber
          : phoneNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      gender: freezed == gender
          ? _self.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String?,
      birthDate: freezed == birthDate
          ? _self.birthDate
          : birthDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isVerified: null == isVerified
          ? _self.isVerified
          : isVerified // ignore: cast_nullable_to_non_nullable
              as bool,
      birthYear: freezed == birthYear
          ? _self.birthYear
          : birthYear // ignore: cast_nullable_to_non_nullable
              as int?,
      avatarUrl: freezed == avatarUrl
          ? _self.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      profileImageUrl: freezed == profileImageUrl
          ? _self.profileImageUrl
          : profileImageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
