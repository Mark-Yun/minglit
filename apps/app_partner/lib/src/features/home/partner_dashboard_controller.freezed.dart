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

 int get pendingReviewCount; List<Event> get todayEvents; bool get hasRevenuePermission; PartnerRevenueSummary get revenueSummary; List<PartnerMonthlyRevenue> get monthlyRevenue; List<PartnerSettlement> get settlements; AsyncValue<void> get status;
/// Create a copy of PartnerDashboardState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PartnerDashboardStateCopyWith<PartnerDashboardState> get copyWith => _$PartnerDashboardStateCopyWithImpl<PartnerDashboardState>(this as PartnerDashboardState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PartnerDashboardState&&(identical(other.pendingReviewCount, pendingReviewCount) || other.pendingReviewCount == pendingReviewCount)&&const DeepCollectionEquality().equals(other.todayEvents, todayEvents)&&(identical(other.hasRevenuePermission, hasRevenuePermission) || other.hasRevenuePermission == hasRevenuePermission)&&(identical(other.revenueSummary, revenueSummary) || other.revenueSummary == revenueSummary)&&const DeepCollectionEquality().equals(other.monthlyRevenue, monthlyRevenue)&&const DeepCollectionEquality().equals(other.settlements, settlements)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,pendingReviewCount,const DeepCollectionEquality().hash(todayEvents),hasRevenuePermission,revenueSummary,const DeepCollectionEquality().hash(monthlyRevenue),const DeepCollectionEquality().hash(settlements),status);

@override
String toString() {
  return 'PartnerDashboardState(pendingReviewCount: $pendingReviewCount, todayEvents: $todayEvents, hasRevenuePermission: $hasRevenuePermission, revenueSummary: $revenueSummary, monthlyRevenue: $monthlyRevenue, settlements: $settlements, status: $status)';
}


}

/// @nodoc
abstract mixin class $PartnerDashboardStateCopyWith<$Res>  {
  factory $PartnerDashboardStateCopyWith(PartnerDashboardState value, $Res Function(PartnerDashboardState) _then) = _$PartnerDashboardStateCopyWithImpl;
@useResult
$Res call({
 int pendingReviewCount, List<Event> todayEvents, bool hasRevenuePermission, PartnerRevenueSummary revenueSummary, List<PartnerMonthlyRevenue> monthlyRevenue, List<PartnerSettlement> settlements, AsyncValue<void> status
});




}
/// @nodoc
class _$PartnerDashboardStateCopyWithImpl<$Res>
    implements $PartnerDashboardStateCopyWith<$Res> {
  _$PartnerDashboardStateCopyWithImpl(this._self, this._then);

  final PartnerDashboardState _self;
  final $Res Function(PartnerDashboardState) _then;

/// Create a copy of PartnerDashboardState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pendingReviewCount = null,Object? todayEvents = null,Object? hasRevenuePermission = null,Object? revenueSummary = null,Object? monthlyRevenue = null,Object? settlements = null,Object? status = null,}) {
  return _then(_self.copyWith(
pendingReviewCount: null == pendingReviewCount ? _self.pendingReviewCount : pendingReviewCount // ignore: cast_nullable_to_non_nullable
as int,todayEvents: null == todayEvents ? _self.todayEvents : todayEvents // ignore: cast_nullable_to_non_nullable
as List<Event>,hasRevenuePermission: null == hasRevenuePermission ? _self.hasRevenuePermission : hasRevenuePermission // ignore: cast_nullable_to_non_nullable
as bool,revenueSummary: null == revenueSummary ? _self.revenueSummary : revenueSummary // ignore: cast_nullable_to_non_nullable
as PartnerRevenueSummary,monthlyRevenue: null == monthlyRevenue ? _self.monthlyRevenue : monthlyRevenue // ignore: cast_nullable_to_non_nullable
as List<PartnerMonthlyRevenue>,settlements: null == settlements ? _self.settlements : settlements // ignore: cast_nullable_to_non_nullable
as List<PartnerSettlement>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PartnerDashboardState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PartnerDashboardState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PartnerDashboardState value)  $default,){
final _that = this;
switch (_that) {
case _PartnerDashboardState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PartnerDashboardState value)?  $default,){
final _that = this;
switch (_that) {
case _PartnerDashboardState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int pendingReviewCount,  List<Event> todayEvents,  bool hasRevenuePermission,  PartnerRevenueSummary revenueSummary,  List<PartnerMonthlyRevenue> monthlyRevenue,  List<PartnerSettlement> settlements,  AsyncValue<void> status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PartnerDashboardState() when $default != null:
return $default(_that.pendingReviewCount,_that.todayEvents,_that.hasRevenuePermission,_that.revenueSummary,_that.monthlyRevenue,_that.settlements,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int pendingReviewCount,  List<Event> todayEvents,  bool hasRevenuePermission,  PartnerRevenueSummary revenueSummary,  List<PartnerMonthlyRevenue> monthlyRevenue,  List<PartnerSettlement> settlements,  AsyncValue<void> status)  $default,) {final _that = this;
switch (_that) {
case _PartnerDashboardState():
return $default(_that.pendingReviewCount,_that.todayEvents,_that.hasRevenuePermission,_that.revenueSummary,_that.monthlyRevenue,_that.settlements,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int pendingReviewCount,  List<Event> todayEvents,  bool hasRevenuePermission,  PartnerRevenueSummary revenueSummary,  List<PartnerMonthlyRevenue> monthlyRevenue,  List<PartnerSettlement> settlements,  AsyncValue<void> status)?  $default,) {final _that = this;
switch (_that) {
case _PartnerDashboardState() when $default != null:
return $default(_that.pendingReviewCount,_that.todayEvents,_that.hasRevenuePermission,_that.revenueSummary,_that.monthlyRevenue,_that.settlements,_that.status);case _:
  return null;

}
}

}

/// @nodoc


class _PartnerDashboardState implements PartnerDashboardState {
  const _PartnerDashboardState({this.pendingReviewCount = 0, final  List<Event> todayEvents = const [], this.hasRevenuePermission = false, this.revenueSummary = const PartnerRevenueSummary(), final  List<PartnerMonthlyRevenue> monthlyRevenue = const [], final  List<PartnerSettlement> settlements = const [], this.status = const AsyncValue<void>.loading()}): _todayEvents = todayEvents,_monthlyRevenue = monthlyRevenue,_settlements = settlements;
  

@override@JsonKey() final  int pendingReviewCount;
 final  List<Event> _todayEvents;
@override@JsonKey() List<Event> get todayEvents {
  if (_todayEvents is EqualUnmodifiableListView) return _todayEvents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_todayEvents);
}

@override@JsonKey() final  bool hasRevenuePermission;
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

/// Create a copy of PartnerDashboardState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PartnerDashboardStateCopyWith<_PartnerDashboardState> get copyWith => __$PartnerDashboardStateCopyWithImpl<_PartnerDashboardState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PartnerDashboardState&&(identical(other.pendingReviewCount, pendingReviewCount) || other.pendingReviewCount == pendingReviewCount)&&const DeepCollectionEquality().equals(other._todayEvents, _todayEvents)&&(identical(other.hasRevenuePermission, hasRevenuePermission) || other.hasRevenuePermission == hasRevenuePermission)&&(identical(other.revenueSummary, revenueSummary) || other.revenueSummary == revenueSummary)&&const DeepCollectionEquality().equals(other._monthlyRevenue, _monthlyRevenue)&&const DeepCollectionEquality().equals(other._settlements, _settlements)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,pendingReviewCount,const DeepCollectionEquality().hash(_todayEvents),hasRevenuePermission,revenueSummary,const DeepCollectionEquality().hash(_monthlyRevenue),const DeepCollectionEquality().hash(_settlements),status);

@override
String toString() {
  return 'PartnerDashboardState(pendingReviewCount: $pendingReviewCount, todayEvents: $todayEvents, hasRevenuePermission: $hasRevenuePermission, revenueSummary: $revenueSummary, monthlyRevenue: $monthlyRevenue, settlements: $settlements, status: $status)';
}


}

/// @nodoc
abstract mixin class _$PartnerDashboardStateCopyWith<$Res> implements $PartnerDashboardStateCopyWith<$Res> {
  factory _$PartnerDashboardStateCopyWith(_PartnerDashboardState value, $Res Function(_PartnerDashboardState) _then) = __$PartnerDashboardStateCopyWithImpl;
@override @useResult
$Res call({
 int pendingReviewCount, List<Event> todayEvents, bool hasRevenuePermission, PartnerRevenueSummary revenueSummary, List<PartnerMonthlyRevenue> monthlyRevenue, List<PartnerSettlement> settlements, AsyncValue<void> status
});




}
/// @nodoc
class __$PartnerDashboardStateCopyWithImpl<$Res>
    implements _$PartnerDashboardStateCopyWith<$Res> {
  __$PartnerDashboardStateCopyWithImpl(this._self, this._then);

  final _PartnerDashboardState _self;
  final $Res Function(_PartnerDashboardState) _then;

/// Create a copy of PartnerDashboardState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pendingReviewCount = null,Object? todayEvents = null,Object? hasRevenuePermission = null,Object? revenueSummary = null,Object? monthlyRevenue = null,Object? settlements = null,Object? status = null,}) {
  return _then(_PartnerDashboardState(
pendingReviewCount: null == pendingReviewCount ? _self.pendingReviewCount : pendingReviewCount // ignore: cast_nullable_to_non_nullable
as int,todayEvents: null == todayEvents ? _self._todayEvents : todayEvents // ignore: cast_nullable_to_non_nullable
as List<Event>,hasRevenuePermission: null == hasRevenuePermission ? _self.hasRevenuePermission : hasRevenuePermission // ignore: cast_nullable_to_non_nullable
as bool,revenueSummary: null == revenueSummary ? _self.revenueSummary : revenueSummary // ignore: cast_nullable_to_non_nullable
as PartnerRevenueSummary,monthlyRevenue: null == monthlyRevenue ? _self._monthlyRevenue : monthlyRevenue // ignore: cast_nullable_to_non_nullable
as List<PartnerMonthlyRevenue>,settlements: null == settlements ? _self._settlements : settlements // ignore: cast_nullable_to_non_nullable
as List<PartnerSettlement>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AsyncValue<void>,
  ));
}


}

// dart format on
