// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'verification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VerificationRequirementStatus {

 Map<String, dynamic> get master; Map<String, dynamic>? get originalData; Map<String, dynamic>? get activeRequest; Map<String, dynamic>? get verifiedResult;
/// Create a copy of VerificationRequirementStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerificationRequirementStatusCopyWith<VerificationRequirementStatus> get copyWith => _$VerificationRequirementStatusCopyWithImpl<VerificationRequirementStatus>(this as VerificationRequirementStatus, _$identity);

  /// Serializes this VerificationRequirementStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerificationRequirementStatus&&const DeepCollectionEquality().equals(other.master, master)&&const DeepCollectionEquality().equals(other.originalData, originalData)&&const DeepCollectionEquality().equals(other.activeRequest, activeRequest)&&const DeepCollectionEquality().equals(other.verifiedResult, verifiedResult));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(master),const DeepCollectionEquality().hash(originalData),const DeepCollectionEquality().hash(activeRequest),const DeepCollectionEquality().hash(verifiedResult));

@override
String toString() {
  return 'VerificationRequirementStatus(master: $master, originalData: $originalData, activeRequest: $activeRequest, verifiedResult: $verifiedResult)';
}


}

/// @nodoc
abstract mixin class $VerificationRequirementStatusCopyWith<$Res>  {
  factory $VerificationRequirementStatusCopyWith(VerificationRequirementStatus value, $Res Function(VerificationRequirementStatus) _then) = _$VerificationRequirementStatusCopyWithImpl;
@useResult
$Res call({
 Map<String, dynamic> master, Map<String, dynamic>? originalData, Map<String, dynamic>? activeRequest, Map<String, dynamic>? verifiedResult
});




}
/// @nodoc
class _$VerificationRequirementStatusCopyWithImpl<$Res>
    implements $VerificationRequirementStatusCopyWith<$Res> {
  _$VerificationRequirementStatusCopyWithImpl(this._self, this._then);

  final VerificationRequirementStatus _self;
  final $Res Function(VerificationRequirementStatus) _then;

/// Create a copy of VerificationRequirementStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? master = null,Object? originalData = freezed,Object? activeRequest = freezed,Object? verifiedResult = freezed,}) {
  return _then(_self.copyWith(
master: null == master ? _self.master : master // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,originalData: freezed == originalData ? _self.originalData : originalData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,activeRequest: freezed == activeRequest ? _self.activeRequest : activeRequest // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,verifiedResult: freezed == verifiedResult ? _self.verifiedResult : verifiedResult // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [VerificationRequirementStatus].
extension VerificationRequirementStatusPatterns on VerificationRequirementStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VerificationRequirementStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VerificationRequirementStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VerificationRequirementStatus value)  $default,){
final _that = this;
switch (_that) {
case _VerificationRequirementStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VerificationRequirementStatus value)?  $default,){
final _that = this;
switch (_that) {
case _VerificationRequirementStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, dynamic> master,  Map<String, dynamic>? originalData,  Map<String, dynamic>? activeRequest,  Map<String, dynamic>? verifiedResult)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VerificationRequirementStatus() when $default != null:
return $default(_that.master,_that.originalData,_that.activeRequest,_that.verifiedResult);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, dynamic> master,  Map<String, dynamic>? originalData,  Map<String, dynamic>? activeRequest,  Map<String, dynamic>? verifiedResult)  $default,) {final _that = this;
switch (_that) {
case _VerificationRequirementStatus():
return $default(_that.master,_that.originalData,_that.activeRequest,_that.verifiedResult);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, dynamic> master,  Map<String, dynamic>? originalData,  Map<String, dynamic>? activeRequest,  Map<String, dynamic>? verifiedResult)?  $default,) {final _that = this;
switch (_that) {
case _VerificationRequirementStatus() when $default != null:
return $default(_that.master,_that.originalData,_that.activeRequest,_that.verifiedResult);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VerificationRequirementStatus extends VerificationRequirementStatus {
  const _VerificationRequirementStatus({required final  Map<String, dynamic> master, final  Map<String, dynamic>? originalData, final  Map<String, dynamic>? activeRequest, final  Map<String, dynamic>? verifiedResult}): _master = master,_originalData = originalData,_activeRequest = activeRequest,_verifiedResult = verifiedResult,super._();
  factory _VerificationRequirementStatus.fromJson(Map<String, dynamic> json) => _$VerificationRequirementStatusFromJson(json);

 final  Map<String, dynamic> _master;
@override Map<String, dynamic> get master {
  if (_master is EqualUnmodifiableMapView) return _master;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_master);
}

 final  Map<String, dynamic>? _originalData;
@override Map<String, dynamic>? get originalData {
  final value = _originalData;
  if (value == null) return null;
  if (_originalData is EqualUnmodifiableMapView) return _originalData;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  Map<String, dynamic>? _activeRequest;
@override Map<String, dynamic>? get activeRequest {
  final value = _activeRequest;
  if (value == null) return null;
  if (_activeRequest is EqualUnmodifiableMapView) return _activeRequest;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  Map<String, dynamic>? _verifiedResult;
@override Map<String, dynamic>? get verifiedResult {
  final value = _verifiedResult;
  if (value == null) return null;
  if (_verifiedResult is EqualUnmodifiableMapView) return _verifiedResult;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of VerificationRequirementStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VerificationRequirementStatusCopyWith<_VerificationRequirementStatus> get copyWith => __$VerificationRequirementStatusCopyWithImpl<_VerificationRequirementStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VerificationRequirementStatusToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VerificationRequirementStatus&&const DeepCollectionEquality().equals(other._master, _master)&&const DeepCollectionEquality().equals(other._originalData, _originalData)&&const DeepCollectionEquality().equals(other._activeRequest, _activeRequest)&&const DeepCollectionEquality().equals(other._verifiedResult, _verifiedResult));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_master),const DeepCollectionEquality().hash(_originalData),const DeepCollectionEquality().hash(_activeRequest),const DeepCollectionEquality().hash(_verifiedResult));

@override
String toString() {
  return 'VerificationRequirementStatus(master: $master, originalData: $originalData, activeRequest: $activeRequest, verifiedResult: $verifiedResult)';
}


}

/// @nodoc
abstract mixin class _$VerificationRequirementStatusCopyWith<$Res> implements $VerificationRequirementStatusCopyWith<$Res> {
  factory _$VerificationRequirementStatusCopyWith(_VerificationRequirementStatus value, $Res Function(_VerificationRequirementStatus) _then) = __$VerificationRequirementStatusCopyWithImpl;
@override @useResult
$Res call({
 Map<String, dynamic> master, Map<String, dynamic>? originalData, Map<String, dynamic>? activeRequest, Map<String, dynamic>? verifiedResult
});




}
/// @nodoc
class __$VerificationRequirementStatusCopyWithImpl<$Res>
    implements _$VerificationRequirementStatusCopyWith<$Res> {
  __$VerificationRequirementStatusCopyWithImpl(this._self, this._then);

  final _VerificationRequirementStatus _self;
  final $Res Function(_VerificationRequirementStatus) _then;

/// Create a copy of VerificationRequirementStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? master = null,Object? originalData = freezed,Object? activeRequest = freezed,Object? verifiedResult = freezed,}) {
  return _then(_VerificationRequirementStatus(
master: null == master ? _self._master : master // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,originalData: freezed == originalData ? _self._originalData : originalData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,activeRequest: freezed == activeRequest ? _self._activeRequest : activeRequest // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,verifiedResult: freezed == verifiedResult ? _self._verifiedResult : verifiedResult // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
