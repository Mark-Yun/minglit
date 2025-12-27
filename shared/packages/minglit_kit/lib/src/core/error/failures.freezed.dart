// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'failures.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Failure {

 String get message;
/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FailureCopyWith<Failure> get copyWith => _$FailureCopyWithImpl<Failure>(this as Failure, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Failure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'Failure(message: $message)';
}


}

/// @nodoc
abstract mixin class $FailureCopyWith<$Res>  {
  factory $FailureCopyWith(Failure value, $Res Function(Failure) _then) = _$FailureCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$FailureCopyWithImpl<$Res>
    implements $FailureCopyWith<$Res> {
  _$FailureCopyWithImpl(this._self, this._then);

  final Failure _self;
  final $Res Function(Failure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? message = null,}) {
  return _then(_self.copyWith(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Failure].
extension FailurePatterns on Failure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _ServerFailure value)?  server,TResult Function( _NetworkFailure value)?  network,TResult Function( _AuthFailure value)?  auth,TResult Function( _ValidationFailure value)?  validation,TResult Function( _UnknownFailure value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServerFailure() when server != null:
return server(_that);case _NetworkFailure() when network != null:
return network(_that);case _AuthFailure() when auth != null:
return auth(_that);case _ValidationFailure() when validation != null:
return validation(_that);case _UnknownFailure() when unknown != null:
return unknown(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _ServerFailure value)  server,required TResult Function( _NetworkFailure value)  network,required TResult Function( _AuthFailure value)  auth,required TResult Function( _ValidationFailure value)  validation,required TResult Function( _UnknownFailure value)  unknown,}){
final _that = this;
switch (_that) {
case _ServerFailure():
return server(_that);case _NetworkFailure():
return network(_that);case _AuthFailure():
return auth(_that);case _ValidationFailure():
return validation(_that);case _UnknownFailure():
return unknown(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _ServerFailure value)?  server,TResult? Function( _NetworkFailure value)?  network,TResult? Function( _AuthFailure value)?  auth,TResult? Function( _ValidationFailure value)?  validation,TResult? Function( _UnknownFailure value)?  unknown,}){
final _that = this;
switch (_that) {
case _ServerFailure() when server != null:
return server(_that);case _NetworkFailure() when network != null:
return network(_that);case _AuthFailure() when auth != null:
return auth(_that);case _ValidationFailure() when validation != null:
return validation(_that);case _UnknownFailure() when unknown != null:
return unknown(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String message)?  server,TResult Function( String message)?  network,TResult Function( String message)?  auth,TResult Function( String message)?  validation,TResult Function( String message)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServerFailure() when server != null:
return server(_that.message);case _NetworkFailure() when network != null:
return network(_that.message);case _AuthFailure() when auth != null:
return auth(_that.message);case _ValidationFailure() when validation != null:
return validation(_that.message);case _UnknownFailure() when unknown != null:
return unknown(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String message)  server,required TResult Function( String message)  network,required TResult Function( String message)  auth,required TResult Function( String message)  validation,required TResult Function( String message)  unknown,}) {final _that = this;
switch (_that) {
case _ServerFailure():
return server(_that.message);case _NetworkFailure():
return network(_that.message);case _AuthFailure():
return auth(_that.message);case _ValidationFailure():
return validation(_that.message);case _UnknownFailure():
return unknown(_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String message)?  server,TResult? Function( String message)?  network,TResult? Function( String message)?  auth,TResult? Function( String message)?  validation,TResult? Function( String message)?  unknown,}) {final _that = this;
switch (_that) {
case _ServerFailure() when server != null:
return server(_that.message);case _NetworkFailure() when network != null:
return network(_that.message);case _AuthFailure() when auth != null:
return auth(_that.message);case _ValidationFailure() when validation != null:
return validation(_that.message);case _UnknownFailure() when unknown != null:
return unknown(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _ServerFailure extends Failure {
  const _ServerFailure({required this.message}): super._();
  

@override final  String message;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServerFailureCopyWith<_ServerFailure> get copyWith => __$ServerFailureCopyWithImpl<_ServerFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServerFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'Failure.server(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ServerFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory _$ServerFailureCopyWith(_ServerFailure value, $Res Function(_ServerFailure) _then) = __$ServerFailureCopyWithImpl;
@override @useResult
$Res call({
 String message
});




}
/// @nodoc
class __$ServerFailureCopyWithImpl<$Res>
    implements _$ServerFailureCopyWith<$Res> {
  __$ServerFailureCopyWithImpl(this._self, this._then);

  final _ServerFailure _self;
  final $Res Function(_ServerFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_ServerFailure(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _NetworkFailure extends Failure {
  const _NetworkFailure({this.message = '네트워크 연결을 확인해 주세요.'}): super._();
  

@override@JsonKey() final  String message;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NetworkFailureCopyWith<_NetworkFailure> get copyWith => __$NetworkFailureCopyWithImpl<_NetworkFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NetworkFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'Failure.network(message: $message)';
}


}

/// @nodoc
abstract mixin class _$NetworkFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory _$NetworkFailureCopyWith(_NetworkFailure value, $Res Function(_NetworkFailure) _then) = __$NetworkFailureCopyWithImpl;
@override @useResult
$Res call({
 String message
});




}
/// @nodoc
class __$NetworkFailureCopyWithImpl<$Res>
    implements _$NetworkFailureCopyWith<$Res> {
  __$NetworkFailureCopyWithImpl(this._self, this._then);

  final _NetworkFailure _self;
  final $Res Function(_NetworkFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_NetworkFailure(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _AuthFailure extends Failure {
  const _AuthFailure({required this.message}): super._();
  

@override final  String message;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthFailureCopyWith<_AuthFailure> get copyWith => __$AuthFailureCopyWithImpl<_AuthFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'Failure.auth(message: $message)';
}


}

/// @nodoc
abstract mixin class _$AuthFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory _$AuthFailureCopyWith(_AuthFailure value, $Res Function(_AuthFailure) _then) = __$AuthFailureCopyWithImpl;
@override @useResult
$Res call({
 String message
});




}
/// @nodoc
class __$AuthFailureCopyWithImpl<$Res>
    implements _$AuthFailureCopyWith<$Res> {
  __$AuthFailureCopyWithImpl(this._self, this._then);

  final _AuthFailure _self;
  final $Res Function(_AuthFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_AuthFailure(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _ValidationFailure extends Failure {
  const _ValidationFailure({required this.message}): super._();
  

@override final  String message;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ValidationFailureCopyWith<_ValidationFailure> get copyWith => __$ValidationFailureCopyWithImpl<_ValidationFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ValidationFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'Failure.validation(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ValidationFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory _$ValidationFailureCopyWith(_ValidationFailure value, $Res Function(_ValidationFailure) _then) = __$ValidationFailureCopyWithImpl;
@override @useResult
$Res call({
 String message
});




}
/// @nodoc
class __$ValidationFailureCopyWithImpl<$Res>
    implements _$ValidationFailureCopyWith<$Res> {
  __$ValidationFailureCopyWithImpl(this._self, this._then);

  final _ValidationFailure _self;
  final $Res Function(_ValidationFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_ValidationFailure(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _UnknownFailure extends Failure {
  const _UnknownFailure({this.message = '알 수 없는 오류가 발생했습니다.'}): super._();
  

@override@JsonKey() final  String message;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UnknownFailureCopyWith<_UnknownFailure> get copyWith => __$UnknownFailureCopyWithImpl<_UnknownFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UnknownFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'Failure.unknown(message: $message)';
}


}

/// @nodoc
abstract mixin class _$UnknownFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory _$UnknownFailureCopyWith(_UnknownFailure value, $Res Function(_UnknownFailure) _then) = __$UnknownFailureCopyWithImpl;
@override @useResult
$Res call({
 String message
});




}
/// @nodoc
class __$UnknownFailureCopyWithImpl<$Res>
    implements _$UnknownFailureCopyWith<$Res> {
  __$UnknownFailureCopyWithImpl(this._self, this._then);

  final _UnknownFailure _self;
  final $Res Function(_UnknownFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_UnknownFailure(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
