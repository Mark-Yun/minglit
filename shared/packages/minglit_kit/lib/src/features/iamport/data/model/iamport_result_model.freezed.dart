// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'iamport_result_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$IamportResultModel {
  @JsonKey(name: 'imp_uid')
  String? get impUid;
  @JsonKey(name: 'merchant_uid')
  String? get merchantUid;
  @JsonKey(name: 'success')
  bool get success;
  @JsonKey(name: 'error_msg')
  String? get errorMsg;
  @JsonKey(name: 'pg_provider')
  String? get pgProvider;
  @JsonKey(name: 'pg_type')
  String? get pgType;

  /// Create a copy of IamportResultModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $IamportResultModelCopyWith<IamportResultModel> get copyWith =>
      _$IamportResultModelCopyWithImpl<IamportResultModel>(
          this as IamportResultModel, _$identity);

  /// Serializes this IamportResultModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is IamportResultModel &&
            (identical(other.impUid, impUid) || other.impUid == impUid) &&
            (identical(other.merchantUid, merchantUid) ||
                other.merchantUid == merchantUid) &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.errorMsg, errorMsg) ||
                other.errorMsg == errorMsg) &&
            (identical(other.pgProvider, pgProvider) ||
                other.pgProvider == pgProvider) &&
            (identical(other.pgType, pgType) || other.pgType == pgType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, impUid, merchantUid, success, errorMsg, pgProvider, pgType);

  @override
  String toString() {
    return 'IamportResultModel(impUid: $impUid, merchantUid: $merchantUid, success: $success, errorMsg: $errorMsg, pgProvider: $pgProvider, pgType: $pgType)';
  }
}

/// @nodoc
abstract mixin class $IamportResultModelCopyWith<$Res> {
  factory $IamportResultModelCopyWith(
          IamportResultModel value, $Res Function(IamportResultModel) _then) =
      _$IamportResultModelCopyWithImpl;
  @useResult
  $Res call(
      {@JsonKey(name: 'imp_uid') String? impUid,
      @JsonKey(name: 'merchant_uid') String? merchantUid,
      @JsonKey(name: 'success') bool success,
      @JsonKey(name: 'error_msg') String? errorMsg,
      @JsonKey(name: 'pg_provider') String? pgProvider,
      @JsonKey(name: 'pg_type') String? pgType});
}

/// @nodoc
class _$IamportResultModelCopyWithImpl<$Res>
    implements $IamportResultModelCopyWith<$Res> {
  _$IamportResultModelCopyWithImpl(this._self, this._then);

  final IamportResultModel _self;
  final $Res Function(IamportResultModel) _then;

  /// Create a copy of IamportResultModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? impUid = freezed,
    Object? merchantUid = freezed,
    Object? success = null,
    Object? errorMsg = freezed,
    Object? pgProvider = freezed,
    Object? pgType = freezed,
  }) {
    return _then(_self.copyWith(
      impUid: freezed == impUid
          ? _self.impUid
          : impUid // ignore: cast_nullable_to_non_nullable
              as String?,
      merchantUid: freezed == merchantUid
          ? _self.merchantUid
          : merchantUid // ignore: cast_nullable_to_non_nullable
              as String?,
      success: null == success
          ? _self.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMsg: freezed == errorMsg
          ? _self.errorMsg
          : errorMsg // ignore: cast_nullable_to_non_nullable
              as String?,
      pgProvider: freezed == pgProvider
          ? _self.pgProvider
          : pgProvider // ignore: cast_nullable_to_non_nullable
              as String?,
      pgType: freezed == pgType
          ? _self.pgType
          : pgType // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [IamportResultModel].
extension IamportResultModelPatterns on IamportResultModel {
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
    TResult Function(_IamportResultModel value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _IamportResultModel() when $default != null:
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
    TResult Function(_IamportResultModel value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _IamportResultModel():
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
    TResult? Function(_IamportResultModel value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _IamportResultModel() when $default != null:
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
            @JsonKey(name: 'imp_uid') String? impUid,
            @JsonKey(name: 'merchant_uid') String? merchantUid,
            @JsonKey(name: 'success') bool success,
            @JsonKey(name: 'error_msg') String? errorMsg,
            @JsonKey(name: 'pg_provider') String? pgProvider,
            @JsonKey(name: 'pg_type') String? pgType)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _IamportResultModel() when $default != null:
        return $default(_that.impUid, _that.merchantUid, _that.success,
            _that.errorMsg, _that.pgProvider, _that.pgType);
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
            @JsonKey(name: 'imp_uid') String? impUid,
            @JsonKey(name: 'merchant_uid') String? merchantUid,
            @JsonKey(name: 'success') bool success,
            @JsonKey(name: 'error_msg') String? errorMsg,
            @JsonKey(name: 'pg_provider') String? pgProvider,
            @JsonKey(name: 'pg_type') String? pgType)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _IamportResultModel():
        return $default(_that.impUid, _that.merchantUid, _that.success,
            _that.errorMsg, _that.pgProvider, _that.pgType);
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
            @JsonKey(name: 'imp_uid') String? impUid,
            @JsonKey(name: 'merchant_uid') String? merchantUid,
            @JsonKey(name: 'success') bool success,
            @JsonKey(name: 'error_msg') String? errorMsg,
            @JsonKey(name: 'pg_provider') String? pgProvider,
            @JsonKey(name: 'pg_type') String? pgType)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _IamportResultModel() when $default != null:
        return $default(_that.impUid, _that.merchantUid, _that.success,
            _that.errorMsg, _that.pgProvider, _that.pgType);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _IamportResultModel extends IamportResultModel {
  const _IamportResultModel(
      {@JsonKey(name: 'imp_uid') this.impUid,
      @JsonKey(name: 'merchant_uid') this.merchantUid,
      @JsonKey(name: 'success') this.success = false,
      @JsonKey(name: 'error_msg') this.errorMsg,
      @JsonKey(name: 'pg_provider') this.pgProvider,
      @JsonKey(name: 'pg_type') this.pgType})
      : super._();
  factory _IamportResultModel.fromJson(Map<String, dynamic> json) =>
      _$IamportResultModelFromJson(json);

  @override
  @JsonKey(name: 'imp_uid')
  final String? impUid;
  @override
  @JsonKey(name: 'merchant_uid')
  final String? merchantUid;
  @override
  @JsonKey(name: 'success')
  final bool success;
  @override
  @JsonKey(name: 'error_msg')
  final String? errorMsg;
  @override
  @JsonKey(name: 'pg_provider')
  final String? pgProvider;
  @override
  @JsonKey(name: 'pg_type')
  final String? pgType;

  /// Create a copy of IamportResultModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$IamportResultModelCopyWith<_IamportResultModel> get copyWith =>
      __$IamportResultModelCopyWithImpl<_IamportResultModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$IamportResultModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _IamportResultModel &&
            (identical(other.impUid, impUid) || other.impUid == impUid) &&
            (identical(other.merchantUid, merchantUid) ||
                other.merchantUid == merchantUid) &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.errorMsg, errorMsg) ||
                other.errorMsg == errorMsg) &&
            (identical(other.pgProvider, pgProvider) ||
                other.pgProvider == pgProvider) &&
            (identical(other.pgType, pgType) || other.pgType == pgType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, impUid, merchantUid, success, errorMsg, pgProvider, pgType);

  @override
  String toString() {
    return 'IamportResultModel(impUid: $impUid, merchantUid: $merchantUid, success: $success, errorMsg: $errorMsg, pgProvider: $pgProvider, pgType: $pgType)';
  }
}

/// @nodoc
abstract mixin class _$IamportResultModelCopyWith<$Res>
    implements $IamportResultModelCopyWith<$Res> {
  factory _$IamportResultModelCopyWith(
          _IamportResultModel value, $Res Function(_IamportResultModel) _then) =
      __$IamportResultModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'imp_uid') String? impUid,
      @JsonKey(name: 'merchant_uid') String? merchantUid,
      @JsonKey(name: 'success') bool success,
      @JsonKey(name: 'error_msg') String? errorMsg,
      @JsonKey(name: 'pg_provider') String? pgProvider,
      @JsonKey(name: 'pg_type') String? pgType});
}

/// @nodoc
class __$IamportResultModelCopyWithImpl<$Res>
    implements _$IamportResultModelCopyWith<$Res> {
  __$IamportResultModelCopyWithImpl(this._self, this._then);

  final _IamportResultModel _self;
  final $Res Function(_IamportResultModel) _then;

  /// Create a copy of IamportResultModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? impUid = freezed,
    Object? merchantUid = freezed,
    Object? success = null,
    Object? errorMsg = freezed,
    Object? pgProvider = freezed,
    Object? pgType = freezed,
  }) {
    return _then(_IamportResultModel(
      impUid: freezed == impUid
          ? _self.impUid
          : impUid // ignore: cast_nullable_to_non_nullable
              as String?,
      merchantUid: freezed == merchantUid
          ? _self.merchantUid
          : merchantUid // ignore: cast_nullable_to_non_nullable
              as String?,
      success: null == success
          ? _self.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMsg: freezed == errorMsg
          ? _self.errorMsg
          : errorMsg // ignore: cast_nullable_to_non_nullable
              as String?,
      pgProvider: freezed == pgProvider
          ? _self.pgProvider
          : pgProvider // ignore: cast_nullable_to_non_nullable
              as String?,
      pgType: freezed == pgType
          ? _self.pgType
          : pgType // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
