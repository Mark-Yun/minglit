// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'verification_submission.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VerificationSubmission {
  String get id;
  @JsonKey(name: 'partner_id')
  String get partnerId;
  @JsonKey(name: 'user_id')
  String get userId;
  @JsonKey(name: 'verification_id')
  String get verificationId;
  VerificationStatus get status;
  @JsonKey(name: 'snapshot_data')
  Map<String, dynamic> get snapshotData;
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt;
  @JsonKey(name: 'application_id')
  String? get applicationId;
  @JsonKey(name: 'admin_comment')
  String? get adminComment;
  @JsonKey(name: 'reviewed_at')
  DateTime? get reviewedAt;
  @JsonKey(name: 'reviewed_by')
  String? get reviewedBy;

  /// Create a copy of VerificationSubmission
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $VerificationSubmissionCopyWith<VerificationSubmission> get copyWith =>
      _$VerificationSubmissionCopyWithImpl<VerificationSubmission>(
          this as VerificationSubmission, _$identity);

  /// Serializes this VerificationSubmission to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is VerificationSubmission &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.partnerId, partnerId) ||
                other.partnerId == partnerId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.verificationId, verificationId) ||
                other.verificationId == verificationId) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality()
                .equals(other.snapshotData, snapshotData) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.applicationId, applicationId) ||
                other.applicationId == applicationId) &&
            (identical(other.adminComment, adminComment) ||
                other.adminComment == adminComment) &&
            (identical(other.reviewedAt, reviewedAt) ||
                other.reviewedAt == reviewedAt) &&
            (identical(other.reviewedBy, reviewedBy) ||
                other.reviewedBy == reviewedBy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      partnerId,
      userId,
      verificationId,
      status,
      const DeepCollectionEquality().hash(snapshotData),
      createdAt,
      updatedAt,
      applicationId,
      adminComment,
      reviewedAt,
      reviewedBy);

  @override
  String toString() {
    return 'VerificationSubmission(id: $id, partnerId: $partnerId, userId: $userId, verificationId: $verificationId, status: $status, snapshotData: $snapshotData, createdAt: $createdAt, updatedAt: $updatedAt, applicationId: $applicationId, adminComment: $adminComment, reviewedAt: $reviewedAt, reviewedBy: $reviewedBy)';
  }
}

/// @nodoc
abstract mixin class $VerificationSubmissionCopyWith<$Res> {
  factory $VerificationSubmissionCopyWith(VerificationSubmission value,
          $Res Function(VerificationSubmission) _then) =
      _$VerificationSubmissionCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'partner_id') String partnerId,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'verification_id') String verificationId,
      VerificationStatus status,
      @JsonKey(name: 'snapshot_data') Map<String, dynamic> snapshotData,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt,
      @JsonKey(name: 'application_id') String? applicationId,
      @JsonKey(name: 'admin_comment') String? adminComment,
      @JsonKey(name: 'reviewed_at') DateTime? reviewedAt,
      @JsonKey(name: 'reviewed_by') String? reviewedBy});
}

/// @nodoc
class _$VerificationSubmissionCopyWithImpl<$Res>
    implements $VerificationSubmissionCopyWith<$Res> {
  _$VerificationSubmissionCopyWithImpl(this._self, this._then);

  final VerificationSubmission _self;
  final $Res Function(VerificationSubmission) _then;

  /// Create a copy of VerificationSubmission
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? partnerId = null,
    Object? userId = null,
    Object? verificationId = null,
    Object? status = null,
    Object? snapshotData = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? applicationId = freezed,
    Object? adminComment = freezed,
    Object? reviewedAt = freezed,
    Object? reviewedBy = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      partnerId: null == partnerId
          ? _self.partnerId
          : partnerId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      verificationId: null == verificationId
          ? _self.verificationId
          : verificationId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as VerificationStatus,
      snapshotData: null == snapshotData
          ? _self.snapshotData
          : snapshotData // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      applicationId: freezed == applicationId
          ? _self.applicationId
          : applicationId // ignore: cast_nullable_to_non_nullable
              as String?,
      adminComment: freezed == adminComment
          ? _self.adminComment
          : adminComment // ignore: cast_nullable_to_non_nullable
              as String?,
      reviewedAt: freezed == reviewedAt
          ? _self.reviewedAt
          : reviewedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      reviewedBy: freezed == reviewedBy
          ? _self.reviewedBy
          : reviewedBy // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [VerificationSubmission].
extension VerificationSubmissionPatterns on VerificationSubmission {
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
    TResult Function(_VerificationSubmission value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _VerificationSubmission() when $default != null:
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
    TResult Function(_VerificationSubmission value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _VerificationSubmission():
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
    TResult? Function(_VerificationSubmission value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _VerificationSubmission() when $default != null:
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
            @JsonKey(name: 'partner_id') String partnerId,
            @JsonKey(name: 'user_id') String userId,
            @JsonKey(name: 'verification_id') String verificationId,
            VerificationStatus status,
            @JsonKey(name: 'snapshot_data') Map<String, dynamic> snapshotData,
            @JsonKey(name: 'created_at') DateTime createdAt,
            @JsonKey(name: 'updated_at') DateTime updatedAt,
            @JsonKey(name: 'application_id') String? applicationId,
            @JsonKey(name: 'admin_comment') String? adminComment,
            @JsonKey(name: 'reviewed_at') DateTime? reviewedAt,
            @JsonKey(name: 'reviewed_by') String? reviewedBy)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _VerificationSubmission() when $default != null:
        return $default(
            _that.id,
            _that.partnerId,
            _that.userId,
            _that.verificationId,
            _that.status,
            _that.snapshotData,
            _that.createdAt,
            _that.updatedAt,
            _that.applicationId,
            _that.adminComment,
            _that.reviewedAt,
            _that.reviewedBy);
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
            @JsonKey(name: 'partner_id') String partnerId,
            @JsonKey(name: 'user_id') String userId,
            @JsonKey(name: 'verification_id') String verificationId,
            VerificationStatus status,
            @JsonKey(name: 'snapshot_data') Map<String, dynamic> snapshotData,
            @JsonKey(name: 'created_at') DateTime createdAt,
            @JsonKey(name: 'updated_at') DateTime updatedAt,
            @JsonKey(name: 'application_id') String? applicationId,
            @JsonKey(name: 'admin_comment') String? adminComment,
            @JsonKey(name: 'reviewed_at') DateTime? reviewedAt,
            @JsonKey(name: 'reviewed_by') String? reviewedBy)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _VerificationSubmission():
        return $default(
            _that.id,
            _that.partnerId,
            _that.userId,
            _that.verificationId,
            _that.status,
            _that.snapshotData,
            _that.createdAt,
            _that.updatedAt,
            _that.applicationId,
            _that.adminComment,
            _that.reviewedAt,
            _that.reviewedBy);
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
            @JsonKey(name: 'partner_id') String partnerId,
            @JsonKey(name: 'user_id') String userId,
            @JsonKey(name: 'verification_id') String verificationId,
            VerificationStatus status,
            @JsonKey(name: 'snapshot_data') Map<String, dynamic> snapshotData,
            @JsonKey(name: 'created_at') DateTime createdAt,
            @JsonKey(name: 'updated_at') DateTime updatedAt,
            @JsonKey(name: 'application_id') String? applicationId,
            @JsonKey(name: 'admin_comment') String? adminComment,
            @JsonKey(name: 'reviewed_at') DateTime? reviewedAt,
            @JsonKey(name: 'reviewed_by') String? reviewedBy)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _VerificationSubmission() when $default != null:
        return $default(
            _that.id,
            _that.partnerId,
            _that.userId,
            _that.verificationId,
            _that.status,
            _that.snapshotData,
            _that.createdAt,
            _that.updatedAt,
            _that.applicationId,
            _that.adminComment,
            _that.reviewedAt,
            _that.reviewedBy);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _VerificationSubmission implements VerificationSubmission {
  const _VerificationSubmission(
      {required this.id,
      @JsonKey(name: 'partner_id') required this.partnerId,
      @JsonKey(name: 'user_id') required this.userId,
      @JsonKey(name: 'verification_id') required this.verificationId,
      required this.status,
      @JsonKey(name: 'snapshot_data')
      required final Map<String, dynamic> snapshotData,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'updated_at') required this.updatedAt,
      @JsonKey(name: 'application_id') this.applicationId,
      @JsonKey(name: 'admin_comment') this.adminComment,
      @JsonKey(name: 'reviewed_at') this.reviewedAt,
      @JsonKey(name: 'reviewed_by') this.reviewedBy})
      : _snapshotData = snapshotData;
  factory _VerificationSubmission.fromJson(Map<String, dynamic> json) =>
      _$VerificationSubmissionFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'partner_id')
  final String partnerId;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @JsonKey(name: 'verification_id')
  final String verificationId;
  @override
  final VerificationStatus status;
  final Map<String, dynamic> _snapshotData;
  @override
  @JsonKey(name: 'snapshot_data')
  Map<String, dynamic> get snapshotData {
    if (_snapshotData is EqualUnmodifiableMapView) return _snapshotData;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_snapshotData);
  }

  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @override
  @JsonKey(name: 'application_id')
  final String? applicationId;
  @override
  @JsonKey(name: 'admin_comment')
  final String? adminComment;
  @override
  @JsonKey(name: 'reviewed_at')
  final DateTime? reviewedAt;
  @override
  @JsonKey(name: 'reviewed_by')
  final String? reviewedBy;

  /// Create a copy of VerificationSubmission
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$VerificationSubmissionCopyWith<_VerificationSubmission> get copyWith =>
      __$VerificationSubmissionCopyWithImpl<_VerificationSubmission>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$VerificationSubmissionToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _VerificationSubmission &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.partnerId, partnerId) ||
                other.partnerId == partnerId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.verificationId, verificationId) ||
                other.verificationId == verificationId) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality()
                .equals(other._snapshotData, _snapshotData) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.applicationId, applicationId) ||
                other.applicationId == applicationId) &&
            (identical(other.adminComment, adminComment) ||
                other.adminComment == adminComment) &&
            (identical(other.reviewedAt, reviewedAt) ||
                other.reviewedAt == reviewedAt) &&
            (identical(other.reviewedBy, reviewedBy) ||
                other.reviewedBy == reviewedBy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      partnerId,
      userId,
      verificationId,
      status,
      const DeepCollectionEquality().hash(_snapshotData),
      createdAt,
      updatedAt,
      applicationId,
      adminComment,
      reviewedAt,
      reviewedBy);

  @override
  String toString() {
    return 'VerificationSubmission(id: $id, partnerId: $partnerId, userId: $userId, verificationId: $verificationId, status: $status, snapshotData: $snapshotData, createdAt: $createdAt, updatedAt: $updatedAt, applicationId: $applicationId, adminComment: $adminComment, reviewedAt: $reviewedAt, reviewedBy: $reviewedBy)';
  }
}

/// @nodoc
abstract mixin class _$VerificationSubmissionCopyWith<$Res>
    implements $VerificationSubmissionCopyWith<$Res> {
  factory _$VerificationSubmissionCopyWith(_VerificationSubmission value,
          $Res Function(_VerificationSubmission) _then) =
      __$VerificationSubmissionCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'partner_id') String partnerId,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'verification_id') String verificationId,
      VerificationStatus status,
      @JsonKey(name: 'snapshot_data') Map<String, dynamic> snapshotData,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt,
      @JsonKey(name: 'application_id') String? applicationId,
      @JsonKey(name: 'admin_comment') String? adminComment,
      @JsonKey(name: 'reviewed_at') DateTime? reviewedAt,
      @JsonKey(name: 'reviewed_by') String? reviewedBy});
}

/// @nodoc
class __$VerificationSubmissionCopyWithImpl<$Res>
    implements _$VerificationSubmissionCopyWith<$Res> {
  __$VerificationSubmissionCopyWithImpl(this._self, this._then);

  final _VerificationSubmission _self;
  final $Res Function(_VerificationSubmission) _then;

  /// Create a copy of VerificationSubmission
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? partnerId = null,
    Object? userId = null,
    Object? verificationId = null,
    Object? status = null,
    Object? snapshotData = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? applicationId = freezed,
    Object? adminComment = freezed,
    Object? reviewedAt = freezed,
    Object? reviewedBy = freezed,
  }) {
    return _then(_VerificationSubmission(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      partnerId: null == partnerId
          ? _self.partnerId
          : partnerId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      verificationId: null == verificationId
          ? _self.verificationId
          : verificationId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as VerificationStatus,
      snapshotData: null == snapshotData
          ? _self._snapshotData
          : snapshotData // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      applicationId: freezed == applicationId
          ? _self.applicationId
          : applicationId // ignore: cast_nullable_to_non_nullable
              as String?,
      adminComment: freezed == adminComment
          ? _self.adminComment
          : adminComment // ignore: cast_nullable_to_non_nullable
              as String?,
      reviewedAt: freezed == reviewedAt
          ? _self.reviewedAt
          : reviewedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      reviewedBy: freezed == reviewedBy
          ? _self.reviewedBy
          : reviewedBy // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
