// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settlement_dashboard_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SettlementDashboardState {

 DateTime get selectedMonth; AsyncValue<void> get status; Map<String, dynamic>? get dashboardData;
/// Create a copy of SettlementDashboardState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettlementDashboardStateCopyWith<SettlementDashboardState> get copyWith => _$SettlementDashboardStateCopyWithImpl<SettlementDashboardState>(this as SettlementDashboardState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettlementDashboardState&&(identical(other.selectedMonth, selectedMonth) || other.selectedMonth == selectedMonth)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.dashboardData, dashboardData));
}


@override
int get hashCode => Object.hash(runtimeType,selectedMonth,status,const DeepCollectionEquality().hash(dashboardData));

@override
String toString() {
  return 'SettlementDashboardState(selectedMonth: $selectedMonth, status: $status, dashboardData: $dashboardData)';
}


}

/// @nodoc
abstract mixin class $SettlementDashboardStateCopyWith<$Res>  {
  factory $SettlementDashboardStateCopyWith(SettlementDashboardState value, $Res Function(SettlementDashboardState) _then) = _$SettlementDashboardStateCopyWithImpl;
@useResult
$Res call({
 DateTime selectedMonth, AsyncValue<void> status, Map<String, dynamic>? dashboardData
});




}
/// @nodoc
class _$SettlementDashboardStateCopyWithImpl<$Res>
    implements $SettlementDashboardStateCopyWith<$Res> {
  _$SettlementDashboardStateCopyWithImpl(this._self, this._then);

  final SettlementDashboardState _self;
  final $Res Function(SettlementDashboardState) _then;

/// Create a copy of SettlementDashboardState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? selectedMonth = null,Object? status = null,Object? dashboardData = freezed,}) {
  return _then(_self.copyWith(
selectedMonth: null == selectedMonth ? _self.selectedMonth : selectedMonth // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AsyncValue<void>,dashboardData: freezed == dashboardData ? _self.dashboardData : dashboardData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [SettlementDashboardState].
extension SettlementDashboardStatePatterns on SettlementDashboardState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SettlementDashboardState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SettlementDashboardState() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SettlementDashboardState value)  $default,){
final _that = this;
switch (_that) {
case _SettlementDashboardState():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SettlementDashboardState value)?  $default,){
final _that = this;
switch (_that) {
case _SettlementDashboardState() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime selectedMonth,  AsyncValue<void> status,  Map<String, dynamic>? dashboardData)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SettlementDashboardState() when $default != null:
return $default(_that.selectedMonth,_that.status,_that.dashboardData);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime selectedMonth,  AsyncValue<void> status,  Map<String, dynamic>? dashboardData)  $default,) {final _that = this;
switch (_that) {
case _SettlementDashboardState():
return $default(_that.selectedMonth,_that.status,_that.dashboardData);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime selectedMonth,  AsyncValue<void> status,  Map<String, dynamic>? dashboardData)?  $default,) {final _that = this;
switch (_that) {
case _SettlementDashboardState() when $default != null:
return $default(_that.selectedMonth,_that.status,_that.dashboardData);case _:
  return null;

}
}

}

/// @nodoc


class _SettlementDashboardState implements SettlementDashboardState {
  const _SettlementDashboardState({required this.selectedMonth, this.status = const AsyncValue<void>.loading(), final  Map<String, dynamic>? dashboardData}): _dashboardData = dashboardData;
  

@override final  DateTime selectedMonth;
@override@JsonKey() final  AsyncValue<void> status;
 final  Map<String, dynamic>? _dashboardData;
@override Map<String, dynamic>? get dashboardData {
  final value = _dashboardData;
  if (value == null) return null;
  if (_dashboardData is EqualUnmodifiableMapView) return _dashboardData;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of SettlementDashboardState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SettlementDashboardStateCopyWith<_SettlementDashboardState> get copyWith => __$SettlementDashboardStateCopyWithImpl<_SettlementDashboardState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SettlementDashboardState&&(identical(other.selectedMonth, selectedMonth) || other.selectedMonth == selectedMonth)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._dashboardData, _dashboardData));
}


@override
int get hashCode => Object.hash(runtimeType,selectedMonth,status,const DeepCollectionEquality().hash(_dashboardData));

@override
String toString() {
  return 'SettlementDashboardState(selectedMonth: $selectedMonth, status: $status, dashboardData: $dashboardData)';
}


}

/// @nodoc
abstract mixin class _$SettlementDashboardStateCopyWith<$Res> implements $SettlementDashboardStateCopyWith<$Res> {
  factory _$SettlementDashboardStateCopyWith(_SettlementDashboardState value, $Res Function(_SettlementDashboardState) _then) = __$SettlementDashboardStateCopyWithImpl;
@override @useResult
$Res call({
 DateTime selectedMonth, AsyncValue<void> status, Map<String, dynamic>? dashboardData
});




}
/// @nodoc
class __$SettlementDashboardStateCopyWithImpl<$Res>
    implements _$SettlementDashboardStateCopyWith<$Res> {
  __$SettlementDashboardStateCopyWithImpl(this._self, this._then);

  final _SettlementDashboardState _self;
  final $Res Function(_SettlementDashboardState) _then;

/// Create a copy of SettlementDashboardState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? selectedMonth = null,Object? status = null,Object? dashboardData = freezed,}) {
  return _then(_SettlementDashboardState(
selectedMonth: null == selectedMonth ? _self.selectedMonth : selectedMonth // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AsyncValue<void>,dashboardData: freezed == dashboardData ? _self._dashboardData : dashboardData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
