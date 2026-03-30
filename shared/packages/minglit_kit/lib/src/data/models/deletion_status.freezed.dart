// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'deletion_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DeletionStatus {

@JsonKey(name: 'deleted_at') DateTime? get deletedAt;@JsonKey(name: 'grace_period_ends') DateTime? get gracePeriodEnds; bool get isPending;
/// Create a copy of DeletionStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeletionStatusCopyWith<DeletionStatus> get copyWith => _$DeletionStatusCopyWithImpl<DeletionStatus>(this as DeletionStatus, _$identity);

  /// Serializes this DeletionStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeletionStatus&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.gracePeriodEnds, gracePeriodEnds) || other.gracePeriodEnds == gracePeriodEnds)&&(identical(other.isPending, isPending) || other.isPending == isPending));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,deletedAt,gracePeriodEnds,isPending);

@override
String toString() {
  return 'DeletionStatus(deletedAt: $deletedAt, gracePeriodEnds: $gracePeriodEnds, isPending: $isPending)';
}


}

/// @nodoc
abstract mixin class $DeletionStatusCopyWith<$Res>  {
  factory $DeletionStatusCopyWith(DeletionStatus value, $Res Function(DeletionStatus) _then) = _$DeletionStatusCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'deleted_at') DateTime? deletedAt,@JsonKey(name: 'grace_period_ends') DateTime? gracePeriodEnds, bool isPending
});




}
/// @nodoc
class _$DeletionStatusCopyWithImpl<$Res>
    implements $DeletionStatusCopyWith<$Res> {
  _$DeletionStatusCopyWithImpl(this._self, this._then);

  final DeletionStatus _self;
  final $Res Function(DeletionStatus) _then;

/// Create a copy of DeletionStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deletedAt = freezed,Object? gracePeriodEnds = freezed,Object? isPending = null,}) {
  return _then(_self.copyWith(
deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,gracePeriodEnds: freezed == gracePeriodEnds ? _self.gracePeriodEnds : gracePeriodEnds // ignore: cast_nullable_to_non_nullable
as DateTime?,isPending: null == isPending ? _self.isPending : isPending // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DeletionStatus].
extension DeletionStatusPatterns on DeletionStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeletionStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeletionStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeletionStatus value)  $default,){
final _that = this;
switch (_that) {
case _DeletionStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeletionStatus value)?  $default,){
final _that = this;
switch (_that) {
case _DeletionStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'deleted_at')  DateTime? deletedAt, @JsonKey(name: 'grace_period_ends')  DateTime? gracePeriodEnds,  bool isPending)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeletionStatus() when $default != null:
return $default(_that.deletedAt,_that.gracePeriodEnds,_that.isPending);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'deleted_at')  DateTime? deletedAt, @JsonKey(name: 'grace_period_ends')  DateTime? gracePeriodEnds,  bool isPending)  $default,) {final _that = this;
switch (_that) {
case _DeletionStatus():
return $default(_that.deletedAt,_that.gracePeriodEnds,_that.isPending);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'deleted_at')  DateTime? deletedAt, @JsonKey(name: 'grace_period_ends')  DateTime? gracePeriodEnds,  bool isPending)?  $default,) {final _that = this;
switch (_that) {
case _DeletionStatus() when $default != null:
return $default(_that.deletedAt,_that.gracePeriodEnds,_that.isPending);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeletionStatus implements DeletionStatus {
  const _DeletionStatus({@JsonKey(name: 'deleted_at') this.deletedAt, @JsonKey(name: 'grace_period_ends') this.gracePeriodEnds, this.isPending = false});
  factory _DeletionStatus.fromJson(Map<String, dynamic> json) => _$DeletionStatusFromJson(json);

@override@JsonKey(name: 'deleted_at') final  DateTime? deletedAt;
@override@JsonKey(name: 'grace_period_ends') final  DateTime? gracePeriodEnds;
@override@JsonKey() final  bool isPending;

/// Create a copy of DeletionStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeletionStatusCopyWith<_DeletionStatus> get copyWith => __$DeletionStatusCopyWithImpl<_DeletionStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeletionStatusToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeletionStatus&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.gracePeriodEnds, gracePeriodEnds) || other.gracePeriodEnds == gracePeriodEnds)&&(identical(other.isPending, isPending) || other.isPending == isPending));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,deletedAt,gracePeriodEnds,isPending);

@override
String toString() {
  return 'DeletionStatus(deletedAt: $deletedAt, gracePeriodEnds: $gracePeriodEnds, isPending: $isPending)';
}


}

/// @nodoc
abstract mixin class _$DeletionStatusCopyWith<$Res> implements $DeletionStatusCopyWith<$Res> {
  factory _$DeletionStatusCopyWith(_DeletionStatus value, $Res Function(_DeletionStatus) _then) = __$DeletionStatusCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'deleted_at') DateTime? deletedAt,@JsonKey(name: 'grace_period_ends') DateTime? gracePeriodEnds, bool isPending
});




}
/// @nodoc
class __$DeletionStatusCopyWithImpl<$Res>
    implements _$DeletionStatusCopyWith<$Res> {
  __$DeletionStatusCopyWithImpl(this._self, this._then);

  final _DeletionStatus _self;
  final $Res Function(_DeletionStatus) _then;

/// Create a copy of DeletionStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deletedAt = freezed,Object? gracePeriodEnds = freezed,Object? isPending = null,}) {
  return _then(_DeletionStatus(
deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,gracePeriodEnds: freezed == gracePeriodEnds ? _self.gracePeriodEnds : gracePeriodEnds // ignore: cast_nullable_to_non_nullable
as DateTime?,isPending: null == isPending ? _self.isPending : isPending // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
