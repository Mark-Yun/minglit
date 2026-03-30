// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'partner_dashboard_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PartnerDashboardState {
  int get pendingReviewCount;
  List<Event> get upcomingEvents;
  List<Event> get closingSoonEvents;
  List<Party> get activeParties;
  AsyncValue<void> get status;

  /// Create a copy of PartnerDashboardState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PartnerDashboardStateCopyWith<PartnerDashboardState> get copyWith =>
      _$PartnerDashboardStateCopyWithImpl<PartnerDashboardState>(
          this as PartnerDashboardState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PartnerDashboardState &&
            (identical(other.pendingReviewCount, pendingReviewCount) ||
                other.pendingReviewCount == pendingReviewCount) &&
            const DeepCollectionEquality()
                .equals(other.upcomingEvents, upcomingEvents) &&
            const DeepCollectionEquality()
                .equals(other.closingSoonEvents, closingSoonEvents) &&
            const DeepCollectionEquality()
                .equals(other.activeParties, activeParties) &&
            (identical(other.status, status) || other.status == status));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      pendingReviewCount,
      const DeepCollectionEquality().hash(upcomingEvents),
      const DeepCollectionEquality().hash(closingSoonEvents),
      const DeepCollectionEquality().hash(activeParties),
      status);

  @override
  String toString() {
    return 'PartnerDashboardState(pendingReviewCount: $pendingReviewCount, upcomingEvents: $upcomingEvents, closingSoonEvents: $closingSoonEvents, activeParties: $activeParties, status: $status)';
  }
}

/// @nodoc
abstract mixin class $PartnerDashboardStateCopyWith<$Res> {
  factory $PartnerDashboardStateCopyWith(PartnerDashboardState value,
          $Res Function(PartnerDashboardState) _then) =
      _$PartnerDashboardStateCopyWithImpl;
  @useResult
  $Res call(
      {int pendingReviewCount,
      List<Event> upcomingEvents,
      List<Event> closingSoonEvents,
      List<Party> activeParties,
      AsyncValue<void> status});
}

/// @nodoc
class _$PartnerDashboardStateCopyWithImpl<$Res>
    implements $PartnerDashboardStateCopyWith<$Res> {
  _$PartnerDashboardStateCopyWithImpl(this._self, this._then);

  final PartnerDashboardState _self;
  final $Res Function(PartnerDashboardState) _then;

  /// Create a copy of PartnerDashboardState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pendingReviewCount = null,
    Object? upcomingEvents = null,
    Object? closingSoonEvents = null,
    Object? activeParties = null,
    Object? status = null,
  }) {
    return _then(_self.copyWith(
      pendingReviewCount: null == pendingReviewCount
          ? _self.pendingReviewCount
          : pendingReviewCount // ignore: cast_nullable_to_non_nullable
              as int,
      upcomingEvents: null == upcomingEvents
          ? _self.upcomingEvents
          : upcomingEvents // ignore: cast_nullable_to_non_nullable
              as List<Event>,
      closingSoonEvents: null == closingSoonEvents
          ? _self.closingSoonEvents
          : closingSoonEvents // ignore: cast_nullable_to_non_nullable
              as List<Event>,
      activeParties: null == activeParties
          ? _self.activeParties
          : activeParties // ignore: cast_nullable_to_non_nullable
              as List<Party>,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as AsyncValue<void>,
    ));
  }
}

/// Adds pattern-matching-related methods to [PartnerDashboardState].
extension PartnerDashboardStatePatterns on PartnerDashboardState {
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
    TResult Function(_PartnerDashboardState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PartnerDashboardState() when $default != null:
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
    TResult Function(_PartnerDashboardState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PartnerDashboardState():
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
    TResult? Function(_PartnerDashboardState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PartnerDashboardState() when $default != null:
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
            int pendingReviewCount,
            List<Event> upcomingEvents,
            List<Event> closingSoonEvents,
            List<Party> activeParties,
            AsyncValue<void> status)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PartnerDashboardState() when $default != null:
        return $default(_that.pendingReviewCount, _that.upcomingEvents,
            _that.closingSoonEvents, _that.activeParties, _that.status);
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
            int pendingReviewCount,
            List<Event> upcomingEvents,
            List<Event> closingSoonEvents,
            List<Party> activeParties,
            AsyncValue<void> status)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PartnerDashboardState():
        return $default(_that.pendingReviewCount, _that.upcomingEvents,
            _that.closingSoonEvents, _that.activeParties, _that.status);
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
            int pendingReviewCount,
            List<Event> upcomingEvents,
            List<Event> closingSoonEvents,
            List<Party> activeParties,
            AsyncValue<void> status)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PartnerDashboardState() when $default != null:
        return $default(_that.pendingReviewCount, _that.upcomingEvents,
            _that.closingSoonEvents, _that.activeParties, _that.status);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _PartnerDashboardState implements PartnerDashboardState {
  const _PartnerDashboardState(
      {this.pendingReviewCount = 0,
      final List<Event> upcomingEvents = const [],
      final List<Event> closingSoonEvents = const [],
      final List<Party> activeParties = const [],
      this.status = const AsyncValue<void>.loading()})
      : _upcomingEvents = upcomingEvents,
        _closingSoonEvents = closingSoonEvents,
        _activeParties = activeParties;

  @override
  @JsonKey()
  final int pendingReviewCount;
  final List<Event> _upcomingEvents;
  @override
  @JsonKey()
  List<Event> get upcomingEvents {
    if (_upcomingEvents is EqualUnmodifiableListView) return _upcomingEvents;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_upcomingEvents);
  }

  final List<Event> _closingSoonEvents;
  @override
  @JsonKey()
  List<Event> get closingSoonEvents {
    if (_closingSoonEvents is EqualUnmodifiableListView)
      return _closingSoonEvents;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_closingSoonEvents);
  }

  final List<Party> _activeParties;
  @override
  @JsonKey()
  List<Party> get activeParties {
    if (_activeParties is EqualUnmodifiableListView) return _activeParties;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_activeParties);
  }

  @override
  @JsonKey()
  final AsyncValue<void> status;

  /// Create a copy of PartnerDashboardState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PartnerDashboardStateCopyWith<_PartnerDashboardState> get copyWith =>
      __$PartnerDashboardStateCopyWithImpl<_PartnerDashboardState>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PartnerDashboardState &&
            (identical(other.pendingReviewCount, pendingReviewCount) ||
                other.pendingReviewCount == pendingReviewCount) &&
            const DeepCollectionEquality()
                .equals(other._upcomingEvents, _upcomingEvents) &&
            const DeepCollectionEquality()
                .equals(other._closingSoonEvents, _closingSoonEvents) &&
            const DeepCollectionEquality()
                .equals(other._activeParties, _activeParties) &&
            (identical(other.status, status) || other.status == status));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      pendingReviewCount,
      const DeepCollectionEquality().hash(_upcomingEvents),
      const DeepCollectionEquality().hash(_closingSoonEvents),
      const DeepCollectionEquality().hash(_activeParties),
      status);

  @override
  String toString() {
    return 'PartnerDashboardState(pendingReviewCount: $pendingReviewCount, upcomingEvents: $upcomingEvents, closingSoonEvents: $closingSoonEvents, activeParties: $activeParties, status: $status)';
  }
}

/// @nodoc
abstract mixin class _$PartnerDashboardStateCopyWith<$Res>
    implements $PartnerDashboardStateCopyWith<$Res> {
  factory _$PartnerDashboardStateCopyWith(_PartnerDashboardState value,
          $Res Function(_PartnerDashboardState) _then) =
      __$PartnerDashboardStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int pendingReviewCount,
      List<Event> upcomingEvents,
      List<Event> closingSoonEvents,
      List<Party> activeParties,
      AsyncValue<void> status});
}

/// @nodoc
class __$PartnerDashboardStateCopyWithImpl<$Res>
    implements _$PartnerDashboardStateCopyWith<$Res> {
  __$PartnerDashboardStateCopyWithImpl(this._self, this._then);

  final _PartnerDashboardState _self;
  final $Res Function(_PartnerDashboardState) _then;

  /// Create a copy of PartnerDashboardState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? pendingReviewCount = null,
    Object? upcomingEvents = null,
    Object? closingSoonEvents = null,
    Object? activeParties = null,
    Object? status = null,
  }) {
    return _then(_PartnerDashboardState(
      pendingReviewCount: null == pendingReviewCount
          ? _self.pendingReviewCount
          : pendingReviewCount // ignore: cast_nullable_to_non_nullable
              as int,
      upcomingEvents: null == upcomingEvents
          ? _self._upcomingEvents
          : upcomingEvents // ignore: cast_nullable_to_non_nullable
              as List<Event>,
      closingSoonEvents: null == closingSoonEvents
          ? _self._closingSoonEvents
          : closingSoonEvents // ignore: cast_nullable_to_non_nullable
              as List<Event>,
      activeParties: null == activeParties
          ? _self._activeParties
          : activeParties // ignore: cast_nullable_to_non_nullable
              as List<Party>,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as AsyncValue<void>,
    ));
  }
}

// dart format on
