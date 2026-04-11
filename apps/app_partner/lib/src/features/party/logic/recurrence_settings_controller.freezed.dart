// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recurrence_settings_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RecurrenceSettingsState {

/// Whether recurrence is enabled for the event being created.
 bool get isEnabled;/// Repeat pattern (weekly / biweekly / monthly).
 RecurrencePattern get pattern;/// Days of week to generate events on (0=Sun … 6=Sat, JavaScript convention).
/// Used for weekly and biweekly patterns.
 List<int> get daysOfWeek;/// Day of month (1–31) for monthly pattern.
 int? get monthDay;/// Optional rule end date in YYYY-MM-DD format.
 String? get endDate;
/// Create a copy of RecurrenceSettingsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecurrenceSettingsStateCopyWith<RecurrenceSettingsState> get copyWith => _$RecurrenceSettingsStateCopyWithImpl<RecurrenceSettingsState>(this as RecurrenceSettingsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecurrenceSettingsState&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.pattern, pattern) || other.pattern == pattern)&&const DeepCollectionEquality().equals(other.daysOfWeek, daysOfWeek)&&(identical(other.monthDay, monthDay) || other.monthDay == monthDay)&&(identical(other.endDate, endDate) || other.endDate == endDate));
}


@override
int get hashCode => Object.hash(runtimeType,isEnabled,pattern,const DeepCollectionEquality().hash(daysOfWeek),monthDay,endDate);

@override
String toString() {
  return 'RecurrenceSettingsState(isEnabled: $isEnabled, pattern: $pattern, daysOfWeek: $daysOfWeek, monthDay: $monthDay, endDate: $endDate)';
}


}

/// @nodoc
abstract mixin class $RecurrenceSettingsStateCopyWith<$Res>  {
  factory $RecurrenceSettingsStateCopyWith(RecurrenceSettingsState value, $Res Function(RecurrenceSettingsState) _then) = _$RecurrenceSettingsStateCopyWithImpl;
@useResult
$Res call({
 bool isEnabled, RecurrencePattern pattern, List<int> daysOfWeek, int? monthDay, String? endDate
});




}
/// @nodoc
class _$RecurrenceSettingsStateCopyWithImpl<$Res>
    implements $RecurrenceSettingsStateCopyWith<$Res> {
  _$RecurrenceSettingsStateCopyWithImpl(this._self, this._then);

  final RecurrenceSettingsState _self;
  final $Res Function(RecurrenceSettingsState) _then;

/// Create a copy of RecurrenceSettingsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isEnabled = null,Object? pattern = null,Object? daysOfWeek = null,Object? monthDay = freezed,Object? endDate = freezed,}) {
  return _then(_self.copyWith(
isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,pattern: null == pattern ? _self.pattern : pattern // ignore: cast_nullable_to_non_nullable
as RecurrencePattern,daysOfWeek: null == daysOfWeek ? _self.daysOfWeek : daysOfWeek // ignore: cast_nullable_to_non_nullable
as List<int>,monthDay: freezed == monthDay ? _self.monthDay : monthDay // ignore: cast_nullable_to_non_nullable
as int?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RecurrenceSettingsState].
extension RecurrenceSettingsStatePatterns on RecurrenceSettingsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecurrenceSettingsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecurrenceSettingsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecurrenceSettingsState value)  $default,){
final _that = this;
switch (_that) {
case _RecurrenceSettingsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecurrenceSettingsState value)?  $default,){
final _that = this;
switch (_that) {
case _RecurrenceSettingsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isEnabled,  RecurrencePattern pattern,  List<int> daysOfWeek,  int? monthDay,  String? endDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecurrenceSettingsState() when $default != null:
return $default(_that.isEnabled,_that.pattern,_that.daysOfWeek,_that.monthDay,_that.endDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isEnabled,  RecurrencePattern pattern,  List<int> daysOfWeek,  int? monthDay,  String? endDate)  $default,) {final _that = this;
switch (_that) {
case _RecurrenceSettingsState():
return $default(_that.isEnabled,_that.pattern,_that.daysOfWeek,_that.monthDay,_that.endDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isEnabled,  RecurrencePattern pattern,  List<int> daysOfWeek,  int? monthDay,  String? endDate)?  $default,) {final _that = this;
switch (_that) {
case _RecurrenceSettingsState() when $default != null:
return $default(_that.isEnabled,_that.pattern,_that.daysOfWeek,_that.monthDay,_that.endDate);case _:
  return null;

}
}

}

/// @nodoc


class _RecurrenceSettingsState implements RecurrenceSettingsState {
  const _RecurrenceSettingsState({this.isEnabled = false, this.pattern = RecurrencePattern.weekly, final  List<int> daysOfWeek = const [1], this.monthDay, this.endDate}): _daysOfWeek = daysOfWeek;
  

/// Whether recurrence is enabled for the event being created.
@override@JsonKey() final  bool isEnabled;
/// Repeat pattern (weekly / biweekly / monthly).
@override@JsonKey() final  RecurrencePattern pattern;
/// Days of week to generate events on (0=Sun … 6=Sat, JavaScript convention).
/// Used for weekly and biweekly patterns.
 final  List<int> _daysOfWeek;
/// Days of week to generate events on (0=Sun … 6=Sat, JavaScript convention).
/// Used for weekly and biweekly patterns.
@override@JsonKey() List<int> get daysOfWeek {
  if (_daysOfWeek is EqualUnmodifiableListView) return _daysOfWeek;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_daysOfWeek);
}

/// Day of month (1–31) for monthly pattern.
@override final  int? monthDay;
/// Optional rule end date in YYYY-MM-DD format.
@override final  String? endDate;

/// Create a copy of RecurrenceSettingsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecurrenceSettingsStateCopyWith<_RecurrenceSettingsState> get copyWith => __$RecurrenceSettingsStateCopyWithImpl<_RecurrenceSettingsState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecurrenceSettingsState&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.pattern, pattern) || other.pattern == pattern)&&const DeepCollectionEquality().equals(other._daysOfWeek, _daysOfWeek)&&(identical(other.monthDay, monthDay) || other.monthDay == monthDay)&&(identical(other.endDate, endDate) || other.endDate == endDate));
}


@override
int get hashCode => Object.hash(runtimeType,isEnabled,pattern,const DeepCollectionEquality().hash(_daysOfWeek),monthDay,endDate);

@override
String toString() {
  return 'RecurrenceSettingsState(isEnabled: $isEnabled, pattern: $pattern, daysOfWeek: $daysOfWeek, monthDay: $monthDay, endDate: $endDate)';
}


}

/// @nodoc
abstract mixin class _$RecurrenceSettingsStateCopyWith<$Res> implements $RecurrenceSettingsStateCopyWith<$Res> {
  factory _$RecurrenceSettingsStateCopyWith(_RecurrenceSettingsState value, $Res Function(_RecurrenceSettingsState) _then) = __$RecurrenceSettingsStateCopyWithImpl;
@override @useResult
$Res call({
 bool isEnabled, RecurrencePattern pattern, List<int> daysOfWeek, int? monthDay, String? endDate
});




}
/// @nodoc
class __$RecurrenceSettingsStateCopyWithImpl<$Res>
    implements _$RecurrenceSettingsStateCopyWith<$Res> {
  __$RecurrenceSettingsStateCopyWithImpl(this._self, this._then);

  final _RecurrenceSettingsState _self;
  final $Res Function(_RecurrenceSettingsState) _then;

/// Create a copy of RecurrenceSettingsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isEnabled = null,Object? pattern = null,Object? daysOfWeek = null,Object? monthDay = freezed,Object? endDate = freezed,}) {
  return _then(_RecurrenceSettingsState(
isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,pattern: null == pattern ? _self.pattern : pattern // ignore: cast_nullable_to_non_nullable
as RecurrencePattern,daysOfWeek: null == daysOfWeek ? _self._daysOfWeek : daysOfWeek // ignore: cast_nullable_to_non_nullable
as List<int>,monthDay: freezed == monthDay ? _self.monthDay : monthDay // ignore: cast_nullable_to_non_nullable
as int?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
