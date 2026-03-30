// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'withdrawal_reason.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WithdrawalReason {

@JsonKey(name: 'reason_code') WithdrawalReasonCode get reasonCode;@JsonKey(name: 'reason_text') String? get detail;
/// Create a copy of WithdrawalReason
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WithdrawalReasonCopyWith<WithdrawalReason> get copyWith => _$WithdrawalReasonCopyWithImpl<WithdrawalReason>(this as WithdrawalReason, _$identity);

  /// Serializes this WithdrawalReason to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WithdrawalReason&&(identical(other.reasonCode, reasonCode) || other.reasonCode == reasonCode)&&(identical(other.detail, detail) || other.detail == detail));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reasonCode,detail);

@override
String toString() {
  return 'WithdrawalReason(reasonCode: $reasonCode, detail: $detail)';
}


}

/// @nodoc
abstract mixin class $WithdrawalReasonCopyWith<$Res>  {
  factory $WithdrawalReasonCopyWith(WithdrawalReason value, $Res Function(WithdrawalReason) _then) = _$WithdrawalReasonCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'reason_code') WithdrawalReasonCode reasonCode,@JsonKey(name: 'reason_text') String? detail
});




}
/// @nodoc
class _$WithdrawalReasonCopyWithImpl<$Res>
    implements $WithdrawalReasonCopyWith<$Res> {
  _$WithdrawalReasonCopyWithImpl(this._self, this._then);

  final WithdrawalReason _self;
  final $Res Function(WithdrawalReason) _then;

/// Create a copy of WithdrawalReason
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reasonCode = null,Object? detail = freezed,}) {
  return _then(_self.copyWith(
reasonCode: null == reasonCode ? _self.reasonCode : reasonCode // ignore: cast_nullable_to_non_nullable
as WithdrawalReasonCode,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WithdrawalReason].
extension WithdrawalReasonPatterns on WithdrawalReason {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WithdrawalReason value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WithdrawalReason() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WithdrawalReason value)  $default,){
final _that = this;
switch (_that) {
case _WithdrawalReason():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WithdrawalReason value)?  $default,){
final _that = this;
switch (_that) {
case _WithdrawalReason() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'reason_code')  WithdrawalReasonCode reasonCode, @JsonKey(name: 'reason_text')  String? detail)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WithdrawalReason() when $default != null:
return $default(_that.reasonCode,_that.detail);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'reason_code')  WithdrawalReasonCode reasonCode, @JsonKey(name: 'reason_text')  String? detail)  $default,) {final _that = this;
switch (_that) {
case _WithdrawalReason():
return $default(_that.reasonCode,_that.detail);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'reason_code')  WithdrawalReasonCode reasonCode, @JsonKey(name: 'reason_text')  String? detail)?  $default,) {final _that = this;
switch (_that) {
case _WithdrawalReason() when $default != null:
return $default(_that.reasonCode,_that.detail);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WithdrawalReason implements WithdrawalReason {
  const _WithdrawalReason({@JsonKey(name: 'reason_code') required this.reasonCode, @JsonKey(name: 'reason_text') this.detail});
  factory _WithdrawalReason.fromJson(Map<String, dynamic> json) => _$WithdrawalReasonFromJson(json);

@override@JsonKey(name: 'reason_code') final  WithdrawalReasonCode reasonCode;
@override@JsonKey(name: 'reason_text') final  String? detail;

/// Create a copy of WithdrawalReason
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WithdrawalReasonCopyWith<_WithdrawalReason> get copyWith => __$WithdrawalReasonCopyWithImpl<_WithdrawalReason>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WithdrawalReasonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WithdrawalReason&&(identical(other.reasonCode, reasonCode) || other.reasonCode == reasonCode)&&(identical(other.detail, detail) || other.detail == detail));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reasonCode,detail);

@override
String toString() {
  return 'WithdrawalReason(reasonCode: $reasonCode, detail: $detail)';
}


}

/// @nodoc
abstract mixin class _$WithdrawalReasonCopyWith<$Res> implements $WithdrawalReasonCopyWith<$Res> {
  factory _$WithdrawalReasonCopyWith(_WithdrawalReason value, $Res Function(_WithdrawalReason) _then) = __$WithdrawalReasonCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'reason_code') WithdrawalReasonCode reasonCode,@JsonKey(name: 'reason_text') String? detail
});




}
/// @nodoc
class __$WithdrawalReasonCopyWithImpl<$Res>
    implements _$WithdrawalReasonCopyWith<$Res> {
  __$WithdrawalReasonCopyWithImpl(this._self, this._then);

  final _WithdrawalReason _self;
  final $Res Function(_WithdrawalReason) _then;

/// Create a copy of WithdrawalReason
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reasonCode = null,Object? detail = freezed,}) {
  return _then(_WithdrawalReason(
reasonCode: null == reasonCode ? _self.reasonCode : reasonCode // ignore: cast_nullable_to_non_nullable
as WithdrawalReasonCode,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
