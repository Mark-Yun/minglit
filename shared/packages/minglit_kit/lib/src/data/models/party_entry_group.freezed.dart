// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'party_entry_group.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PartyEntryGroup {

 String get id; String? get label; String? get gender;// 'male', 'female', null(any)
@JsonKey(name: 'birth_year_range') Map<String, dynamic>? get birthYearRange;@JsonKey(name: 'required_verification_ids') List<String> get requiredVerificationIds;
/// Create a copy of PartyEntryGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PartyEntryGroupCopyWith<PartyEntryGroup> get copyWith => _$PartyEntryGroupCopyWithImpl<PartyEntryGroup>(this as PartyEntryGroup, _$identity);

  /// Serializes this PartyEntryGroup to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PartyEntryGroup&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.gender, gender) || other.gender == gender)&&const DeepCollectionEquality().equals(other.birthYearRange, birthYearRange)&&const DeepCollectionEquality().equals(other.requiredVerificationIds, requiredVerificationIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,gender,const DeepCollectionEquality().hash(birthYearRange),const DeepCollectionEquality().hash(requiredVerificationIds));

@override
String toString() {
  return 'PartyEntryGroup(id: $id, label: $label, gender: $gender, birthYearRange: $birthYearRange, requiredVerificationIds: $requiredVerificationIds)';
}


}

/// @nodoc
abstract mixin class $PartyEntryGroupCopyWith<$Res>  {
  factory $PartyEntryGroupCopyWith(PartyEntryGroup value, $Res Function(PartyEntryGroup) _then) = _$PartyEntryGroupCopyWithImpl;
@useResult
$Res call({
 String id, String? label, String? gender,@JsonKey(name: 'birth_year_range') Map<String, dynamic>? birthYearRange,@JsonKey(name: 'required_verification_ids') List<String> requiredVerificationIds
});




}
/// @nodoc
class _$PartyEntryGroupCopyWithImpl<$Res>
    implements $PartyEntryGroupCopyWith<$Res> {
  _$PartyEntryGroupCopyWithImpl(this._self, this._then);

  final PartyEntryGroup _self;
  final $Res Function(PartyEntryGroup) _then;

/// Create a copy of PartyEntryGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = freezed,Object? gender = freezed,Object? birthYearRange = freezed,Object? requiredVerificationIds = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,birthYearRange: freezed == birthYearRange ? _self.birthYearRange : birthYearRange // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,requiredVerificationIds: null == requiredVerificationIds ? _self.requiredVerificationIds : requiredVerificationIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [PartyEntryGroup].
extension PartyEntryGroupPatterns on PartyEntryGroup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PartyEntryGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PartyEntryGroup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PartyEntryGroup value)  $default,){
final _that = this;
switch (_that) {
case _PartyEntryGroup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PartyEntryGroup value)?  $default,){
final _that = this;
switch (_that) {
case _PartyEntryGroup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? label,  String? gender, @JsonKey(name: 'birth_year_range')  Map<String, dynamic>? birthYearRange, @JsonKey(name: 'required_verification_ids')  List<String> requiredVerificationIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PartyEntryGroup() when $default != null:
return $default(_that.id,_that.label,_that.gender,_that.birthYearRange,_that.requiredVerificationIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? label,  String? gender, @JsonKey(name: 'birth_year_range')  Map<String, dynamic>? birthYearRange, @JsonKey(name: 'required_verification_ids')  List<String> requiredVerificationIds)  $default,) {final _that = this;
switch (_that) {
case _PartyEntryGroup():
return $default(_that.id,_that.label,_that.gender,_that.birthYearRange,_that.requiredVerificationIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? label,  String? gender, @JsonKey(name: 'birth_year_range')  Map<String, dynamic>? birthYearRange, @JsonKey(name: 'required_verification_ids')  List<String> requiredVerificationIds)?  $default,) {final _that = this;
switch (_that) {
case _PartyEntryGroup() when $default != null:
return $default(_that.id,_that.label,_that.gender,_that.birthYearRange,_that.requiredVerificationIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PartyEntryGroup implements PartyEntryGroup {
  const _PartyEntryGroup({required this.id, this.label, this.gender, @JsonKey(name: 'birth_year_range') final  Map<String, dynamic>? birthYearRange, @JsonKey(name: 'required_verification_ids') final  List<String> requiredVerificationIds = const []}): _birthYearRange = birthYearRange,_requiredVerificationIds = requiredVerificationIds;
  factory _PartyEntryGroup.fromJson(Map<String, dynamic> json) => _$PartyEntryGroupFromJson(json);

@override final  String id;
@override final  String? label;
@override final  String? gender;
// 'male', 'female', null(any)
 final  Map<String, dynamic>? _birthYearRange;
// 'male', 'female', null(any)
@override@JsonKey(name: 'birth_year_range') Map<String, dynamic>? get birthYearRange {
  final value = _birthYearRange;
  if (value == null) return null;
  if (_birthYearRange is EqualUnmodifiableMapView) return _birthYearRange;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  List<String> _requiredVerificationIds;
@override@JsonKey(name: 'required_verification_ids') List<String> get requiredVerificationIds {
  if (_requiredVerificationIds is EqualUnmodifiableListView) return _requiredVerificationIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_requiredVerificationIds);
}


/// Create a copy of PartyEntryGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PartyEntryGroupCopyWith<_PartyEntryGroup> get copyWith => __$PartyEntryGroupCopyWithImpl<_PartyEntryGroup>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PartyEntryGroupToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PartyEntryGroup&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.gender, gender) || other.gender == gender)&&const DeepCollectionEquality().equals(other._birthYearRange, _birthYearRange)&&const DeepCollectionEquality().equals(other._requiredVerificationIds, _requiredVerificationIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,gender,const DeepCollectionEquality().hash(_birthYearRange),const DeepCollectionEquality().hash(_requiredVerificationIds));

@override
String toString() {
  return 'PartyEntryGroup(id: $id, label: $label, gender: $gender, birthYearRange: $birthYearRange, requiredVerificationIds: $requiredVerificationIds)';
}


}

/// @nodoc
abstract mixin class _$PartyEntryGroupCopyWith<$Res> implements $PartyEntryGroupCopyWith<$Res> {
  factory _$PartyEntryGroupCopyWith(_PartyEntryGroup value, $Res Function(_PartyEntryGroup) _then) = __$PartyEntryGroupCopyWithImpl;
@override @useResult
$Res call({
 String id, String? label, String? gender,@JsonKey(name: 'birth_year_range') Map<String, dynamic>? birthYearRange,@JsonKey(name: 'required_verification_ids') List<String> requiredVerificationIds
});




}
/// @nodoc
class __$PartyEntryGroupCopyWithImpl<$Res>
    implements _$PartyEntryGroupCopyWith<$Res> {
  __$PartyEntryGroupCopyWithImpl(this._self, this._then);

  final _PartyEntryGroup _self;
  final $Res Function(_PartyEntryGroup) _then;

/// Create a copy of PartyEntryGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = freezed,Object? gender = freezed,Object? birthYearRange = freezed,Object? requiredVerificationIds = null,}) {
  return _then(_PartyEntryGroup(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,birthYearRange: freezed == birthYearRange ? _self._birthYearRange : birthYearRange // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,requiredVerificationIds: null == requiredVerificationIds ? _self._requiredVerificationIds : requiredVerificationIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
