// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'social_interaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SocialInteraction {
  String get userId;
  String get targetId;
  SocialTargetType get targetType;
  SocialInteractionType get interactionType;
  DateTime? get createdAt;

  /// Create a copy of SocialInteraction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SocialInteractionCopyWith<SocialInteraction> get copyWith =>
      _$SocialInteractionCopyWithImpl<SocialInteraction>(
          this as SocialInteraction, _$identity);

  /// Serializes this SocialInteraction to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SocialInteraction &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.targetId, targetId) ||
                other.targetId == targetId) &&
            (identical(other.targetType, targetType) ||
                other.targetType == targetType) &&
            (identical(other.interactionType, interactionType) ||
                other.interactionType == interactionType) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, userId, targetId, targetType, interactionType, createdAt);

  @override
  String toString() {
    return 'SocialInteraction(userId: $userId, targetId: $targetId, targetType: $targetType, interactionType: $interactionType, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class $SocialInteractionCopyWith<$Res> {
  factory $SocialInteractionCopyWith(
          SocialInteraction value, $Res Function(SocialInteraction) _then) =
      _$SocialInteractionCopyWithImpl;
  @useResult
  $Res call(
      {String userId,
      String targetId,
      SocialTargetType targetType,
      SocialInteractionType interactionType,
      DateTime? createdAt});
}

/// @nodoc
class _$SocialInteractionCopyWithImpl<$Res>
    implements $SocialInteractionCopyWith<$Res> {
  _$SocialInteractionCopyWithImpl(this._self, this._then);

  final SocialInteraction _self;
  final $Res Function(SocialInteraction) _then;

  /// Create a copy of SocialInteraction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? targetId = null,
    Object? targetType = null,
    Object? interactionType = null,
    Object? createdAt = freezed,
  }) {
    return _then(_self.copyWith(
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      targetId: null == targetId
          ? _self.targetId
          : targetId // ignore: cast_nullable_to_non_nullable
              as String,
      targetType: null == targetType
          ? _self.targetType
          : targetType // ignore: cast_nullable_to_non_nullable
              as SocialTargetType,
      interactionType: null == interactionType
          ? _self.interactionType
          : interactionType // ignore: cast_nullable_to_non_nullable
              as SocialInteractionType,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// Adds pattern-matching-related methods to [SocialInteraction].
extension SocialInteractionPatterns on SocialInteraction {
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
    TResult Function(_SocialInteraction value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SocialInteraction() when $default != null:
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
    TResult Function(_SocialInteraction value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SocialInteraction():
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
    TResult? Function(_SocialInteraction value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SocialInteraction() when $default != null:
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
            String userId,
            String targetId,
            SocialTargetType targetType,
            SocialInteractionType interactionType,
            DateTime? createdAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SocialInteraction() when $default != null:
        return $default(_that.userId, _that.targetId, _that.targetType,
            _that.interactionType, _that.createdAt);
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
            String userId,
            String targetId,
            SocialTargetType targetType,
            SocialInteractionType interactionType,
            DateTime? createdAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SocialInteraction():
        return $default(_that.userId, _that.targetId, _that.targetType,
            _that.interactionType, _that.createdAt);
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
            String userId,
            String targetId,
            SocialTargetType targetType,
            SocialInteractionType interactionType,
            DateTime? createdAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SocialInteraction() when $default != null:
        return $default(_that.userId, _that.targetId, _that.targetType,
            _that.interactionType, _that.createdAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _SocialInteraction implements SocialInteraction {
  const _SocialInteraction(
      {required this.userId,
      required this.targetId,
      required this.targetType,
      required this.interactionType,
      this.createdAt});
  factory _SocialInteraction.fromJson(Map<String, dynamic> json) =>
      _$SocialInteractionFromJson(json);

  @override
  final String userId;
  @override
  final String targetId;
  @override
  final SocialTargetType targetType;
  @override
  final SocialInteractionType interactionType;
  @override
  final DateTime? createdAt;

  /// Create a copy of SocialInteraction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SocialInteractionCopyWith<_SocialInteraction> get copyWith =>
      __$SocialInteractionCopyWithImpl<_SocialInteraction>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SocialInteractionToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SocialInteraction &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.targetId, targetId) ||
                other.targetId == targetId) &&
            (identical(other.targetType, targetType) ||
                other.targetType == targetType) &&
            (identical(other.interactionType, interactionType) ||
                other.interactionType == interactionType) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, userId, targetId, targetType, interactionType, createdAt);

  @override
  String toString() {
    return 'SocialInteraction(userId: $userId, targetId: $targetId, targetType: $targetType, interactionType: $interactionType, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class _$SocialInteractionCopyWith<$Res>
    implements $SocialInteractionCopyWith<$Res> {
  factory _$SocialInteractionCopyWith(
          _SocialInteraction value, $Res Function(_SocialInteraction) _then) =
      __$SocialInteractionCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String userId,
      String targetId,
      SocialTargetType targetType,
      SocialInteractionType interactionType,
      DateTime? createdAt});
}

/// @nodoc
class __$SocialInteractionCopyWithImpl<$Res>
    implements _$SocialInteractionCopyWith<$Res> {
  __$SocialInteractionCopyWithImpl(this._self, this._then);

  final _SocialInteraction _self;
  final $Res Function(_SocialInteraction) _then;

  /// Create a copy of SocialInteraction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? userId = null,
    Object? targetId = null,
    Object? targetType = null,
    Object? interactionType = null,
    Object? createdAt = freezed,
  }) {
    return _then(_SocialInteraction(
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      targetId: null == targetId
          ? _self.targetId
          : targetId // ignore: cast_nullable_to_non_nullable
              as String,
      targetType: null == targetType
          ? _self.targetType
          : targetType // ignore: cast_nullable_to_non_nullable
              as SocialTargetType,
      interactionType: null == interactionType
          ? _self.interactionType
          : interactionType // ignore: cast_nullable_to_non_nullable
              as SocialInteractionType,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
