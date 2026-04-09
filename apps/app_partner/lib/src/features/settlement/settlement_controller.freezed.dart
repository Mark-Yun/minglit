// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settlement_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SettlementState {

 PartnerRevenueSummary get revenueSummary; List<PartnerMonthlyRevenue> get monthlyRevenue; List<PartnerSettlement> get settlements; AsyncValue<void> get status;
/// Create a copy of SettlementState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettlementStateCopyWith<SettlementState> get copyWith => _$SettlementStateCopyWithImpl<SettlementState>(this as SettlementState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettlementState&&(identical(other.revenueSummary, revenueSummary) || other.revenueSummary == revenueSummary)&&const DeepCollectionEquality().equals(other.monthlyRevenue, monthlyRevenue)&&const DeepCollectionEquality().equals(other.settlements, settlements)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,revenueSummary,const DeepCollectionEquality().hash(monthlyRevenue),const DeepCollectionEquality().hash(settlements),status);

@override
String toString() {
  return 'SettlementState(revenueSummary: $revenueSummary, monthlyRevenue: $monthlyRevenue, settlements: $settlements, status: $status)';
}


}

/// @nodoc
abstract mixin class $SettlementStateCopyWith<$Res>  {
  factory $SettlementStateCopyWith(SettlementState value, $Res Function(SettlementState) _then) = _$SettlementStateCopyWithImpl;
@useResult
$Res call({
 PartnerRevenueSummary revenueSummary, List<PartnerMonthlyRevenue> monthlyRevenue, List<PartnerSettlement> settlements, AsyncValue<void> status
});




}
/// @nodoc
class _$SettlementStateCopyWithImpl<$Res>
    implements $SettlementStateCopyWith<$Res> {
  _$SettlementStateCopyWithImpl(this._self, this._then);

  final SettlementState _self;
  final $Res Function(SettlementState) _then;

/// Create a copy of SettlementState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? revenueSummary = null,Object? monthlyRevenue = null,Object? settlements = null,Object? status = null,}) {
  return _then(_self.copyWith(
revenueSummary: null == revenueSummary ? _self.revenueSummary : revenueSummary // ignore: cast_nullable_to_non_nullable
as PartnerRevenueSummary,monthlyRevenue: null == monthlyRevenue ? _self.monthlyRevenue : monthlyRevenue // ignore: cast_nullable_to_non_nullable
as List<PartnerMonthlyRevenue>,settlements: null == settlements ? _self.settlements : settlements // ignore: cast_nullable_to_non_nullable
as List<PartnerSettlement>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AsyncValue<void>,
  ));
}

}


/// Adds pattern-matching-related methods to [SettlementState].
extension SettlementStatePatterns on SettlementState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SettlementState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SettlementState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SettlementState value)  $default,){
final _that = this;
switch (_that) {
case _SettlementState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SettlementState value)?  $default,){
final _that = this;
switch (_that) {
case _SettlementState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PartnerRevenueSummary revenueSummary,  List<PartnerMonthlyRevenue> monthlyRevenue,  List<PartnerSettlement> settlements,  AsyncValue<void> status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SettlementState() when $default != null:
return $default(_that.revenueSummary,_that.monthlyRevenue,_that.settlements,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PartnerRevenueSummary revenueSummary,  List<PartnerMonthlyRevenue> monthlyRevenue,  List<PartnerSettlement> settlements,  AsyncValue<void> status)  $default,) {final _that = this;
switch (_that) {
case _SettlementState():
return $default(_that.revenueSummary,_that.monthlyRevenue,_that.settlements,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PartnerRevenueSummary revenueSummary,  List<PartnerMonthlyRevenue> monthlyRevenue,  List<PartnerSettlement> settlements,  AsyncValue<void> status)?  $default,) {final _that = this;
switch (_that) {
case _SettlementState() when $default != null:
return $default(_that.revenueSummary,_that.monthlyRevenue,_that.settlements,_that.status);case _:
  return null;

}
}

}

/// @nodoc


class _SettlementState implements SettlementState {
  const _SettlementState({this.revenueSummary = const PartnerRevenueSummary(), final  List<PartnerMonthlyRevenue> monthlyRevenue = const [], final  List<PartnerSettlement> settlements = const [], this.status = const AsyncValue<void>.loading()}): _monthlyRevenue = monthlyRevenue,_settlements = settlements;
  

@override@JsonKey() final  PartnerRevenueSummary revenueSummary;
 final  List<PartnerMonthlyRevenue> _monthlyRevenue;
@override@JsonKey() List<PartnerMonthlyRevenue> get monthlyRevenue {
  if (_monthlyRevenue is EqualUnmodifiableListView) return _monthlyRevenue;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_monthlyRevenue);
}

 final  List<PartnerSettlement> _settlements;
@override@JsonKey() List<PartnerSettlement> get settlements {
  if (_settlements is EqualUnmodifiableListView) return _settlements;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_settlements);
}

@override@JsonKey() final  AsyncValue<void> status;

/// Create a copy of SettlementState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SettlementStateCopyWith<_SettlementState> get copyWith => __$SettlementStateCopyWithImpl<_SettlementState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SettlementState&&(identical(other.revenueSummary, revenueSummary) || other.revenueSummary == revenueSummary)&&const DeepCollectionEquality().equals(other._monthlyRevenue, _monthlyRevenue)&&const DeepCollectionEquality().equals(other._settlements, _settlements)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,revenueSummary,const DeepCollectionEquality().hash(_monthlyRevenue),const DeepCollectionEquality().hash(_settlements),status);

@override
String toString() {
  return 'SettlementState(revenueSummary: $revenueSummary, monthlyRevenue: $monthlyRevenue, settlements: $settlements, status: $status)';
}


}

/// @nodoc
abstract mixin class _$SettlementStateCopyWith<$Res> implements $SettlementStateCopyWith<$Res> {
  factory _$SettlementStateCopyWith(_SettlementState value, $Res Function(_SettlementState) _then) = __$SettlementStateCopyWithImpl;
@override @useResult
$Res call({
 PartnerRevenueSummary revenueSummary, List<PartnerMonthlyRevenue> monthlyRevenue, List<PartnerSettlement> settlements, AsyncValue<void> status
});




}
/// @nodoc
class __$SettlementStateCopyWithImpl<$Res>
    implements _$SettlementStateCopyWith<$Res> {
  __$SettlementStateCopyWithImpl(this._self, this._then);

  final _SettlementState _self;
  final $Res Function(_SettlementState) _then;

/// Create a copy of SettlementState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? revenueSummary = null,Object? monthlyRevenue = null,Object? settlements = null,Object? status = null,}) {
  return _then(_SettlementState(
revenueSummary: null == revenueSummary ? _self.revenueSummary : revenueSummary // ignore: cast_nullable_to_non_nullable
as PartnerRevenueSummary,monthlyRevenue: null == monthlyRevenue ? _self._monthlyRevenue : monthlyRevenue // ignore: cast_nullable_to_non_nullable
as List<PartnerMonthlyRevenue>,settlements: null == settlements ? _self._settlements : settlements // ignore: cast_nullable_to_non_nullable
as List<PartnerSettlement>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AsyncValue<void>,
  ));
}


}

// dart format on
