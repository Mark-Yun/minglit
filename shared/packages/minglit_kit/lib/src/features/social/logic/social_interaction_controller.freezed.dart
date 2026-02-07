// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'social_interaction_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InteractionState {

/// Whether the current user has the interaction active.
 bool get isActive;/// Total count for this interaction type.
 int get count;
/// Create a copy of InteractionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InteractionStateCopyWith<InteractionState> get copyWith => _$InteractionStateCopyWithImpl<InteractionState>(this as InteractionState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InteractionState&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.count, count) || other.count == count));
}


@override
int get hashCode => Object.hash(runtimeType,isActive,count);

@override
String toString() {
  return 'InteractionState(isActive: $isActive, count: $count)';
}


}

/// @nodoc
abstract mixin class $InteractionStateCopyWith<$Res>  {
  factory $InteractionStateCopyWith(InteractionState value, $Res Function(InteractionState) _then) = _$InteractionStateCopyWithImpl;
@useResult
$Res call({
 bool isActive, int count
});




}
/// @nodoc
class _$InteractionStateCopyWithImpl<$Res>
    implements $InteractionStateCopyWith<$Res> {
  _$InteractionStateCopyWithImpl(this._self, this._then);

  final InteractionState _self;
  final $Res Function(InteractionState) _then;

/// Create a copy of InteractionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isActive = null,Object? count = null,}) {
  return _then(_self.copyWith(
isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [InteractionState].
extension InteractionStatePatterns on InteractionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InteractionState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InteractionState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InteractionState value)  $default,){
final _that = this;
switch (_that) {
case _InteractionState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InteractionState value)?  $default,){
final _that = this;
switch (_that) {
case _InteractionState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isActive,  int count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InteractionState() when $default != null:
return $default(_that.isActive,_that.count);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isActive,  int count)  $default,) {final _that = this;
switch (_that) {
case _InteractionState():
return $default(_that.isActive,_that.count);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isActive,  int count)?  $default,) {final _that = this;
switch (_that) {
case _InteractionState() when $default != null:
return $default(_that.isActive,_that.count);case _:
  return null;

}
}

}

/// @nodoc


class _InteractionState implements InteractionState {
  const _InteractionState({required this.isActive, required this.count});
  

/// Whether the current user has the interaction active.
@override final  bool isActive;
/// Total count for this interaction type.
@override final  int count;

/// Create a copy of InteractionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InteractionStateCopyWith<_InteractionState> get copyWith => __$InteractionStateCopyWithImpl<_InteractionState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InteractionState&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.count, count) || other.count == count));
}


@override
int get hashCode => Object.hash(runtimeType,isActive,count);

@override
String toString() {
  return 'InteractionState(isActive: $isActive, count: $count)';
}


}

/// @nodoc
abstract mixin class _$InteractionStateCopyWith<$Res> implements $InteractionStateCopyWith<$Res> {
  factory _$InteractionStateCopyWith(_InteractionState value, $Res Function(_InteractionState) _then) = __$InteractionStateCopyWithImpl;
@override @useResult
$Res call({
 bool isActive, int count
});




}
/// @nodoc
class __$InteractionStateCopyWithImpl<$Res>
    implements _$InteractionStateCopyWith<$Res> {
  __$InteractionStateCopyWithImpl(this._self, this._then);

  final _InteractionState _self;
  final $Res Function(_InteractionState) _then;

/// Create a copy of InteractionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isActive = null,Object? count = null,}) {
  return _then(_InteractionState(
isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
