// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Event {

 String get id;@JsonKey(name: 'party_id') String get partyId;@JsonKey(name: 'start_time') DateTime get startTime;@JsonKey(name: 'end_time') DateTime get endTime;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt;@JsonKey(name: 'location_id') String? get locationId; String? get title;// Override
 Map<String, dynamic>? get description;// Override
@JsonKey(name: 'contact_phone') String? get contactPhone;// Override
@JsonKey(name: 'contact_email') String? get contactEmail;// Override
@JsonKey(name: 'max_participants') int get maxParticipants;@JsonKey(name: 'current_participants') int get currentParticipants; String get status;// Relationships (Optional, loaded via join)
 Party? get party; Location? get location;
/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventCopyWith<Event> get copyWith => _$EventCopyWithImpl<Event>(this as Event, _$identity);

  /// Serializes this Event to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Event&&(identical(other.id, id) || other.id == id)&&(identical(other.partyId, partyId) || other.partyId == partyId)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.locationId, locationId) || other.locationId == locationId)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.description, description)&&(identical(other.contactPhone, contactPhone) || other.contactPhone == contactPhone)&&(identical(other.contactEmail, contactEmail) || other.contactEmail == contactEmail)&&(identical(other.maxParticipants, maxParticipants) || other.maxParticipants == maxParticipants)&&(identical(other.currentParticipants, currentParticipants) || other.currentParticipants == currentParticipants)&&(identical(other.status, status) || other.status == status)&&(identical(other.party, party) || other.party == party)&&(identical(other.location, location) || other.location == location));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,partyId,startTime,endTime,createdAt,updatedAt,locationId,title,const DeepCollectionEquality().hash(description),contactPhone,contactEmail,maxParticipants,currentParticipants,status,party,location);

@override
String toString() {
  return 'Event(id: $id, partyId: $partyId, startTime: $startTime, endTime: $endTime, createdAt: $createdAt, updatedAt: $updatedAt, locationId: $locationId, title: $title, description: $description, contactPhone: $contactPhone, contactEmail: $contactEmail, maxParticipants: $maxParticipants, currentParticipants: $currentParticipants, status: $status, party: $party, location: $location)';
}


}

/// @nodoc
abstract mixin class $EventCopyWith<$Res>  {
  factory $EventCopyWith(Event value, $Res Function(Event) _then) = _$EventCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'party_id') String partyId,@JsonKey(name: 'start_time') DateTime startTime,@JsonKey(name: 'end_time') DateTime endTime,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'location_id') String? locationId, String? title, Map<String, dynamic>? description,@JsonKey(name: 'contact_phone') String? contactPhone,@JsonKey(name: 'contact_email') String? contactEmail,@JsonKey(name: 'max_participants') int maxParticipants,@JsonKey(name: 'current_participants') int currentParticipants, String status, Party? party, Location? location
});


$PartyCopyWith<$Res>? get party;$LocationCopyWith<$Res>? get location;

}
/// @nodoc
class _$EventCopyWithImpl<$Res>
    implements $EventCopyWith<$Res> {
  _$EventCopyWithImpl(this._self, this._then);

  final Event _self;
  final $Res Function(Event) _then;

/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? partyId = null,Object? startTime = null,Object? endTime = null,Object? createdAt = null,Object? updatedAt = null,Object? locationId = freezed,Object? title = freezed,Object? description = freezed,Object? contactPhone = freezed,Object? contactEmail = freezed,Object? maxParticipants = null,Object? currentParticipants = null,Object? status = null,Object? party = freezed,Object? location = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,partyId: null == partyId ? _self.partyId : partyId // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,locationId: freezed == locationId ? _self.locationId : locationId // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,contactPhone: freezed == contactPhone ? _self.contactPhone : contactPhone // ignore: cast_nullable_to_non_nullable
as String?,contactEmail: freezed == contactEmail ? _self.contactEmail : contactEmail // ignore: cast_nullable_to_non_nullable
as String?,maxParticipants: null == maxParticipants ? _self.maxParticipants : maxParticipants // ignore: cast_nullable_to_non_nullable
as int,currentParticipants: null == currentParticipants ? _self.currentParticipants : currentParticipants // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,party: freezed == party ? _self.party : party // ignore: cast_nullable_to_non_nullable
as Party?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as Location?,
  ));
}
/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PartyCopyWith<$Res>? get party {
    if (_self.party == null) {
    return null;
  }

  return $PartyCopyWith<$Res>(_self.party!, (value) {
    return _then(_self.copyWith(party: value));
  });
}/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocationCopyWith<$Res>? get location {
    if (_self.location == null) {
    return null;
  }

  return $LocationCopyWith<$Res>(_self.location!, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// Adds pattern-matching-related methods to [Event].
extension EventPatterns on Event {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Event value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Event() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Event value)  $default,){
final _that = this;
switch (_that) {
case _Event():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Event value)?  $default,){
final _that = this;
switch (_that) {
case _Event() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'party_id')  String partyId, @JsonKey(name: 'start_time')  DateTime startTime, @JsonKey(name: 'end_time')  DateTime endTime, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'location_id')  String? locationId,  String? title,  Map<String, dynamic>? description, @JsonKey(name: 'contact_phone')  String? contactPhone, @JsonKey(name: 'contact_email')  String? contactEmail, @JsonKey(name: 'max_participants')  int maxParticipants, @JsonKey(name: 'current_participants')  int currentParticipants,  String status,  Party? party,  Location? location)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Event() when $default != null:
return $default(_that.id,_that.partyId,_that.startTime,_that.endTime,_that.createdAt,_that.updatedAt,_that.locationId,_that.title,_that.description,_that.contactPhone,_that.contactEmail,_that.maxParticipants,_that.currentParticipants,_that.status,_that.party,_that.location);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'party_id')  String partyId, @JsonKey(name: 'start_time')  DateTime startTime, @JsonKey(name: 'end_time')  DateTime endTime, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'location_id')  String? locationId,  String? title,  Map<String, dynamic>? description, @JsonKey(name: 'contact_phone')  String? contactPhone, @JsonKey(name: 'contact_email')  String? contactEmail, @JsonKey(name: 'max_participants')  int maxParticipants, @JsonKey(name: 'current_participants')  int currentParticipants,  String status,  Party? party,  Location? location)  $default,) {final _that = this;
switch (_that) {
case _Event():
return $default(_that.id,_that.partyId,_that.startTime,_that.endTime,_that.createdAt,_that.updatedAt,_that.locationId,_that.title,_that.description,_that.contactPhone,_that.contactEmail,_that.maxParticipants,_that.currentParticipants,_that.status,_that.party,_that.location);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'party_id')  String partyId, @JsonKey(name: 'start_time')  DateTime startTime, @JsonKey(name: 'end_time')  DateTime endTime, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'location_id')  String? locationId,  String? title,  Map<String, dynamic>? description, @JsonKey(name: 'contact_phone')  String? contactPhone, @JsonKey(name: 'contact_email')  String? contactEmail, @JsonKey(name: 'max_participants')  int maxParticipants, @JsonKey(name: 'current_participants')  int currentParticipants,  String status,  Party? party,  Location? location)?  $default,) {final _that = this;
switch (_that) {
case _Event() when $default != null:
return $default(_that.id,_that.partyId,_that.startTime,_that.endTime,_that.createdAt,_that.updatedAt,_that.locationId,_that.title,_that.description,_that.contactPhone,_that.contactEmail,_that.maxParticipants,_that.currentParticipants,_that.status,_that.party,_that.location);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Event implements Event {
  const _Event({required this.id, @JsonKey(name: 'party_id') required this.partyId, @JsonKey(name: 'start_time') required this.startTime, @JsonKey(name: 'end_time') required this.endTime, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt, @JsonKey(name: 'location_id') this.locationId, this.title, final  Map<String, dynamic>? description, @JsonKey(name: 'contact_phone') this.contactPhone, @JsonKey(name: 'contact_email') this.contactEmail, @JsonKey(name: 'max_participants') this.maxParticipants = 20, @JsonKey(name: 'current_participants') this.currentParticipants = 0, this.status = 'scheduled', this.party, this.location}): _description = description;
  factory _Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);

@override final  String id;
@override@JsonKey(name: 'party_id') final  String partyId;
@override@JsonKey(name: 'start_time') final  DateTime startTime;
@override@JsonKey(name: 'end_time') final  DateTime endTime;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;
@override@JsonKey(name: 'location_id') final  String? locationId;
@override final  String? title;
// Override
 final  Map<String, dynamic>? _description;
// Override
@override Map<String, dynamic>? get description {
  final value = _description;
  if (value == null) return null;
  if (_description is EqualUnmodifiableMapView) return _description;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

// Override
@override@JsonKey(name: 'contact_phone') final  String? contactPhone;
// Override
@override@JsonKey(name: 'contact_email') final  String? contactEmail;
// Override
@override@JsonKey(name: 'max_participants') final  int maxParticipants;
@override@JsonKey(name: 'current_participants') final  int currentParticipants;
@override@JsonKey() final  String status;
// Relationships (Optional, loaded via join)
@override final  Party? party;
@override final  Location? location;

/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventCopyWith<_Event> get copyWith => __$EventCopyWithImpl<_Event>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Event&&(identical(other.id, id) || other.id == id)&&(identical(other.partyId, partyId) || other.partyId == partyId)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.locationId, locationId) || other.locationId == locationId)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._description, _description)&&(identical(other.contactPhone, contactPhone) || other.contactPhone == contactPhone)&&(identical(other.contactEmail, contactEmail) || other.contactEmail == contactEmail)&&(identical(other.maxParticipants, maxParticipants) || other.maxParticipants == maxParticipants)&&(identical(other.currentParticipants, currentParticipants) || other.currentParticipants == currentParticipants)&&(identical(other.status, status) || other.status == status)&&(identical(other.party, party) || other.party == party)&&(identical(other.location, location) || other.location == location));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,partyId,startTime,endTime,createdAt,updatedAt,locationId,title,const DeepCollectionEquality().hash(_description),contactPhone,contactEmail,maxParticipants,currentParticipants,status,party,location);

@override
String toString() {
  return 'Event(id: $id, partyId: $partyId, startTime: $startTime, endTime: $endTime, createdAt: $createdAt, updatedAt: $updatedAt, locationId: $locationId, title: $title, description: $description, contactPhone: $contactPhone, contactEmail: $contactEmail, maxParticipants: $maxParticipants, currentParticipants: $currentParticipants, status: $status, party: $party, location: $location)';
}


}

/// @nodoc
abstract mixin class _$EventCopyWith<$Res> implements $EventCopyWith<$Res> {
  factory _$EventCopyWith(_Event value, $Res Function(_Event) _then) = __$EventCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'party_id') String partyId,@JsonKey(name: 'start_time') DateTime startTime,@JsonKey(name: 'end_time') DateTime endTime,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'location_id') String? locationId, String? title, Map<String, dynamic>? description,@JsonKey(name: 'contact_phone') String? contactPhone,@JsonKey(name: 'contact_email') String? contactEmail,@JsonKey(name: 'max_participants') int maxParticipants,@JsonKey(name: 'current_participants') int currentParticipants, String status, Party? party, Location? location
});


@override $PartyCopyWith<$Res>? get party;@override $LocationCopyWith<$Res>? get location;

}
/// @nodoc
class __$EventCopyWithImpl<$Res>
    implements _$EventCopyWith<$Res> {
  __$EventCopyWithImpl(this._self, this._then);

  final _Event _self;
  final $Res Function(_Event) _then;

/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? partyId = null,Object? startTime = null,Object? endTime = null,Object? createdAt = null,Object? updatedAt = null,Object? locationId = freezed,Object? title = freezed,Object? description = freezed,Object? contactPhone = freezed,Object? contactEmail = freezed,Object? maxParticipants = null,Object? currentParticipants = null,Object? status = null,Object? party = freezed,Object? location = freezed,}) {
  return _then(_Event(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,partyId: null == partyId ? _self.partyId : partyId // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,locationId: freezed == locationId ? _self.locationId : locationId // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self._description : description // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,contactPhone: freezed == contactPhone ? _self.contactPhone : contactPhone // ignore: cast_nullable_to_non_nullable
as String?,contactEmail: freezed == contactEmail ? _self.contactEmail : contactEmail // ignore: cast_nullable_to_non_nullable
as String?,maxParticipants: null == maxParticipants ? _self.maxParticipants : maxParticipants // ignore: cast_nullable_to_non_nullable
as int,currentParticipants: null == currentParticipants ? _self.currentParticipants : currentParticipants // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,party: freezed == party ? _self.party : party // ignore: cast_nullable_to_non_nullable
as Party?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as Location?,
  ));
}

/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PartyCopyWith<$Res>? get party {
    if (_self.party == null) {
    return null;
  }

  return $PartyCopyWith<$Res>(_self.party!, (value) {
    return _then(_self.copyWith(party: value));
  });
}/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocationCopyWith<$Res>? get location {
    if (_self.location == null) {
    return null;
  }

  return $LocationCopyWith<$Res>(_self.location!, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// @nodoc
mixin _$EventTicket {

 String get id;@JsonKey(name: 'event_id') String get eventId; String get name; int get quantity;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt; String? get description; int get price;@JsonKey(name: 'sold_count') int get soldCount; String? get gender;// 'male', 'female', null
@JsonKey(name: 'min_birth_year') int? get minBirthYear;@JsonKey(name: 'max_birth_year') int? get maxBirthYear;@JsonKey(name: 'required_verification_ids') List<String> get requiredVerificationIds; String get status;
/// Create a copy of EventTicket
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventTicketCopyWith<EventTicket> get copyWith => _$EventTicketCopyWithImpl<EventTicket>(this as EventTicket, _$identity);

  /// Serializes this EventTicket to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventTicket&&(identical(other.id, id) || other.id == id)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.name, name) || other.name == name)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.description, description) || other.description == description)&&(identical(other.price, price) || other.price == price)&&(identical(other.soldCount, soldCount) || other.soldCount == soldCount)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.minBirthYear, minBirthYear) || other.minBirthYear == minBirthYear)&&(identical(other.maxBirthYear, maxBirthYear) || other.maxBirthYear == maxBirthYear)&&const DeepCollectionEquality().equals(other.requiredVerificationIds, requiredVerificationIds)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,eventId,name,quantity,createdAt,updatedAt,description,price,soldCount,gender,minBirthYear,maxBirthYear,const DeepCollectionEquality().hash(requiredVerificationIds),status);

@override
String toString() {
  return 'EventTicket(id: $id, eventId: $eventId, name: $name, quantity: $quantity, createdAt: $createdAt, updatedAt: $updatedAt, description: $description, price: $price, soldCount: $soldCount, gender: $gender, minBirthYear: $minBirthYear, maxBirthYear: $maxBirthYear, requiredVerificationIds: $requiredVerificationIds, status: $status)';
}


}

/// @nodoc
abstract mixin class $EventTicketCopyWith<$Res>  {
  factory $EventTicketCopyWith(EventTicket value, $Res Function(EventTicket) _then) = _$EventTicketCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'event_id') String eventId, String name, int quantity,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt, String? description, int price,@JsonKey(name: 'sold_count') int soldCount, String? gender,@JsonKey(name: 'min_birth_year') int? minBirthYear,@JsonKey(name: 'max_birth_year') int? maxBirthYear,@JsonKey(name: 'required_verification_ids') List<String> requiredVerificationIds, String status
});




}
/// @nodoc
class _$EventTicketCopyWithImpl<$Res>
    implements $EventTicketCopyWith<$Res> {
  _$EventTicketCopyWithImpl(this._self, this._then);

  final EventTicket _self;
  final $Res Function(EventTicket) _then;

/// Create a copy of EventTicket
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? eventId = null,Object? name = null,Object? quantity = null,Object? createdAt = null,Object? updatedAt = null,Object? description = freezed,Object? price = null,Object? soldCount = null,Object? gender = freezed,Object? minBirthYear = freezed,Object? maxBirthYear = freezed,Object? requiredVerificationIds = null,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int,soldCount: null == soldCount ? _self.soldCount : soldCount // ignore: cast_nullable_to_non_nullable
as int,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,minBirthYear: freezed == minBirthYear ? _self.minBirthYear : minBirthYear // ignore: cast_nullable_to_non_nullable
as int?,maxBirthYear: freezed == maxBirthYear ? _self.maxBirthYear : maxBirthYear // ignore: cast_nullable_to_non_nullable
as int?,requiredVerificationIds: null == requiredVerificationIds ? _self.requiredVerificationIds : requiredVerificationIds // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [EventTicket].
extension EventTicketPatterns on EventTicket {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventTicket value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventTicket() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventTicket value)  $default,){
final _that = this;
switch (_that) {
case _EventTicket():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventTicket value)?  $default,){
final _that = this;
switch (_that) {
case _EventTicket() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'event_id')  String eventId,  String name,  int quantity, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt,  String? description,  int price, @JsonKey(name: 'sold_count')  int soldCount,  String? gender, @JsonKey(name: 'min_birth_year')  int? minBirthYear, @JsonKey(name: 'max_birth_year')  int? maxBirthYear, @JsonKey(name: 'required_verification_ids')  List<String> requiredVerificationIds,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventTicket() when $default != null:
return $default(_that.id,_that.eventId,_that.name,_that.quantity,_that.createdAt,_that.updatedAt,_that.description,_that.price,_that.soldCount,_that.gender,_that.minBirthYear,_that.maxBirthYear,_that.requiredVerificationIds,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'event_id')  String eventId,  String name,  int quantity, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt,  String? description,  int price, @JsonKey(name: 'sold_count')  int soldCount,  String? gender, @JsonKey(name: 'min_birth_year')  int? minBirthYear, @JsonKey(name: 'max_birth_year')  int? maxBirthYear, @JsonKey(name: 'required_verification_ids')  List<String> requiredVerificationIds,  String status)  $default,) {final _that = this;
switch (_that) {
case _EventTicket():
return $default(_that.id,_that.eventId,_that.name,_that.quantity,_that.createdAt,_that.updatedAt,_that.description,_that.price,_that.soldCount,_that.gender,_that.minBirthYear,_that.maxBirthYear,_that.requiredVerificationIds,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'event_id')  String eventId,  String name,  int quantity, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt,  String? description,  int price, @JsonKey(name: 'sold_count')  int soldCount,  String? gender, @JsonKey(name: 'min_birth_year')  int? minBirthYear, @JsonKey(name: 'max_birth_year')  int? maxBirthYear, @JsonKey(name: 'required_verification_ids')  List<String> requiredVerificationIds,  String status)?  $default,) {final _that = this;
switch (_that) {
case _EventTicket() when $default != null:
return $default(_that.id,_that.eventId,_that.name,_that.quantity,_that.createdAt,_that.updatedAt,_that.description,_that.price,_that.soldCount,_that.gender,_that.minBirthYear,_that.maxBirthYear,_that.requiredVerificationIds,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EventTicket implements EventTicket {
  const _EventTicket({required this.id, @JsonKey(name: 'event_id') required this.eventId, required this.name, required this.quantity, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt, this.description, this.price = 0, @JsonKey(name: 'sold_count') this.soldCount = 0, this.gender, @JsonKey(name: 'min_birth_year') this.minBirthYear, @JsonKey(name: 'max_birth_year') this.maxBirthYear, @JsonKey(name: 'required_verification_ids') final  List<String> requiredVerificationIds = const [], this.status = 'on_sale'}): _requiredVerificationIds = requiredVerificationIds;
  factory _EventTicket.fromJson(Map<String, dynamic> json) => _$EventTicketFromJson(json);

@override final  String id;
@override@JsonKey(name: 'event_id') final  String eventId;
@override final  String name;
@override final  int quantity;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;
@override final  String? description;
@override@JsonKey() final  int price;
@override@JsonKey(name: 'sold_count') final  int soldCount;
@override final  String? gender;
// 'male', 'female', null
@override@JsonKey(name: 'min_birth_year') final  int? minBirthYear;
@override@JsonKey(name: 'max_birth_year') final  int? maxBirthYear;
 final  List<String> _requiredVerificationIds;
@override@JsonKey(name: 'required_verification_ids') List<String> get requiredVerificationIds {
  if (_requiredVerificationIds is EqualUnmodifiableListView) return _requiredVerificationIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_requiredVerificationIds);
}

@override@JsonKey() final  String status;

/// Create a copy of EventTicket
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventTicketCopyWith<_EventTicket> get copyWith => __$EventTicketCopyWithImpl<_EventTicket>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EventTicketToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventTicket&&(identical(other.id, id) || other.id == id)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.name, name) || other.name == name)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.description, description) || other.description == description)&&(identical(other.price, price) || other.price == price)&&(identical(other.soldCount, soldCount) || other.soldCount == soldCount)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.minBirthYear, minBirthYear) || other.minBirthYear == minBirthYear)&&(identical(other.maxBirthYear, maxBirthYear) || other.maxBirthYear == maxBirthYear)&&const DeepCollectionEquality().equals(other._requiredVerificationIds, _requiredVerificationIds)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,eventId,name,quantity,createdAt,updatedAt,description,price,soldCount,gender,minBirthYear,maxBirthYear,const DeepCollectionEquality().hash(_requiredVerificationIds),status);

@override
String toString() {
  return 'EventTicket(id: $id, eventId: $eventId, name: $name, quantity: $quantity, createdAt: $createdAt, updatedAt: $updatedAt, description: $description, price: $price, soldCount: $soldCount, gender: $gender, minBirthYear: $minBirthYear, maxBirthYear: $maxBirthYear, requiredVerificationIds: $requiredVerificationIds, status: $status)';
}


}

/// @nodoc
abstract mixin class _$EventTicketCopyWith<$Res> implements $EventTicketCopyWith<$Res> {
  factory _$EventTicketCopyWith(_EventTicket value, $Res Function(_EventTicket) _then) = __$EventTicketCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'event_id') String eventId, String name, int quantity,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt, String? description, int price,@JsonKey(name: 'sold_count') int soldCount, String? gender,@JsonKey(name: 'min_birth_year') int? minBirthYear,@JsonKey(name: 'max_birth_year') int? maxBirthYear,@JsonKey(name: 'required_verification_ids') List<String> requiredVerificationIds, String status
});




}
/// @nodoc
class __$EventTicketCopyWithImpl<$Res>
    implements _$EventTicketCopyWith<$Res> {
  __$EventTicketCopyWithImpl(this._self, this._then);

  final _EventTicket _self;
  final $Res Function(_EventTicket) _then;

/// Create a copy of EventTicket
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? eventId = null,Object? name = null,Object? quantity = null,Object? createdAt = null,Object? updatedAt = null,Object? description = freezed,Object? price = null,Object? soldCount = null,Object? gender = freezed,Object? minBirthYear = freezed,Object? maxBirthYear = freezed,Object? requiredVerificationIds = null,Object? status = null,}) {
  return _then(_EventTicket(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int,soldCount: null == soldCount ? _self.soldCount : soldCount // ignore: cast_nullable_to_non_nullable
as int,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,minBirthYear: freezed == minBirthYear ? _self.minBirthYear : minBirthYear // ignore: cast_nullable_to_non_nullable
as int?,maxBirthYear: freezed == maxBirthYear ? _self.maxBirthYear : maxBirthYear // ignore: cast_nullable_to_non_nullable
as int?,requiredVerificationIds: null == requiredVerificationIds ? _self._requiredVerificationIds : requiredVerificationIds // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$EventApplication {

 String get id;@JsonKey(name: 'event_id') String get eventId;@JsonKey(name: 'ticket_id') String get ticketId;@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt; String get status; String? get message;// Relationships
 Event? get event; EventTicket? get ticket;
/// Create a copy of EventApplication
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventApplicationCopyWith<EventApplication> get copyWith => _$EventApplicationCopyWithImpl<EventApplication>(this as EventApplication, _$identity);

  /// Serializes this EventApplication to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventApplication&&(identical(other.id, id) || other.id == id)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.ticketId, ticketId) || other.ticketId == ticketId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.message, message) || other.message == message)&&(identical(other.event, event) || other.event == event)&&(identical(other.ticket, ticket) || other.ticket == ticket));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,eventId,ticketId,userId,createdAt,updatedAt,status,message,event,ticket);

@override
String toString() {
  return 'EventApplication(id: $id, eventId: $eventId, ticketId: $ticketId, userId: $userId, createdAt: $createdAt, updatedAt: $updatedAt, status: $status, message: $message, event: $event, ticket: $ticket)';
}


}

/// @nodoc
abstract mixin class $EventApplicationCopyWith<$Res>  {
  factory $EventApplicationCopyWith(EventApplication value, $Res Function(EventApplication) _then) = _$EventApplicationCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'event_id') String eventId,@JsonKey(name: 'ticket_id') String ticketId,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt, String status, String? message, Event? event, EventTicket? ticket
});


$EventCopyWith<$Res>? get event;$EventTicketCopyWith<$Res>? get ticket;

}
/// @nodoc
class _$EventApplicationCopyWithImpl<$Res>
    implements $EventApplicationCopyWith<$Res> {
  _$EventApplicationCopyWithImpl(this._self, this._then);

  final EventApplication _self;
  final $Res Function(EventApplication) _then;

/// Create a copy of EventApplication
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? eventId = null,Object? ticketId = null,Object? userId = null,Object? createdAt = null,Object? updatedAt = null,Object? status = null,Object? message = freezed,Object? event = freezed,Object? ticket = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,ticketId: null == ticketId ? _self.ticketId : ticketId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,event: freezed == event ? _self.event : event // ignore: cast_nullable_to_non_nullable
as Event?,ticket: freezed == ticket ? _self.ticket : ticket // ignore: cast_nullable_to_non_nullable
as EventTicket?,
  ));
}
/// Create a copy of EventApplication
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EventCopyWith<$Res>? get event {
    if (_self.event == null) {
    return null;
  }

  return $EventCopyWith<$Res>(_self.event!, (value) {
    return _then(_self.copyWith(event: value));
  });
}/// Create a copy of EventApplication
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EventTicketCopyWith<$Res>? get ticket {
    if (_self.ticket == null) {
    return null;
  }

  return $EventTicketCopyWith<$Res>(_self.ticket!, (value) {
    return _then(_self.copyWith(ticket: value));
  });
}
}


/// Adds pattern-matching-related methods to [EventApplication].
extension EventApplicationPatterns on EventApplication {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventApplication value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventApplication() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventApplication value)  $default,){
final _that = this;
switch (_that) {
case _EventApplication():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventApplication value)?  $default,){
final _that = this;
switch (_that) {
case _EventApplication() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'event_id')  String eventId, @JsonKey(name: 'ticket_id')  String ticketId, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt,  String status,  String? message,  Event? event,  EventTicket? ticket)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventApplication() when $default != null:
return $default(_that.id,_that.eventId,_that.ticketId,_that.userId,_that.createdAt,_that.updatedAt,_that.status,_that.message,_that.event,_that.ticket);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'event_id')  String eventId, @JsonKey(name: 'ticket_id')  String ticketId, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt,  String status,  String? message,  Event? event,  EventTicket? ticket)  $default,) {final _that = this;
switch (_that) {
case _EventApplication():
return $default(_that.id,_that.eventId,_that.ticketId,_that.userId,_that.createdAt,_that.updatedAt,_that.status,_that.message,_that.event,_that.ticket);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'event_id')  String eventId, @JsonKey(name: 'ticket_id')  String ticketId, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt,  String status,  String? message,  Event? event,  EventTicket? ticket)?  $default,) {final _that = this;
switch (_that) {
case _EventApplication() when $default != null:
return $default(_that.id,_that.eventId,_that.ticketId,_that.userId,_that.createdAt,_that.updatedAt,_that.status,_that.message,_that.event,_that.ticket);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EventApplication implements EventApplication {
  const _EventApplication({required this.id, @JsonKey(name: 'event_id') required this.eventId, @JsonKey(name: 'ticket_id') required this.ticketId, @JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt, this.status = 'pending', this.message, this.event, this.ticket});
  factory _EventApplication.fromJson(Map<String, dynamic> json) => _$EventApplicationFromJson(json);

@override final  String id;
@override@JsonKey(name: 'event_id') final  String eventId;
@override@JsonKey(name: 'ticket_id') final  String ticketId;
@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;
@override@JsonKey() final  String status;
@override final  String? message;
// Relationships
@override final  Event? event;
@override final  EventTicket? ticket;

/// Create a copy of EventApplication
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventApplicationCopyWith<_EventApplication> get copyWith => __$EventApplicationCopyWithImpl<_EventApplication>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EventApplicationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventApplication&&(identical(other.id, id) || other.id == id)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.ticketId, ticketId) || other.ticketId == ticketId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.message, message) || other.message == message)&&(identical(other.event, event) || other.event == event)&&(identical(other.ticket, ticket) || other.ticket == ticket));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,eventId,ticketId,userId,createdAt,updatedAt,status,message,event,ticket);

@override
String toString() {
  return 'EventApplication(id: $id, eventId: $eventId, ticketId: $ticketId, userId: $userId, createdAt: $createdAt, updatedAt: $updatedAt, status: $status, message: $message, event: $event, ticket: $ticket)';
}


}

/// @nodoc
abstract mixin class _$EventApplicationCopyWith<$Res> implements $EventApplicationCopyWith<$Res> {
  factory _$EventApplicationCopyWith(_EventApplication value, $Res Function(_EventApplication) _then) = __$EventApplicationCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'event_id') String eventId,@JsonKey(name: 'ticket_id') String ticketId,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt, String status, String? message, Event? event, EventTicket? ticket
});


@override $EventCopyWith<$Res>? get event;@override $EventTicketCopyWith<$Res>? get ticket;

}
/// @nodoc
class __$EventApplicationCopyWithImpl<$Res>
    implements _$EventApplicationCopyWith<$Res> {
  __$EventApplicationCopyWithImpl(this._self, this._then);

  final _EventApplication _self;
  final $Res Function(_EventApplication) _then;

/// Create a copy of EventApplication
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? eventId = null,Object? ticketId = null,Object? userId = null,Object? createdAt = null,Object? updatedAt = null,Object? status = null,Object? message = freezed,Object? event = freezed,Object? ticket = freezed,}) {
  return _then(_EventApplication(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,ticketId: null == ticketId ? _self.ticketId : ticketId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,event: freezed == event ? _self.event : event // ignore: cast_nullable_to_non_nullable
as Event?,ticket: freezed == ticket ? _self.ticket : ticket // ignore: cast_nullable_to_non_nullable
as EventTicket?,
  ));
}

/// Create a copy of EventApplication
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EventCopyWith<$Res>? get event {
    if (_self.event == null) {
    return null;
  }

  return $EventCopyWith<$Res>(_self.event!, (value) {
    return _then(_self.copyWith(event: value));
  });
}/// Create a copy of EventApplication
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EventTicketCopyWith<$Res>? get ticket {
    if (_self.ticket == null) {
    return null;
  }

  return $EventTicketCopyWith<$Res>(_self.ticket!, (value) {
    return _then(_self.copyWith(ticket: value));
  });
}
}


/// @nodoc
mixin _$EventParticipant {

 String get id;@JsonKey(name: 'event_id') String get eventId;@JsonKey(name: 'ticket_id') String get ticketId;@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt;@JsonKey(name: 'application_id') String? get applicationId; String get status;@JsonKey(name: 'ticket_code') String? get ticketCode;
/// Create a copy of EventParticipant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventParticipantCopyWith<EventParticipant> get copyWith => _$EventParticipantCopyWithImpl<EventParticipant>(this as EventParticipant, _$identity);

  /// Serializes this EventParticipant to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventParticipant&&(identical(other.id, id) || other.id == id)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.ticketId, ticketId) || other.ticketId == ticketId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.applicationId, applicationId) || other.applicationId == applicationId)&&(identical(other.status, status) || other.status == status)&&(identical(other.ticketCode, ticketCode) || other.ticketCode == ticketCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,eventId,ticketId,userId,createdAt,updatedAt,applicationId,status,ticketCode);

@override
String toString() {
  return 'EventParticipant(id: $id, eventId: $eventId, ticketId: $ticketId, userId: $userId, createdAt: $createdAt, updatedAt: $updatedAt, applicationId: $applicationId, status: $status, ticketCode: $ticketCode)';
}


}

/// @nodoc
abstract mixin class $EventParticipantCopyWith<$Res>  {
  factory $EventParticipantCopyWith(EventParticipant value, $Res Function(EventParticipant) _then) = _$EventParticipantCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'event_id') String eventId,@JsonKey(name: 'ticket_id') String ticketId,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'application_id') String? applicationId, String status,@JsonKey(name: 'ticket_code') String? ticketCode
});




}
/// @nodoc
class _$EventParticipantCopyWithImpl<$Res>
    implements $EventParticipantCopyWith<$Res> {
  _$EventParticipantCopyWithImpl(this._self, this._then);

  final EventParticipant _self;
  final $Res Function(EventParticipant) _then;

/// Create a copy of EventParticipant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? eventId = null,Object? ticketId = null,Object? userId = null,Object? createdAt = null,Object? updatedAt = null,Object? applicationId = freezed,Object? status = null,Object? ticketCode = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,ticketId: null == ticketId ? _self.ticketId : ticketId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,applicationId: freezed == applicationId ? _self.applicationId : applicationId // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,ticketCode: freezed == ticketCode ? _self.ticketCode : ticketCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [EventParticipant].
extension EventParticipantPatterns on EventParticipant {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventParticipant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventParticipant() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventParticipant value)  $default,){
final _that = this;
switch (_that) {
case _EventParticipant():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventParticipant value)?  $default,){
final _that = this;
switch (_that) {
case _EventParticipant() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'event_id')  String eventId, @JsonKey(name: 'ticket_id')  String ticketId, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'application_id')  String? applicationId,  String status, @JsonKey(name: 'ticket_code')  String? ticketCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventParticipant() when $default != null:
return $default(_that.id,_that.eventId,_that.ticketId,_that.userId,_that.createdAt,_that.updatedAt,_that.applicationId,_that.status,_that.ticketCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'event_id')  String eventId, @JsonKey(name: 'ticket_id')  String ticketId, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'application_id')  String? applicationId,  String status, @JsonKey(name: 'ticket_code')  String? ticketCode)  $default,) {final _that = this;
switch (_that) {
case _EventParticipant():
return $default(_that.id,_that.eventId,_that.ticketId,_that.userId,_that.createdAt,_that.updatedAt,_that.applicationId,_that.status,_that.ticketCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'event_id')  String eventId, @JsonKey(name: 'ticket_id')  String ticketId, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'application_id')  String? applicationId,  String status, @JsonKey(name: 'ticket_code')  String? ticketCode)?  $default,) {final _that = this;
switch (_that) {
case _EventParticipant() when $default != null:
return $default(_that.id,_that.eventId,_that.ticketId,_that.userId,_that.createdAt,_that.updatedAt,_that.applicationId,_that.status,_that.ticketCode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EventParticipant implements EventParticipant {
  const _EventParticipant({required this.id, @JsonKey(name: 'event_id') required this.eventId, @JsonKey(name: 'ticket_id') required this.ticketId, @JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt, @JsonKey(name: 'application_id') this.applicationId, this.status = 'ticket_issued', @JsonKey(name: 'ticket_code') this.ticketCode});
  factory _EventParticipant.fromJson(Map<String, dynamic> json) => _$EventParticipantFromJson(json);

@override final  String id;
@override@JsonKey(name: 'event_id') final  String eventId;
@override@JsonKey(name: 'ticket_id') final  String ticketId;
@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;
@override@JsonKey(name: 'application_id') final  String? applicationId;
@override@JsonKey() final  String status;
@override@JsonKey(name: 'ticket_code') final  String? ticketCode;

/// Create a copy of EventParticipant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventParticipantCopyWith<_EventParticipant> get copyWith => __$EventParticipantCopyWithImpl<_EventParticipant>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EventParticipantToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventParticipant&&(identical(other.id, id) || other.id == id)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.ticketId, ticketId) || other.ticketId == ticketId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.applicationId, applicationId) || other.applicationId == applicationId)&&(identical(other.status, status) || other.status == status)&&(identical(other.ticketCode, ticketCode) || other.ticketCode == ticketCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,eventId,ticketId,userId,createdAt,updatedAt,applicationId,status,ticketCode);

@override
String toString() {
  return 'EventParticipant(id: $id, eventId: $eventId, ticketId: $ticketId, userId: $userId, createdAt: $createdAt, updatedAt: $updatedAt, applicationId: $applicationId, status: $status, ticketCode: $ticketCode)';
}


}

/// @nodoc
abstract mixin class _$EventParticipantCopyWith<$Res> implements $EventParticipantCopyWith<$Res> {
  factory _$EventParticipantCopyWith(_EventParticipant value, $Res Function(_EventParticipant) _then) = __$EventParticipantCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'event_id') String eventId,@JsonKey(name: 'ticket_id') String ticketId,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'application_id') String? applicationId, String status,@JsonKey(name: 'ticket_code') String? ticketCode
});




}
/// @nodoc
class __$EventParticipantCopyWithImpl<$Res>
    implements _$EventParticipantCopyWith<$Res> {
  __$EventParticipantCopyWithImpl(this._self, this._then);

  final _EventParticipant _self;
  final $Res Function(_EventParticipant) _then;

/// Create a copy of EventParticipant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? eventId = null,Object? ticketId = null,Object? userId = null,Object? createdAt = null,Object? updatedAt = null,Object? applicationId = freezed,Object? status = null,Object? ticketCode = freezed,}) {
  return _then(_EventParticipant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,ticketId: null == ticketId ? _self.ticketId : ticketId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,applicationId: freezed == applicationId ? _self.applicationId : applicationId // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,ticketCode: freezed == ticketCode ? _self.ticketCode : ticketCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
