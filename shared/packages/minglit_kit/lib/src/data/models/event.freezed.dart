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

 String get id;@JsonKey(name: 'party_id') String get partyId;@JsonKey(name: 'start_time') DateTime get startTime;@JsonKey(name: 'end_time') DateTime get endTime;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt;@JsonKey(name: 'location_id') String? get locationId; String? get title; Map<String, dynamic>? get description;@JsonKey(name: 'image_urls') List<String>? get imageUrls;@JsonKey(name: 'contact_options') Map<String, dynamic> get contactOptions; Map<String, dynamic> get metadata;@JsonKey(name: 'min_confirmed_count') int get minConfirmedCount;@JsonKey(name: 'max_participants') int get maxParticipants;@JsonKey(name: 'current_participants') int get currentParticipants; String get status; String? get visibility;@JsonKey(includeToJson: false) Location? get location;@JsonKey(includeToJson: false) Party? get party;@JsonKey(includeToJson: false) List<Ticket>? get tickets;@JsonKey(includeToJson: false) List<EntryGroup>? get entryGroups;
/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventCopyWith<Event> get copyWith => _$EventCopyWithImpl<Event>(this as Event, _$identity);

  /// Serializes this Event to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Event&&(identical(other.id, id) || other.id == id)&&(identical(other.partyId, partyId) || other.partyId == partyId)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.locationId, locationId) || other.locationId == locationId)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.description, description)&&const DeepCollectionEquality().equals(other.imageUrls, imageUrls)&&const DeepCollectionEquality().equals(other.contactOptions, contactOptions)&&const DeepCollectionEquality().equals(other.metadata, metadata)&&(identical(other.minConfirmedCount, minConfirmedCount) || other.minConfirmedCount == minConfirmedCount)&&(identical(other.maxParticipants, maxParticipants) || other.maxParticipants == maxParticipants)&&(identical(other.currentParticipants, currentParticipants) || other.currentParticipants == currentParticipants)&&(identical(other.status, status) || other.status == status)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.location, location) || other.location == location)&&(identical(other.party, party) || other.party == party)&&const DeepCollectionEquality().equals(other.tickets, tickets)&&const DeepCollectionEquality().equals(other.entryGroups, entryGroups));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,partyId,startTime,endTime,createdAt,updatedAt,locationId,title,const DeepCollectionEquality().hash(description),const DeepCollectionEquality().hash(imageUrls),const DeepCollectionEquality().hash(contactOptions),const DeepCollectionEquality().hash(metadata),minConfirmedCount,maxParticipants,currentParticipants,status,visibility,location,party,const DeepCollectionEquality().hash(tickets),const DeepCollectionEquality().hash(entryGroups)]);

@override
String toString() {
  return 'Event(id: $id, partyId: $partyId, startTime: $startTime, endTime: $endTime, createdAt: $createdAt, updatedAt: $updatedAt, locationId: $locationId, title: $title, description: $description, imageUrls: $imageUrls, contactOptions: $contactOptions, metadata: $metadata, minConfirmedCount: $minConfirmedCount, maxParticipants: $maxParticipants, currentParticipants: $currentParticipants, status: $status, visibility: $visibility, location: $location, party: $party, tickets: $tickets, entryGroups: $entryGroups)';
}


}

/// @nodoc
abstract mixin class $EventCopyWith<$Res>  {
  factory $EventCopyWith(Event value, $Res Function(Event) _then) = _$EventCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'party_id') String partyId,@JsonKey(name: 'start_time') DateTime startTime,@JsonKey(name: 'end_time') DateTime endTime,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'location_id') String? locationId, String? title, Map<String, dynamic>? description,@JsonKey(name: 'image_urls') List<String>? imageUrls,@JsonKey(name: 'contact_options') Map<String, dynamic> contactOptions, Map<String, dynamic> metadata,@JsonKey(name: 'min_confirmed_count') int minConfirmedCount,@JsonKey(name: 'max_participants') int maxParticipants,@JsonKey(name: 'current_participants') int currentParticipants, String status, String? visibility,@JsonKey(includeToJson: false) Location? location,@JsonKey(includeToJson: false) Party? party,@JsonKey(includeToJson: false) List<Ticket>? tickets,@JsonKey(includeToJson: false) List<EntryGroup>? entryGroups
});


$LocationCopyWith<$Res>? get location;$PartyCopyWith<$Res>? get party;

}
/// @nodoc
class _$EventCopyWithImpl<$Res>
    implements $EventCopyWith<$Res> {
  _$EventCopyWithImpl(this._self, this._then);

  final Event _self;
  final $Res Function(Event) _then;

/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? partyId = null,Object? startTime = null,Object? endTime = null,Object? createdAt = null,Object? updatedAt = null,Object? locationId = freezed,Object? title = freezed,Object? description = freezed,Object? imageUrls = freezed,Object? contactOptions = null,Object? metadata = null,Object? minConfirmedCount = null,Object? maxParticipants = null,Object? currentParticipants = null,Object? status = null,Object? visibility = freezed,Object? location = freezed,Object? party = freezed,Object? tickets = freezed,Object? entryGroups = freezed,}) {
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
as Map<String, dynamic>?,imageUrls: freezed == imageUrls ? _self.imageUrls : imageUrls // ignore: cast_nullable_to_non_nullable
as List<String>?,contactOptions: null == contactOptions ? _self.contactOptions : contactOptions // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,minConfirmedCount: null == minConfirmedCount ? _self.minConfirmedCount : minConfirmedCount // ignore: cast_nullable_to_non_nullable
as int,maxParticipants: null == maxParticipants ? _self.maxParticipants : maxParticipants // ignore: cast_nullable_to_non_nullable
as int,currentParticipants: null == currentParticipants ? _self.currentParticipants : currentParticipants // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,visibility: freezed == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as Location?,party: freezed == party ? _self.party : party // ignore: cast_nullable_to_non_nullable
as Party?,tickets: freezed == tickets ? _self.tickets : tickets // ignore: cast_nullable_to_non_nullable
as List<Ticket>?,entryGroups: freezed == entryGroups ? _self.entryGroups : entryGroups // ignore: cast_nullable_to_non_nullable
as List<EntryGroup>?,
  ));
}
/// Create a copy of Event
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
}/// Create a copy of Event
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'party_id')  String partyId, @JsonKey(name: 'start_time')  DateTime startTime, @JsonKey(name: 'end_time')  DateTime endTime, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'location_id')  String? locationId,  String? title,  Map<String, dynamic>? description, @JsonKey(name: 'image_urls')  List<String>? imageUrls, @JsonKey(name: 'contact_options')  Map<String, dynamic> contactOptions,  Map<String, dynamic> metadata, @JsonKey(name: 'min_confirmed_count')  int minConfirmedCount, @JsonKey(name: 'max_participants')  int maxParticipants, @JsonKey(name: 'current_participants')  int currentParticipants,  String status,  String? visibility, @JsonKey(includeToJson: false)  Location? location, @JsonKey(includeToJson: false)  Party? party, @JsonKey(includeToJson: false)  List<Ticket>? tickets, @JsonKey(includeToJson: false)  List<EntryGroup>? entryGroups)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Event() when $default != null:
return $default(_that.id,_that.partyId,_that.startTime,_that.endTime,_that.createdAt,_that.updatedAt,_that.locationId,_that.title,_that.description,_that.imageUrls,_that.contactOptions,_that.metadata,_that.minConfirmedCount,_that.maxParticipants,_that.currentParticipants,_that.status,_that.visibility,_that.location,_that.party,_that.tickets,_that.entryGroups);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'party_id')  String partyId, @JsonKey(name: 'start_time')  DateTime startTime, @JsonKey(name: 'end_time')  DateTime endTime, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'location_id')  String? locationId,  String? title,  Map<String, dynamic>? description, @JsonKey(name: 'image_urls')  List<String>? imageUrls, @JsonKey(name: 'contact_options')  Map<String, dynamic> contactOptions,  Map<String, dynamic> metadata, @JsonKey(name: 'min_confirmed_count')  int minConfirmedCount, @JsonKey(name: 'max_participants')  int maxParticipants, @JsonKey(name: 'current_participants')  int currentParticipants,  String status,  String? visibility, @JsonKey(includeToJson: false)  Location? location, @JsonKey(includeToJson: false)  Party? party, @JsonKey(includeToJson: false)  List<Ticket>? tickets, @JsonKey(includeToJson: false)  List<EntryGroup>? entryGroups)  $default,) {final _that = this;
switch (_that) {
case _Event():
return $default(_that.id,_that.partyId,_that.startTime,_that.endTime,_that.createdAt,_that.updatedAt,_that.locationId,_that.title,_that.description,_that.imageUrls,_that.contactOptions,_that.metadata,_that.minConfirmedCount,_that.maxParticipants,_that.currentParticipants,_that.status,_that.visibility,_that.location,_that.party,_that.tickets,_that.entryGroups);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'party_id')  String partyId, @JsonKey(name: 'start_time')  DateTime startTime, @JsonKey(name: 'end_time')  DateTime endTime, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'location_id')  String? locationId,  String? title,  Map<String, dynamic>? description, @JsonKey(name: 'image_urls')  List<String>? imageUrls, @JsonKey(name: 'contact_options')  Map<String, dynamic> contactOptions,  Map<String, dynamic> metadata, @JsonKey(name: 'min_confirmed_count')  int minConfirmedCount, @JsonKey(name: 'max_participants')  int maxParticipants, @JsonKey(name: 'current_participants')  int currentParticipants,  String status,  String? visibility, @JsonKey(includeToJson: false)  Location? location, @JsonKey(includeToJson: false)  Party? party, @JsonKey(includeToJson: false)  List<Ticket>? tickets, @JsonKey(includeToJson: false)  List<EntryGroup>? entryGroups)?  $default,) {final _that = this;
switch (_that) {
case _Event() when $default != null:
return $default(_that.id,_that.partyId,_that.startTime,_that.endTime,_that.createdAt,_that.updatedAt,_that.locationId,_that.title,_that.description,_that.imageUrls,_that.contactOptions,_that.metadata,_that.minConfirmedCount,_that.maxParticipants,_that.currentParticipants,_that.status,_that.visibility,_that.location,_that.party,_that.tickets,_that.entryGroups);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Event extends Event {
  const _Event({required this.id, @JsonKey(name: 'party_id') required this.partyId, @JsonKey(name: 'start_time') required this.startTime, @JsonKey(name: 'end_time') required this.endTime, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt, @JsonKey(name: 'location_id') this.locationId, this.title, final  Map<String, dynamic>? description, @JsonKey(name: 'image_urls') final  List<String>? imageUrls, @JsonKey(name: 'contact_options') final  Map<String, dynamic> contactOptions = const {}, final  Map<String, dynamic> metadata = const {}, @JsonKey(name: 'min_confirmed_count') this.minConfirmedCount = 0, @JsonKey(name: 'max_participants') this.maxParticipants = 20, @JsonKey(name: 'current_participants') this.currentParticipants = 0, this.status = 'scheduled', this.visibility, @JsonKey(includeToJson: false) this.location, @JsonKey(includeToJson: false) this.party, @JsonKey(includeToJson: false) final  List<Ticket>? tickets, @JsonKey(includeToJson: false) final  List<EntryGroup>? entryGroups}): _description = description,_imageUrls = imageUrls,_contactOptions = contactOptions,_metadata = metadata,_tickets = tickets,_entryGroups = entryGroups,super._();
  factory _Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);

@override final  String id;
@override@JsonKey(name: 'party_id') final  String partyId;
@override@JsonKey(name: 'start_time') final  DateTime startTime;
@override@JsonKey(name: 'end_time') final  DateTime endTime;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;
@override@JsonKey(name: 'location_id') final  String? locationId;
@override final  String? title;
 final  Map<String, dynamic>? _description;
@override Map<String, dynamic>? get description {
  final value = _description;
  if (value == null) return null;
  if (_description is EqualUnmodifiableMapView) return _description;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  List<String>? _imageUrls;
@override@JsonKey(name: 'image_urls') List<String>? get imageUrls {
  final value = _imageUrls;
  if (value == null) return null;
  if (_imageUrls is EqualUnmodifiableListView) return _imageUrls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  Map<String, dynamic> _contactOptions;
@override@JsonKey(name: 'contact_options') Map<String, dynamic> get contactOptions {
  if (_contactOptions is EqualUnmodifiableMapView) return _contactOptions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_contactOptions);
}

 final  Map<String, dynamic> _metadata;
@override@JsonKey() Map<String, dynamic> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}

@override@JsonKey(name: 'min_confirmed_count') final  int minConfirmedCount;
@override@JsonKey(name: 'max_participants') final  int maxParticipants;
@override@JsonKey(name: 'current_participants') final  int currentParticipants;
@override@JsonKey() final  String status;
@override final  String? visibility;
@override@JsonKey(includeToJson: false) final  Location? location;
@override@JsonKey(includeToJson: false) final  Party? party;
 final  List<Ticket>? _tickets;
@override@JsonKey(includeToJson: false) List<Ticket>? get tickets {
  final value = _tickets;
  if (value == null) return null;
  if (_tickets is EqualUnmodifiableListView) return _tickets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<EntryGroup>? _entryGroups;
@override@JsonKey(includeToJson: false) List<EntryGroup>? get entryGroups {
  final value = _entryGroups;
  if (value == null) return null;
  if (_entryGroups is EqualUnmodifiableListView) return _entryGroups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Event&&(identical(other.id, id) || other.id == id)&&(identical(other.partyId, partyId) || other.partyId == partyId)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.locationId, locationId) || other.locationId == locationId)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._description, _description)&&const DeepCollectionEquality().equals(other._imageUrls, _imageUrls)&&const DeepCollectionEquality().equals(other._contactOptions, _contactOptions)&&const DeepCollectionEquality().equals(other._metadata, _metadata)&&(identical(other.minConfirmedCount, minConfirmedCount) || other.minConfirmedCount == minConfirmedCount)&&(identical(other.maxParticipants, maxParticipants) || other.maxParticipants == maxParticipants)&&(identical(other.currentParticipants, currentParticipants) || other.currentParticipants == currentParticipants)&&(identical(other.status, status) || other.status == status)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.location, location) || other.location == location)&&(identical(other.party, party) || other.party == party)&&const DeepCollectionEquality().equals(other._tickets, _tickets)&&const DeepCollectionEquality().equals(other._entryGroups, _entryGroups));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,partyId,startTime,endTime,createdAt,updatedAt,locationId,title,const DeepCollectionEquality().hash(_description),const DeepCollectionEquality().hash(_imageUrls),const DeepCollectionEquality().hash(_contactOptions),const DeepCollectionEquality().hash(_metadata),minConfirmedCount,maxParticipants,currentParticipants,status,visibility,location,party,const DeepCollectionEquality().hash(_tickets),const DeepCollectionEquality().hash(_entryGroups)]);

@override
String toString() {
  return 'Event(id: $id, partyId: $partyId, startTime: $startTime, endTime: $endTime, createdAt: $createdAt, updatedAt: $updatedAt, locationId: $locationId, title: $title, description: $description, imageUrls: $imageUrls, contactOptions: $contactOptions, metadata: $metadata, minConfirmedCount: $minConfirmedCount, maxParticipants: $maxParticipants, currentParticipants: $currentParticipants, status: $status, visibility: $visibility, location: $location, party: $party, tickets: $tickets, entryGroups: $entryGroups)';
}


}

/// @nodoc
abstract mixin class _$EventCopyWith<$Res> implements $EventCopyWith<$Res> {
  factory _$EventCopyWith(_Event value, $Res Function(_Event) _then) = __$EventCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'party_id') String partyId,@JsonKey(name: 'start_time') DateTime startTime,@JsonKey(name: 'end_time') DateTime endTime,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'location_id') String? locationId, String? title, Map<String, dynamic>? description,@JsonKey(name: 'image_urls') List<String>? imageUrls,@JsonKey(name: 'contact_options') Map<String, dynamic> contactOptions, Map<String, dynamic> metadata,@JsonKey(name: 'min_confirmed_count') int minConfirmedCount,@JsonKey(name: 'max_participants') int maxParticipants,@JsonKey(name: 'current_participants') int currentParticipants, String status, String? visibility,@JsonKey(includeToJson: false) Location? location,@JsonKey(includeToJson: false) Party? party,@JsonKey(includeToJson: false) List<Ticket>? tickets,@JsonKey(includeToJson: false) List<EntryGroup>? entryGroups
});


@override $LocationCopyWith<$Res>? get location;@override $PartyCopyWith<$Res>? get party;

}
/// @nodoc
class __$EventCopyWithImpl<$Res>
    implements _$EventCopyWith<$Res> {
  __$EventCopyWithImpl(this._self, this._then);

  final _Event _self;
  final $Res Function(_Event) _then;

/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? partyId = null,Object? startTime = null,Object? endTime = null,Object? createdAt = null,Object? updatedAt = null,Object? locationId = freezed,Object? title = freezed,Object? description = freezed,Object? imageUrls = freezed,Object? contactOptions = null,Object? metadata = null,Object? minConfirmedCount = null,Object? maxParticipants = null,Object? currentParticipants = null,Object? status = null,Object? visibility = freezed,Object? location = freezed,Object? party = freezed,Object? tickets = freezed,Object? entryGroups = freezed,}) {
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
as Map<String, dynamic>?,imageUrls: freezed == imageUrls ? _self._imageUrls : imageUrls // ignore: cast_nullable_to_non_nullable
as List<String>?,contactOptions: null == contactOptions ? _self._contactOptions : contactOptions // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,minConfirmedCount: null == minConfirmedCount ? _self.minConfirmedCount : minConfirmedCount // ignore: cast_nullable_to_non_nullable
as int,maxParticipants: null == maxParticipants ? _self.maxParticipants : maxParticipants // ignore: cast_nullable_to_non_nullable
as int,currentParticipants: null == currentParticipants ? _self.currentParticipants : currentParticipants // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,visibility: freezed == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as Location?,party: freezed == party ? _self.party : party // ignore: cast_nullable_to_non_nullable
as Party?,tickets: freezed == tickets ? _self._tickets : tickets // ignore: cast_nullable_to_non_nullable
as List<Ticket>?,entryGroups: freezed == entryGroups ? _self._entryGroups : entryGroups // ignore: cast_nullable_to_non_nullable
as List<EntryGroup>?,
  ));
}

/// Create a copy of Event
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
}/// Create a copy of Event
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
}
}

// dart format on
