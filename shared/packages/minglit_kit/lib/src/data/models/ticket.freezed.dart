// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ticket.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Ticket {

 String get id; String get name;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt;@JsonKey(name: 'event_id') String? get eventId;// Nullable for templates
@JsonKey(name: 'party_id') String? get partyId;// Nullable for event instances
 String? get description; int get price; int get quantity;@JsonKey(name: 'sold_count') int get soldCount; Map<String, dynamic> get conditions;// JSONB (gender, age, etc.)
@JsonKey(name: 'required_verification_ids') List<String> get requiredVerificationIds; String get status;
/// Create a copy of Ticket
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TicketCopyWith<Ticket> get copyWith => _$TicketCopyWithImpl<Ticket>(this as Ticket, _$identity);

  /// Serializes this Ticket to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Ticket&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.partyId, partyId) || other.partyId == partyId)&&(identical(other.description, description) || other.description == description)&&(identical(other.price, price) || other.price == price)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.soldCount, soldCount) || other.soldCount == soldCount)&&const DeepCollectionEquality().equals(other.conditions, conditions)&&const DeepCollectionEquality().equals(other.requiredVerificationIds, requiredVerificationIds)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,createdAt,updatedAt,eventId,partyId,description,price,quantity,soldCount,const DeepCollectionEquality().hash(conditions),const DeepCollectionEquality().hash(requiredVerificationIds),status);

@override
String toString() {
  return 'Ticket(id: $id, name: $name, createdAt: $createdAt, updatedAt: $updatedAt, eventId: $eventId, partyId: $partyId, description: $description, price: $price, quantity: $quantity, soldCount: $soldCount, conditions: $conditions, requiredVerificationIds: $requiredVerificationIds, status: $status)';
}


}

/// @nodoc
abstract mixin class $TicketCopyWith<$Res>  {
  factory $TicketCopyWith(Ticket value, $Res Function(Ticket) _then) = _$TicketCopyWithImpl;
@useResult
$Res call({
 String id, String name,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'event_id') String? eventId,@JsonKey(name: 'party_id') String? partyId, String? description, int price, int quantity,@JsonKey(name: 'sold_count') int soldCount, Map<String, dynamic> conditions,@JsonKey(name: 'required_verification_ids') List<String> requiredVerificationIds, String status
});




}
/// @nodoc
class _$TicketCopyWithImpl<$Res>
    implements $TicketCopyWith<$Res> {
  _$TicketCopyWithImpl(this._self, this._then);

  final Ticket _self;
  final $Res Function(Ticket) _then;

/// Create a copy of Ticket
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? createdAt = null,Object? updatedAt = null,Object? eventId = freezed,Object? partyId = freezed,Object? description = freezed,Object? price = null,Object? quantity = null,Object? soldCount = null,Object? conditions = null,Object? requiredVerificationIds = null,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,eventId: freezed == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String?,partyId: freezed == partyId ? _self.partyId : partyId // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,soldCount: null == soldCount ? _self.soldCount : soldCount // ignore: cast_nullable_to_non_nullable
as int,conditions: null == conditions ? _self.conditions : conditions // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,requiredVerificationIds: null == requiredVerificationIds ? _self.requiredVerificationIds : requiredVerificationIds // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Ticket].
extension TicketPatterns on Ticket {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Ticket value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Ticket() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Ticket value)  $default,){
final _that = this;
switch (_that) {
case _Ticket():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Ticket value)?  $default,){
final _that = this;
switch (_that) {
case _Ticket() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'event_id')  String? eventId, @JsonKey(name: 'party_id')  String? partyId,  String? description,  int price,  int quantity, @JsonKey(name: 'sold_count')  int soldCount,  Map<String, dynamic> conditions, @JsonKey(name: 'required_verification_ids')  List<String> requiredVerificationIds,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Ticket() when $default != null:
return $default(_that.id,_that.name,_that.createdAt,_that.updatedAt,_that.eventId,_that.partyId,_that.description,_that.price,_that.quantity,_that.soldCount,_that.conditions,_that.requiredVerificationIds,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'event_id')  String? eventId, @JsonKey(name: 'party_id')  String? partyId,  String? description,  int price,  int quantity, @JsonKey(name: 'sold_count')  int soldCount,  Map<String, dynamic> conditions, @JsonKey(name: 'required_verification_ids')  List<String> requiredVerificationIds,  String status)  $default,) {final _that = this;
switch (_that) {
case _Ticket():
return $default(_that.id,_that.name,_that.createdAt,_that.updatedAt,_that.eventId,_that.partyId,_that.description,_that.price,_that.quantity,_that.soldCount,_that.conditions,_that.requiredVerificationIds,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'event_id')  String? eventId, @JsonKey(name: 'party_id')  String? partyId,  String? description,  int price,  int quantity, @JsonKey(name: 'sold_count')  int soldCount,  Map<String, dynamic> conditions, @JsonKey(name: 'required_verification_ids')  List<String> requiredVerificationIds,  String status)?  $default,) {final _that = this;
switch (_that) {
case _Ticket() when $default != null:
return $default(_that.id,_that.name,_that.createdAt,_that.updatedAt,_that.eventId,_that.partyId,_that.description,_that.price,_that.quantity,_that.soldCount,_that.conditions,_that.requiredVerificationIds,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Ticket implements Ticket {
  const _Ticket({required this.id, required this.name, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt, @JsonKey(name: 'event_id') this.eventId, @JsonKey(name: 'party_id') this.partyId, this.description, this.price = 0, this.quantity = 0, @JsonKey(name: 'sold_count') this.soldCount = 0, final  Map<String, dynamic> conditions = const {}, @JsonKey(name: 'required_verification_ids') final  List<String> requiredVerificationIds = const [], this.status = 'on_sale'}): _conditions = conditions,_requiredVerificationIds = requiredVerificationIds;
  factory _Ticket.fromJson(Map<String, dynamic> json) => _$TicketFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;
@override@JsonKey(name: 'event_id') final  String? eventId;
// Nullable for templates
@override@JsonKey(name: 'party_id') final  String? partyId;
// Nullable for event instances
@override final  String? description;
@override@JsonKey() final  int price;
@override@JsonKey() final  int quantity;
@override@JsonKey(name: 'sold_count') final  int soldCount;
 final  Map<String, dynamic> _conditions;
@override@JsonKey() Map<String, dynamic> get conditions {
  if (_conditions is EqualUnmodifiableMapView) return _conditions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_conditions);
}

// JSONB (gender, age, etc.)
 final  List<String> _requiredVerificationIds;
// JSONB (gender, age, etc.)
@override@JsonKey(name: 'required_verification_ids') List<String> get requiredVerificationIds {
  if (_requiredVerificationIds is EqualUnmodifiableListView) return _requiredVerificationIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_requiredVerificationIds);
}

@override@JsonKey() final  String status;

/// Create a copy of Ticket
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TicketCopyWith<_Ticket> get copyWith => __$TicketCopyWithImpl<_Ticket>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TicketToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Ticket&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.partyId, partyId) || other.partyId == partyId)&&(identical(other.description, description) || other.description == description)&&(identical(other.price, price) || other.price == price)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.soldCount, soldCount) || other.soldCount == soldCount)&&const DeepCollectionEquality().equals(other._conditions, _conditions)&&const DeepCollectionEquality().equals(other._requiredVerificationIds, _requiredVerificationIds)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,createdAt,updatedAt,eventId,partyId,description,price,quantity,soldCount,const DeepCollectionEquality().hash(_conditions),const DeepCollectionEquality().hash(_requiredVerificationIds),status);

@override
String toString() {
  return 'Ticket(id: $id, name: $name, createdAt: $createdAt, updatedAt: $updatedAt, eventId: $eventId, partyId: $partyId, description: $description, price: $price, quantity: $quantity, soldCount: $soldCount, conditions: $conditions, requiredVerificationIds: $requiredVerificationIds, status: $status)';
}


}

/// @nodoc
abstract mixin class _$TicketCopyWith<$Res> implements $TicketCopyWith<$Res> {
  factory _$TicketCopyWith(_Ticket value, $Res Function(_Ticket) _then) = __$TicketCopyWithImpl;
@override @useResult
$Res call({
 String id, String name,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'event_id') String? eventId,@JsonKey(name: 'party_id') String? partyId, String? description, int price, int quantity,@JsonKey(name: 'sold_count') int soldCount, Map<String, dynamic> conditions,@JsonKey(name: 'required_verification_ids') List<String> requiredVerificationIds, String status
});




}
/// @nodoc
class __$TicketCopyWithImpl<$Res>
    implements _$TicketCopyWith<$Res> {
  __$TicketCopyWithImpl(this._self, this._then);

  final _Ticket _self;
  final $Res Function(_Ticket) _then;

/// Create a copy of Ticket
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? createdAt = null,Object? updatedAt = null,Object? eventId = freezed,Object? partyId = freezed,Object? description = freezed,Object? price = null,Object? quantity = null,Object? soldCount = null,Object? conditions = null,Object? requiredVerificationIds = null,Object? status = null,}) {
  return _then(_Ticket(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,eventId: freezed == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String?,partyId: freezed == partyId ? _self.partyId : partyId // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,soldCount: null == soldCount ? _self.soldCount : soldCount // ignore: cast_nullable_to_non_nullable
as int,conditions: null == conditions ? _self._conditions : conditions // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,requiredVerificationIds: null == requiredVerificationIds ? _self._requiredVerificationIds : requiredVerificationIds // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
