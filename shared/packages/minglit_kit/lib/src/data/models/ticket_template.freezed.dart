// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ticket_template.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TicketTemplate {

 String get id;@JsonKey(name: 'party_id') String get partyId; String get name;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt; String? get description; int get price; int get quantity;@JsonKey(name: 'target_entry_group_ids') List<String> get targetEntryGroupIds;@JsonKey(name: 'required_verification_ids') List<String> get requiredVerificationIds;
/// Create a copy of TicketTemplate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TicketTemplateCopyWith<TicketTemplate> get copyWith => _$TicketTemplateCopyWithImpl<TicketTemplate>(this as TicketTemplate, _$identity);

  /// Serializes this TicketTemplate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TicketTemplate&&(identical(other.id, id) || other.id == id)&&(identical(other.partyId, partyId) || other.partyId == partyId)&&(identical(other.name, name) || other.name == name)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.description, description) || other.description == description)&&(identical(other.price, price) || other.price == price)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&const DeepCollectionEquality().equals(other.targetEntryGroupIds, targetEntryGroupIds)&&const DeepCollectionEquality().equals(other.requiredVerificationIds, requiredVerificationIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,partyId,name,createdAt,updatedAt,description,price,quantity,const DeepCollectionEquality().hash(targetEntryGroupIds),const DeepCollectionEquality().hash(requiredVerificationIds));

@override
String toString() {
  return 'TicketTemplate(id: $id, partyId: $partyId, name: $name, createdAt: $createdAt, updatedAt: $updatedAt, description: $description, price: $price, quantity: $quantity, targetEntryGroupIds: $targetEntryGroupIds, requiredVerificationIds: $requiredVerificationIds)';
}


}

/// @nodoc
abstract mixin class $TicketTemplateCopyWith<$Res>  {
  factory $TicketTemplateCopyWith(TicketTemplate value, $Res Function(TicketTemplate) _then) = _$TicketTemplateCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'party_id') String partyId, String name,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt, String? description, int price, int quantity,@JsonKey(name: 'target_entry_group_ids') List<String> targetEntryGroupIds,@JsonKey(name: 'required_verification_ids') List<String> requiredVerificationIds
});




}
/// @nodoc
class _$TicketTemplateCopyWithImpl<$Res>
    implements $TicketTemplateCopyWith<$Res> {
  _$TicketTemplateCopyWithImpl(this._self, this._then);

  final TicketTemplate _self;
  final $Res Function(TicketTemplate) _then;

/// Create a copy of TicketTemplate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? partyId = null,Object? name = null,Object? createdAt = null,Object? updatedAt = null,Object? description = freezed,Object? price = null,Object? quantity = null,Object? targetEntryGroupIds = null,Object? requiredVerificationIds = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,partyId: null == partyId ? _self.partyId : partyId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,targetEntryGroupIds: null == targetEntryGroupIds ? _self.targetEntryGroupIds : targetEntryGroupIds // ignore: cast_nullable_to_non_nullable
as List<String>,requiredVerificationIds: null == requiredVerificationIds ? _self.requiredVerificationIds : requiredVerificationIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [TicketTemplate].
extension TicketTemplatePatterns on TicketTemplate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TicketTemplate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TicketTemplate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TicketTemplate value)  $default,){
final _that = this;
switch (_that) {
case _TicketTemplate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TicketTemplate value)?  $default,){
final _that = this;
switch (_that) {
case _TicketTemplate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'party_id')  String partyId,  String name, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt,  String? description,  int price,  int quantity, @JsonKey(name: 'target_entry_group_ids')  List<String> targetEntryGroupIds, @JsonKey(name: 'required_verification_ids')  List<String> requiredVerificationIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TicketTemplate() when $default != null:
return $default(_that.id,_that.partyId,_that.name,_that.createdAt,_that.updatedAt,_that.description,_that.price,_that.quantity,_that.targetEntryGroupIds,_that.requiredVerificationIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'party_id')  String partyId,  String name, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt,  String? description,  int price,  int quantity, @JsonKey(name: 'target_entry_group_ids')  List<String> targetEntryGroupIds, @JsonKey(name: 'required_verification_ids')  List<String> requiredVerificationIds)  $default,) {final _that = this;
switch (_that) {
case _TicketTemplate():
return $default(_that.id,_that.partyId,_that.name,_that.createdAt,_that.updatedAt,_that.description,_that.price,_that.quantity,_that.targetEntryGroupIds,_that.requiredVerificationIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'party_id')  String partyId,  String name, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt,  String? description,  int price,  int quantity, @JsonKey(name: 'target_entry_group_ids')  List<String> targetEntryGroupIds, @JsonKey(name: 'required_verification_ids')  List<String> requiredVerificationIds)?  $default,) {final _that = this;
switch (_that) {
case _TicketTemplate() when $default != null:
return $default(_that.id,_that.partyId,_that.name,_that.createdAt,_that.updatedAt,_that.description,_that.price,_that.quantity,_that.targetEntryGroupIds,_that.requiredVerificationIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TicketTemplate implements TicketTemplate {
  const _TicketTemplate({required this.id, @JsonKey(name: 'party_id') required this.partyId, required this.name, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt, this.description, this.price = 0, this.quantity = 0, @JsonKey(name: 'target_entry_group_ids') final  List<String> targetEntryGroupIds = const [], @JsonKey(name: 'required_verification_ids') final  List<String> requiredVerificationIds = const []}): _targetEntryGroupIds = targetEntryGroupIds,_requiredVerificationIds = requiredVerificationIds;
  factory _TicketTemplate.fromJson(Map<String, dynamic> json) => _$TicketTemplateFromJson(json);

@override final  String id;
@override@JsonKey(name: 'party_id') final  String partyId;
@override final  String name;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;
@override final  String? description;
@override@JsonKey() final  int price;
@override@JsonKey() final  int quantity;
 final  List<String> _targetEntryGroupIds;
@override@JsonKey(name: 'target_entry_group_ids') List<String> get targetEntryGroupIds {
  if (_targetEntryGroupIds is EqualUnmodifiableListView) return _targetEntryGroupIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_targetEntryGroupIds);
}

 final  List<String> _requiredVerificationIds;
@override@JsonKey(name: 'required_verification_ids') List<String> get requiredVerificationIds {
  if (_requiredVerificationIds is EqualUnmodifiableListView) return _requiredVerificationIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_requiredVerificationIds);
}


/// Create a copy of TicketTemplate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TicketTemplateCopyWith<_TicketTemplate> get copyWith => __$TicketTemplateCopyWithImpl<_TicketTemplate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TicketTemplateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TicketTemplate&&(identical(other.id, id) || other.id == id)&&(identical(other.partyId, partyId) || other.partyId == partyId)&&(identical(other.name, name) || other.name == name)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.description, description) || other.description == description)&&(identical(other.price, price) || other.price == price)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&const DeepCollectionEquality().equals(other._targetEntryGroupIds, _targetEntryGroupIds)&&const DeepCollectionEquality().equals(other._requiredVerificationIds, _requiredVerificationIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,partyId,name,createdAt,updatedAt,description,price,quantity,const DeepCollectionEquality().hash(_targetEntryGroupIds),const DeepCollectionEquality().hash(_requiredVerificationIds));

@override
String toString() {
  return 'TicketTemplate(id: $id, partyId: $partyId, name: $name, createdAt: $createdAt, updatedAt: $updatedAt, description: $description, price: $price, quantity: $quantity, targetEntryGroupIds: $targetEntryGroupIds, requiredVerificationIds: $requiredVerificationIds)';
}


}

/// @nodoc
abstract mixin class _$TicketTemplateCopyWith<$Res> implements $TicketTemplateCopyWith<$Res> {
  factory _$TicketTemplateCopyWith(_TicketTemplate value, $Res Function(_TicketTemplate) _then) = __$TicketTemplateCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'party_id') String partyId, String name,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt, String? description, int price, int quantity,@JsonKey(name: 'target_entry_group_ids') List<String> targetEntryGroupIds,@JsonKey(name: 'required_verification_ids') List<String> requiredVerificationIds
});




}
/// @nodoc
class __$TicketTemplateCopyWithImpl<$Res>
    implements _$TicketTemplateCopyWith<$Res> {
  __$TicketTemplateCopyWithImpl(this._self, this._then);

  final _TicketTemplate _self;
  final $Res Function(_TicketTemplate) _then;

/// Create a copy of TicketTemplate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? partyId = null,Object? name = null,Object? createdAt = null,Object? updatedAt = null,Object? description = freezed,Object? price = null,Object? quantity = null,Object? targetEntryGroupIds = null,Object? requiredVerificationIds = null,}) {
  return _then(_TicketTemplate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,partyId: null == partyId ? _self.partyId : partyId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,targetEntryGroupIds: null == targetEntryGroupIds ? _self._targetEntryGroupIds : targetEntryGroupIds // ignore: cast_nullable_to_non_nullable
as List<String>,requiredVerificationIds: null == requiredVerificationIds ? _self._requiredVerificationIds : requiredVerificationIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
