// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settlement_list_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SettlementListState {
  List<SettlementItemDetail> get items;
  String? get selectedStatus;
  bool get isLoading;
  bool get hasMore;
  String? get error;

  /// Create a copy of SettlementListState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SettlementListStateCopyWith<SettlementListState> get copyWith =>
      _$SettlementListStateCopyWithImpl<SettlementListState>(
          this as SettlementListState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SettlementListState &&
            const DeepCollectionEquality().equals(other.items, items) &&
            (identical(other.selectedStatus, selectedStatus) ||
                other.selectedStatus == selectedStatus) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(items),
      selectedStatus,
      isLoading,
      hasMore,
      error);

  @override
  String toString() {
    return 'SettlementListState(items: $items, selectedStatus: $selectedStatus, isLoading: $isLoading, hasMore: $hasMore, error: $error)';
  }
}

/// @nodoc
abstract mixin class $SettlementListStateCopyWith<$Res> {
  factory $SettlementListStateCopyWith(
          SettlementListState value, $Res Function(SettlementListState) _then) =
      _$SettlementListStateCopyWithImpl;
  @useResult
  $Res call(
      {List<SettlementItemDetail> items,
      String? selectedStatus,
      bool isLoading,
      bool hasMore,
      String? error});
}

/// @nodoc
class _$SettlementListStateCopyWithImpl<$Res>
    implements $SettlementListStateCopyWith<$Res> {
  _$SettlementListStateCopyWithImpl(this._self, this._then);

  final SettlementListState _self;
  final $Res Function(SettlementListState) _then;

  /// Create a copy of SettlementListState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? selectedStatus = freezed,
    Object? isLoading = null,
    Object? hasMore = null,
    Object? error = freezed,
  }) {
    return _then(_self.copyWith(
      items: null == items
          ? _self.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<SettlementItemDetail>,
      selectedStatus: freezed == selectedStatus
          ? _self.selectedStatus
          : selectedStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      isLoading: null == isLoading
          ? _self.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      hasMore: null == hasMore
          ? _self.hasMore
          : hasMore // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [SettlementListState].
extension SettlementListStatePatterns on SettlementListState {
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
    TResult Function(_SettlementListState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SettlementListState() when $default != null:
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
    TResult Function(_SettlementListState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SettlementListState():
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
    TResult? Function(_SettlementListState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SettlementListState() when $default != null:
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
    TResult Function(List<SettlementItemDetail> items, String? selectedStatus,
            bool isLoading, bool hasMore, String? error)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SettlementListState() when $default != null:
        return $default(_that.items, _that.selectedStatus, _that.isLoading,
            _that.hasMore, _that.error);
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
    TResult Function(List<SettlementItemDetail> items, String? selectedStatus,
            bool isLoading, bool hasMore, String? error)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SettlementListState():
        return $default(_that.items, _that.selectedStatus, _that.isLoading,
            _that.hasMore, _that.error);
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
    TResult? Function(List<SettlementItemDetail> items, String? selectedStatus,
            bool isLoading, bool hasMore, String? error)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SettlementListState() when $default != null:
        return $default(_that.items, _that.selectedStatus, _that.isLoading,
            _that.hasMore, _that.error);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _SettlementListState implements SettlementListState {
  const _SettlementListState(
      {final List<SettlementItemDetail> items = const [],
      this.selectedStatus = null,
      this.isLoading = false,
      this.hasMore = true,
      this.error = null})
      : _items = items;

  final List<SettlementItemDetail> _items;
  @override
  @JsonKey()
  List<SettlementItemDetail> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  @JsonKey()
  final String? selectedStatus;
  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool hasMore;
  @override
  @JsonKey()
  final String? error;

  /// Create a copy of SettlementListState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SettlementListStateCopyWith<_SettlementListState> get copyWith =>
      __$SettlementListStateCopyWithImpl<_SettlementListState>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SettlementListState &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.selectedStatus, selectedStatus) ||
                other.selectedStatus == selectedStatus) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_items),
      selectedStatus,
      isLoading,
      hasMore,
      error);

  @override
  String toString() {
    return 'SettlementListState(items: $items, selectedStatus: $selectedStatus, isLoading: $isLoading, hasMore: $hasMore, error: $error)';
  }
}

/// @nodoc
abstract mixin class _$SettlementListStateCopyWith<$Res>
    implements $SettlementListStateCopyWith<$Res> {
  factory _$SettlementListStateCopyWith(_SettlementListState value,
          $Res Function(_SettlementListState) _then) =
      __$SettlementListStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {List<SettlementItemDetail> items,
      String? selectedStatus,
      bool isLoading,
      bool hasMore,
      String? error});
}

/// @nodoc
class __$SettlementListStateCopyWithImpl<$Res>
    implements _$SettlementListStateCopyWith<$Res> {
  __$SettlementListStateCopyWithImpl(this._self, this._then);

  final _SettlementListState _self;
  final $Res Function(_SettlementListState) _then;

  /// Create a copy of SettlementListState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? items = null,
    Object? selectedStatus = freezed,
    Object? isLoading = null,
    Object? hasMore = null,
    Object? error = freezed,
  }) {
    return _then(_SettlementListState(
      items: null == items
          ? _self._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<SettlementItemDetail>,
      selectedStatus: freezed == selectedStatus
          ? _self.selectedStatus
          : selectedStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      isLoading: null == isLoading
          ? _self.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      hasMore: null == hasMore
          ? _self.hasMore
          : hasMore // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
