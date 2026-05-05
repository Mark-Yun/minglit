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

 int get pendingReviewCount; List<Event> get upcomingEvents; List<Event> get liveEvents; List<Event> get recruitingEvents; List<Event> get preparingEvents; List<Party> get activeParties; List<Party> get draftParties; int get totalPartyCount; int get totalAttendees;// Fix #1215: tracks ALL events ever created, not just upcoming ones.
// Using upcomingEvents for onboarding check caused the guide to reappear
// after all events ended or were more than 7 days away.
 bool get hasAnyEvents; AsyncValue<void> get status;
/// Create a copy of PartnerDashboardState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PartnerDashboardStateCopyWith<PartnerDashboardState> get copyWith => _$PartnerDashboardStateCopyWithImpl<PartnerDashboardState>(this as PartnerDashboardState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PartnerDashboardState&&(identical(other.pendingReviewCount, pendingReviewCount) || other.pendingReviewCount == pendingReviewCount)&&const DeepCollectionEquality().equals(other.upcomingEvents, upcomingEvents)&&const DeepCollectionEquality().equals(other.liveEvents, liveEvents)&&const DeepCollectionEquality().equals(other.recruitingEvents, recruitingEvents)&&const DeepCollectionEquality().equals(other.preparingEvents, preparingEvents)&&const DeepCollectionEquality().equals(other.activeParties, activeParties)&&const DeepCollectionEquality().equals(other.draftParties, draftParties)&&(identical(other.totalPartyCount, totalPartyCount) || other.totalPartyCount == totalPartyCount)&&(identical(other.totalAttendees, totalAttendees) || other.totalAttendees == totalAttendees)&&(identical(other.hasAnyEvents, hasAnyEvents) || other.hasAnyEvents == hasAnyEvents)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,pendingReviewCount,const DeepCollectionEquality().hash(upcomingEvents),const DeepCollectionEquality().hash(liveEvents),const DeepCollectionEquality().hash(recruitingEvents),const DeepCollectionEquality().hash(preparingEvents),const DeepCollectionEquality().hash(activeParties),const DeepCollectionEquality().hash(draftParties),totalPartyCount,totalAttendees,hasAnyEvents,status);

@override
String toString() {
  return 'PartnerDashboardState(pendingReviewCount: $pendingReviewCount, upcomingEvents: $upcomingEvents, liveEvents: $liveEvents, recruitingEvents: $recruitingEvents, preparingEvents: $preparingEvents, activeParties: $activeParties, draftParties: $draftParties, totalPartyCount: $totalPartyCount, totalAttendees: $totalAttendees, hasAnyEvents: $hasAnyEvents, status: $status)';
}


}

/// @nodoc
abstract mixin class $PartnerDashboardStateCopyWith<$Res>  {
  factory $PartnerDashboardStateCopyWith(PartnerDashboardState value, $Res Function(PartnerDashboardState) _then) = _$PartnerDashboardStateCopyWithImpl;
@useResult
$Res call({
 int pendingReviewCount, List<Event> upcomingEvents, List<Event> liveEvents, List<Event> recruitingEvents, List<Event> preparingEvents, List<Party> activeParties, List<Party> draftParties, int totalPartyCount, int totalAttendees, bool hasAnyEvents, AsyncValue<void> status
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
@pragma('vm:prefer-inline') @override $Res call({Object? pendingReviewCount = null,Object? upcomingEvents = null,Object? liveEvents = null,Object? recruitingEvents = null,Object? preparingEvents = null,Object? activeParties = null,Object? draftParties = null,Object? totalPartyCount = null,Object? totalAttendees = null,Object? hasAnyEvents = null,Object? status = null,}) {
  return _then(_self.copyWith(
pendingReviewCount: null == pendingReviewCount ? _self.pendingReviewCount : pendingReviewCount // ignore: cast_nullable_to_non_nullable
as int,upcomingEvents: null == upcomingEvents ? _self.upcomingEvents : upcomingEvents // ignore: cast_nullable_to_non_nullable
as List<Event>,liveEvents: null == liveEvents ? _self.liveEvents : liveEvents // ignore: cast_nullable_to_non_nullable
as List<Event>,recruitingEvents: null == recruitingEvents ? _self.recruitingEvents : recruitingEvents // ignore: cast_nullable_to_non_nullable
as List<Event>,preparingEvents: null == preparingEvents ? _self.preparingEvents : preparingEvents // ignore: cast_nullable_to_non_nullable
as List<Event>,activeParties: null == activeParties ? _self.activeParties : activeParties // ignore: cast_nullable_to_non_nullable
as List<Party>,draftParties: null == draftParties ? _self.draftParties : draftParties // ignore: cast_nullable_to_non_nullable
as List<Party>,totalPartyCount: null == totalPartyCount ? _self.totalPartyCount : totalPartyCount // ignore: cast_nullable_to_non_nullable
as int,totalAttendees: null == totalAttendees ? _self.totalAttendees : totalAttendees // ignore: cast_nullable_to_non_nullable
as int,hasAnyEvents: null == hasAnyEvents ? _self.hasAnyEvents : hasAnyEvents // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int pendingReviewCount,  List<Event> upcomingEvents,  List<Event> liveEvents,  List<Event> recruitingEvents,  List<Event> preparingEvents,  List<Party> activeParties,  List<Party> draftParties,  int totalPartyCount,  int totalAttendees,  bool hasAnyEvents,  AsyncValue<void> status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PartnerDashboardState() when $default != null:
return $default(_that.pendingReviewCount,_that.upcomingEvents,_that.liveEvents,_that.recruitingEvents,_that.preparingEvents,_that.activeParties,_that.draftParties,_that.totalPartyCount,_that.totalAttendees,_that.hasAnyEvents,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int pendingReviewCount,  List<Event> upcomingEvents,  List<Event> liveEvents,  List<Event> recruitingEvents,  List<Event> preparingEvents,  List<Party> activeParties,  List<Party> draftParties,  int totalPartyCount,  int totalAttendees,  bool hasAnyEvents,  AsyncValue<void> status)  $default,) {final _that = this;
switch (_that) {
case _PartnerDashboardState():
return $default(_that.pendingReviewCount,_that.upcomingEvents,_that.liveEvents,_that.recruitingEvents,_that.preparingEvents,_that.activeParties,_that.draftParties,_that.totalPartyCount,_that.totalAttendees,_that.hasAnyEvents,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int pendingReviewCount,  List<Event> upcomingEvents,  List<Event> liveEvents,  List<Event> recruitingEvents,  List<Event> preparingEvents,  List<Party> activeParties,  List<Party> draftParties,  int totalPartyCount,  int totalAttendees,  bool hasAnyEvents,  AsyncValue<void> status)?  $default,) {final _that = this;
switch (_that) {
case _PartnerDashboardState() when $default != null:
return $default(_that.pendingReviewCount,_that.upcomingEvents,_that.liveEvents,_that.recruitingEvents,_that.preparingEvents,_that.activeParties,_that.draftParties,_that.totalPartyCount,_that.totalAttendees,_that.hasAnyEvents,_that.status);case _:
  return null;

}
}

}

/// @nodoc


class _PartnerDashboardState implements PartnerDashboardState {
  const _PartnerDashboardState({this.pendingReviewCount = 0, final  List<Event> upcomingEvents = const [], final  List<Event> liveEvents = const [], final  List<Event> recruitingEvents = const [], final  List<Event> preparingEvents = const [], final  List<Party> activeParties = const [], final  List<Party> draftParties = const [], this.totalPartyCount = 0, this.totalAttendees = 0, this.hasAnyEvents = false, this.status = const AsyncValue<void>.loading()}): _upcomingEvents = upcomingEvents,_liveEvents = liveEvents,_recruitingEvents = recruitingEvents,_preparingEvents = preparingEvents,_activeParties = activeParties,_draftParties = draftParties;
  

@override@JsonKey() final  int pendingReviewCount;
 final  List<Event> _upcomingEvents;
@override@JsonKey() List<Event> get upcomingEvents {
  if (_upcomingEvents is EqualUnmodifiableListView) return _upcomingEvents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_upcomingEvents);
}

 final  List<Event> _liveEvents;
@override@JsonKey() List<Event> get liveEvents {
  if (_liveEvents is EqualUnmodifiableListView) return _liveEvents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_liveEvents);
}

 final  List<Event> _recruitingEvents;
@override@JsonKey() List<Event> get recruitingEvents {
  if (_recruitingEvents is EqualUnmodifiableListView) return _recruitingEvents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recruitingEvents);
}

 final  List<Event> _preparingEvents;
@override@JsonKey() List<Event> get preparingEvents {
  if (_preparingEvents is EqualUnmodifiableListView) return _preparingEvents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_preparingEvents);
}

 final  List<Party> _activeParties;
@override@JsonKey() List<Party> get activeParties {
  if (_activeParties is EqualUnmodifiableListView) return _activeParties;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_activeParties);
}

 final  List<Party> _draftParties;
@override@JsonKey() List<Party> get draftParties {
  if (_draftParties is EqualUnmodifiableListView) return _draftParties;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_draftParties);
}

@override@JsonKey() final  int totalPartyCount;
@override@JsonKey() final  int totalAttendees;
// Fix #1215: tracks ALL events ever created, not just upcoming ones.
// Using upcomingEvents for onboarding check caused the guide to reappear
// after all events ended or were more than 7 days away.
@override@JsonKey() final  bool hasAnyEvents;
@override@JsonKey() final  AsyncValue<void> status;

/// Create a copy of PartnerDashboardState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PartnerDashboardStateCopyWith<_PartnerDashboardState> get copyWith => __$PartnerDashboardStateCopyWithImpl<_PartnerDashboardState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PartnerDashboardState&&(identical(other.pendingReviewCount, pendingReviewCount) || other.pendingReviewCount == pendingReviewCount)&&const DeepCollectionEquality().equals(other._upcomingEvents, _upcomingEvents)&&const DeepCollectionEquality().equals(other._liveEvents, _liveEvents)&&const DeepCollectionEquality().equals(other._recruitingEvents, _recruitingEvents)&&const DeepCollectionEquality().equals(other._preparingEvents, _preparingEvents)&&const DeepCollectionEquality().equals(other._activeParties, _activeParties)&&const DeepCollectionEquality().equals(other._draftParties, _draftParties)&&(identical(other.totalPartyCount, totalPartyCount) || other.totalPartyCount == totalPartyCount)&&(identical(other.totalAttendees, totalAttendees) || other.totalAttendees == totalAttendees)&&(identical(other.hasAnyEvents, hasAnyEvents) || other.hasAnyEvents == hasAnyEvents)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,pendingReviewCount,const DeepCollectionEquality().hash(_upcomingEvents),const DeepCollectionEquality().hash(_liveEvents),const DeepCollectionEquality().hash(_recruitingEvents),const DeepCollectionEquality().hash(_preparingEvents),const DeepCollectionEquality().hash(_activeParties),const DeepCollectionEquality().hash(_draftParties),totalPartyCount,totalAttendees,hasAnyEvents,status);

@override
String toString() {
  return 'PartnerDashboardState(pendingReviewCount: $pendingReviewCount, upcomingEvents: $upcomingEvents, liveEvents: $liveEvents, recruitingEvents: $recruitingEvents, preparingEvents: $preparingEvents, activeParties: $activeParties, draftParties: $draftParties, totalPartyCount: $totalPartyCount, totalAttendees: $totalAttendees, hasAnyEvents: $hasAnyEvents, status: $status)';
}


}

/// @nodoc
abstract mixin class _$PartnerDashboardStateCopyWith<$Res> implements $PartnerDashboardStateCopyWith<$Res> {
  factory _$PartnerDashboardStateCopyWith(_PartnerDashboardState value, $Res Function(_PartnerDashboardState) _then) = __$PartnerDashboardStateCopyWithImpl;
@override @useResult
$Res call({
 int pendingReviewCount, List<Event> upcomingEvents, List<Event> liveEvents, List<Event> recruitingEvents, List<Event> preparingEvents, List<Party> activeParties, List<Party> draftParties, int totalPartyCount, int totalAttendees, bool hasAnyEvents, AsyncValue<void> status
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
@override @pragma('vm:prefer-inline') $Res call({Object? pendingReviewCount = null,Object? upcomingEvents = null,Object? liveEvents = null,Object? recruitingEvents = null,Object? preparingEvents = null,Object? activeParties = null,Object? draftParties = null,Object? totalPartyCount = null,Object? totalAttendees = null,Object? hasAnyEvents = null,Object? status = null,}) {
  return _then(_PartnerDashboardState(
pendingReviewCount: null == pendingReviewCount ? _self.pendingReviewCount : pendingReviewCount // ignore: cast_nullable_to_non_nullable
as int,upcomingEvents: null == upcomingEvents ? _self._upcomingEvents : upcomingEvents // ignore: cast_nullable_to_non_nullable
as List<Event>,liveEvents: null == liveEvents ? _self._liveEvents : liveEvents // ignore: cast_nullable_to_non_nullable
as List<Event>,recruitingEvents: null == recruitingEvents ? _self._recruitingEvents : recruitingEvents // ignore: cast_nullable_to_non_nullable
as List<Event>,preparingEvents: null == preparingEvents ? _self._preparingEvents : preparingEvents // ignore: cast_nullable_to_non_nullable
as List<Event>,activeParties: null == activeParties ? _self._activeParties : activeParties // ignore: cast_nullable_to_non_nullable
as List<Party>,draftParties: null == draftParties ? _self._draftParties : draftParties // ignore: cast_nullable_to_non_nullable
as List<Party>,totalPartyCount: null == totalPartyCount ? _self.totalPartyCount : totalPartyCount // ignore: cast_nullable_to_non_nullable
as int,totalAttendees: null == totalAttendees ? _self.totalAttendees : totalAttendees // ignore: cast_nullable_to_non_nullable
as int,hasAnyEvents: null == hasAnyEvents ? _self.hasAnyEvents : hasAnyEvents // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AsyncValue<void>,
  ));
}


}

// dart format on
