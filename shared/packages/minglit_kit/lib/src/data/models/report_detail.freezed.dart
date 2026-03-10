// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'report_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReportDetail {

 String get id;@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'target_id') String get targetId;@JsonKey(name: 'target_type') SocialTargetType get targetType; String get reason; String? get description;@JsonKey(name: 'created_at') DateTime get createdAt;
/// Create a copy of ReportDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReportDetailCopyWith<ReportDetail> get copyWith => _$ReportDetailCopyWithImpl<ReportDetail>(this as ReportDetail, _$identity);

  /// Serializes this ReportDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReportDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.description, description) || other.description == description)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,targetId,targetType,reason,description,createdAt);

@override
String toString() {
  return 'ReportDetail(id: $id, userId: $userId, targetId: $targetId, targetType: $targetType, reason: $reason, description: $description, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ReportDetailCopyWith<$Res>  {
  factory $ReportDetailCopyWith(ReportDetail value, $Res Function(ReportDetail) _then) = _$ReportDetailCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'target_id') String targetId,@JsonKey(name: 'target_type') SocialTargetType targetType, String reason, String? description,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class _$ReportDetailCopyWithImpl<$Res>
    implements $ReportDetailCopyWith<$Res> {
  _$ReportDetailCopyWithImpl(this._self, this._then);

  final ReportDetail _self;
  final $Res Function(ReportDetail) _then;

/// Create a copy of ReportDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? targetId = null,Object? targetType = null,Object? reason = null,Object? description = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as SocialTargetType,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ReportDetail].
extension ReportDetailPatterns on ReportDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReportDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReportDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReportDetail value)  $default,){
final _that = this;
switch (_that) {
case _ReportDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReportDetail value)?  $default,){
final _that = this;
switch (_that) {
case _ReportDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'target_id')  String targetId, @JsonKey(name: 'target_type')  SocialTargetType targetType,  String reason,  String? description, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReportDetail() when $default != null:
return $default(_that.id,_that.userId,_that.targetId,_that.targetType,_that.reason,_that.description,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'target_id')  String targetId, @JsonKey(name: 'target_type')  SocialTargetType targetType,  String reason,  String? description, @JsonKey(name: 'created_at')  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _ReportDetail():
return $default(_that.id,_that.userId,_that.targetId,_that.targetType,_that.reason,_that.description,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'target_id')  String targetId, @JsonKey(name: 'target_type')  SocialTargetType targetType,  String reason,  String? description, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ReportDetail() when $default != null:
return $default(_that.id,_that.userId,_that.targetId,_that.targetType,_that.reason,_that.description,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReportDetail implements ReportDetail {
  const _ReportDetail({required this.id, @JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'target_id') required this.targetId, @JsonKey(name: 'target_type') required this.targetType, required this.reason, this.description, @JsonKey(name: 'created_at') required this.createdAt});
  factory _ReportDetail.fromJson(Map<String, dynamic> json) => _$ReportDetailFromJson(json);

@override final  String id;
@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'target_id') final  String targetId;
@override@JsonKey(name: 'target_type') final  SocialTargetType targetType;
@override final  String reason;
@override final  String? description;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;

/// Create a copy of ReportDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReportDetailCopyWith<_ReportDetail> get copyWith => __$ReportDetailCopyWithImpl<_ReportDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReportDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReportDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.description, description) || other.description == description)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,targetId,targetType,reason,description,createdAt);

@override
String toString() {
  return 'ReportDetail(id: $id, userId: $userId, targetId: $targetId, targetType: $targetType, reason: $reason, description: $description, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ReportDetailCopyWith<$Res> implements $ReportDetailCopyWith<$Res> {
  factory _$ReportDetailCopyWith(_ReportDetail value, $Res Function(_ReportDetail) _then) = __$ReportDetailCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'target_id') String targetId,@JsonKey(name: 'target_type') SocialTargetType targetType, String reason, String? description,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class __$ReportDetailCopyWithImpl<$Res>
    implements _$ReportDetailCopyWith<$Res> {
  __$ReportDetailCopyWithImpl(this._self, this._then);

  final _ReportDetail _self;
  final $Res Function(_ReportDetail) _then;

/// Create a copy of ReportDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? targetId = null,Object? targetType = null,Object? reason = null,Object? description = freezed,Object? createdAt = null,}) {
  return _then(_ReportDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as SocialTargetType,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
