// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'global_loading_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GlobalLoadingState {

 bool get isVisible; VoidCallback? get onCancel;
/// Create a copy of GlobalLoadingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GlobalLoadingStateCopyWith<GlobalLoadingState> get copyWith => _$GlobalLoadingStateCopyWithImpl<GlobalLoadingState>(this as GlobalLoadingState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GlobalLoadingState&&(identical(other.isVisible, isVisible) || other.isVisible == isVisible)&&(identical(other.onCancel, onCancel) || other.onCancel == onCancel));
}


@override
int get hashCode => Object.hash(runtimeType,isVisible,onCancel);

@override
String toString() {
  return 'GlobalLoadingState(isVisible: $isVisible, onCancel: $onCancel)';
}


}

/// @nodoc
abstract mixin class $GlobalLoadingStateCopyWith<$Res>  {
  factory $GlobalLoadingStateCopyWith(GlobalLoadingState value, $Res Function(GlobalLoadingState) _then) = _$GlobalLoadingStateCopyWithImpl;
@useResult
$Res call({
 bool isVisible, VoidCallback? onCancel
});




}
/// @nodoc
class _$GlobalLoadingStateCopyWithImpl<$Res>
    implements $GlobalLoadingStateCopyWith<$Res> {
  _$GlobalLoadingStateCopyWithImpl(this._self, this._then);

  final GlobalLoadingState _self;
  final $Res Function(GlobalLoadingState) _then;

/// Create a copy of GlobalLoadingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isVisible = null,Object? onCancel = freezed,}) {
  return _then(_self.copyWith(
isVisible: null == isVisible ? _self.isVisible : isVisible // ignore: cast_nullable_to_non_nullable
as bool,onCancel: freezed == onCancel ? _self.onCancel : onCancel // ignore: cast_nullable_to_non_nullable
as VoidCallback?,
  ));
}

}


/// Adds pattern-matching-related methods to [GlobalLoadingState].
extension GlobalLoadingStatePatterns on GlobalLoadingState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GlobalLoadingState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GlobalLoadingState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GlobalLoadingState value)  $default,){
final _that = this;
switch (_that) {
case _GlobalLoadingState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GlobalLoadingState value)?  $default,){
final _that = this;
switch (_that) {
case _GlobalLoadingState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isVisible,  VoidCallback? onCancel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GlobalLoadingState() when $default != null:
return $default(_that.isVisible,_that.onCancel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isVisible,  VoidCallback? onCancel)  $default,) {final _that = this;
switch (_that) {
case _GlobalLoadingState():
return $default(_that.isVisible,_that.onCancel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isVisible,  VoidCallback? onCancel)?  $default,) {final _that = this;
switch (_that) {
case _GlobalLoadingState() when $default != null:
return $default(_that.isVisible,_that.onCancel);case _:
  return null;

}
}

}

/// @nodoc


class _GlobalLoadingState implements GlobalLoadingState {
  const _GlobalLoadingState({this.isVisible = false, this.onCancel});
  

@override@JsonKey() final  bool isVisible;
@override final  VoidCallback? onCancel;

/// Create a copy of GlobalLoadingState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GlobalLoadingStateCopyWith<_GlobalLoadingState> get copyWith => __$GlobalLoadingStateCopyWithImpl<_GlobalLoadingState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GlobalLoadingState&&(identical(other.isVisible, isVisible) || other.isVisible == isVisible)&&(identical(other.onCancel, onCancel) || other.onCancel == onCancel));
}


@override
int get hashCode => Object.hash(runtimeType,isVisible,onCancel);

@override
String toString() {
  return 'GlobalLoadingState(isVisible: $isVisible, onCancel: $onCancel)';
}


}

/// @nodoc
abstract mixin class _$GlobalLoadingStateCopyWith<$Res> implements $GlobalLoadingStateCopyWith<$Res> {
  factory _$GlobalLoadingStateCopyWith(_GlobalLoadingState value, $Res Function(_GlobalLoadingState) _then) = __$GlobalLoadingStateCopyWithImpl;
@override @useResult
$Res call({
 bool isVisible, VoidCallback? onCancel
});




}
/// @nodoc
class __$GlobalLoadingStateCopyWithImpl<$Res>
    implements _$GlobalLoadingStateCopyWith<$Res> {
  __$GlobalLoadingStateCopyWithImpl(this._self, this._then);

  final _GlobalLoadingState _self;
  final $Res Function(_GlobalLoadingState) _then;

/// Create a copy of GlobalLoadingState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isVisible = null,Object? onCancel = freezed,}) {
  return _then(_GlobalLoadingState(
isVisible: null == isVisible ? _self.isVisible : isVisible // ignore: cast_nullable_to_non_nullable
as bool,onCancel: freezed == onCancel ? _self.onCancel : onCancel // ignore: cast_nullable_to_non_nullable
as VoidCallback?,
  ));
}


}

// dart format on
