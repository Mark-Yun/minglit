// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'party.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Location {

 String get id;@JsonKey(name: 'partner_id') String get partnerId; String get name; String get address;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt;@JsonKey(name: 'address_detail') String? get addressDetail;@JsonKey(name: 'region_1') String? get region1;@JsonKey(name: 'region_2') String? get region2;@JsonKey(name: 'region_3') String? get region3;@JsonKey(name: 'directions_guide') String? get directionsGuide;@JsonKey(name: 'postal_code') String? get postalCode;// GeoJSON Point or lat/lng handled manually if needed.
@JsonKey(includeFromJson: false, includeToJson: false) dynamic get geoPoint;// UI Convenience fields
@JsonKey(name: 'lat') double get latitude;@JsonKey(name: 'lng') double get longitude;
/// Create a copy of Location
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocationCopyWith<Location> get copyWith => _$LocationCopyWithImpl<Location>(this as Location, _$identity);

  /// Serializes this Location to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Location&&(identical(other.id, id) || other.id == id)&&(identical(other.partnerId, partnerId) || other.partnerId == partnerId)&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.addressDetail, addressDetail) || other.addressDetail == addressDetail)&&(identical(other.region1, region1) || other.region1 == region1)&&(identical(other.region2, region2) || other.region2 == region2)&&(identical(other.region3, region3) || other.region3 == region3)&&(identical(other.directionsGuide, directionsGuide) || other.directionsGuide == directionsGuide)&&(identical(other.postalCode, postalCode) || other.postalCode == postalCode)&&const DeepCollectionEquality().equals(other.geoPoint, geoPoint)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,partnerId,name,address,createdAt,updatedAt,addressDetail,region1,region2,region3,directionsGuide,postalCode,const DeepCollectionEquality().hash(geoPoint),latitude,longitude);

@override
String toString() {
  return 'Location(id: $id, partnerId: $partnerId, name: $name, address: $address, createdAt: $createdAt, updatedAt: $updatedAt, addressDetail: $addressDetail, region1: $region1, region2: $region2, region3: $region3, directionsGuide: $directionsGuide, postalCode: $postalCode, geoPoint: $geoPoint, latitude: $latitude, longitude: $longitude)';
}


}

/// @nodoc
abstract mixin class $LocationCopyWith<$Res>  {
  factory $LocationCopyWith(Location value, $Res Function(Location) _then) = _$LocationCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'partner_id') String partnerId, String name, String address,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'address_detail') String? addressDetail,@JsonKey(name: 'region_1') String? region1,@JsonKey(name: 'region_2') String? region2,@JsonKey(name: 'region_3') String? region3,@JsonKey(name: 'directions_guide') String? directionsGuide,@JsonKey(name: 'postal_code') String? postalCode,@JsonKey(includeFromJson: false, includeToJson: false) dynamic geoPoint,@JsonKey(name: 'lat') double latitude,@JsonKey(name: 'lng') double longitude
});




}
/// @nodoc
class _$LocationCopyWithImpl<$Res>
    implements $LocationCopyWith<$Res> {
  _$LocationCopyWithImpl(this._self, this._then);

  final Location _self;
  final $Res Function(Location) _then;

/// Create a copy of Location
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? partnerId = null,Object? name = null,Object? address = null,Object? createdAt = null,Object? updatedAt = null,Object? addressDetail = freezed,Object? region1 = freezed,Object? region2 = freezed,Object? region3 = freezed,Object? directionsGuide = freezed,Object? postalCode = freezed,Object? geoPoint = freezed,Object? latitude = null,Object? longitude = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,partnerId: null == partnerId ? _self.partnerId : partnerId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,addressDetail: freezed == addressDetail ? _self.addressDetail : addressDetail // ignore: cast_nullable_to_non_nullable
as String?,region1: freezed == region1 ? _self.region1 : region1 // ignore: cast_nullable_to_non_nullable
as String?,region2: freezed == region2 ? _self.region2 : region2 // ignore: cast_nullable_to_non_nullable
as String?,region3: freezed == region3 ? _self.region3 : region3 // ignore: cast_nullable_to_non_nullable
as String?,directionsGuide: freezed == directionsGuide ? _self.directionsGuide : directionsGuide // ignore: cast_nullable_to_non_nullable
as String?,postalCode: freezed == postalCode ? _self.postalCode : postalCode // ignore: cast_nullable_to_non_nullable
as String?,geoPoint: freezed == geoPoint ? _self.geoPoint : geoPoint // ignore: cast_nullable_to_non_nullable
as dynamic,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [Location].
extension LocationPatterns on Location {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Location value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Location() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Location value)  $default,){
final _that = this;
switch (_that) {
case _Location():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Location value)?  $default,){
final _that = this;
switch (_that) {
case _Location() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'partner_id')  String partnerId,  String name,  String address, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'address_detail')  String? addressDetail, @JsonKey(name: 'region_1')  String? region1, @JsonKey(name: 'region_2')  String? region2, @JsonKey(name: 'region_3')  String? region3, @JsonKey(name: 'directions_guide')  String? directionsGuide, @JsonKey(name: 'postal_code')  String? postalCode, @JsonKey(includeFromJson: false, includeToJson: false)  dynamic geoPoint, @JsonKey(name: 'lat')  double latitude, @JsonKey(name: 'lng')  double longitude)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Location() when $default != null:
return $default(_that.id,_that.partnerId,_that.name,_that.address,_that.createdAt,_that.updatedAt,_that.addressDetail,_that.region1,_that.region2,_that.region3,_that.directionsGuide,_that.postalCode,_that.geoPoint,_that.latitude,_that.longitude);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'partner_id')  String partnerId,  String name,  String address, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'address_detail')  String? addressDetail, @JsonKey(name: 'region_1')  String? region1, @JsonKey(name: 'region_2')  String? region2, @JsonKey(name: 'region_3')  String? region3, @JsonKey(name: 'directions_guide')  String? directionsGuide, @JsonKey(name: 'postal_code')  String? postalCode, @JsonKey(includeFromJson: false, includeToJson: false)  dynamic geoPoint, @JsonKey(name: 'lat')  double latitude, @JsonKey(name: 'lng')  double longitude)  $default,) {final _that = this;
switch (_that) {
case _Location():
return $default(_that.id,_that.partnerId,_that.name,_that.address,_that.createdAt,_that.updatedAt,_that.addressDetail,_that.region1,_that.region2,_that.region3,_that.directionsGuide,_that.postalCode,_that.geoPoint,_that.latitude,_that.longitude);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'partner_id')  String partnerId,  String name,  String address, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'address_detail')  String? addressDetail, @JsonKey(name: 'region_1')  String? region1, @JsonKey(name: 'region_2')  String? region2, @JsonKey(name: 'region_3')  String? region3, @JsonKey(name: 'directions_guide')  String? directionsGuide, @JsonKey(name: 'postal_code')  String? postalCode, @JsonKey(includeFromJson: false, includeToJson: false)  dynamic geoPoint, @JsonKey(name: 'lat')  double latitude, @JsonKey(name: 'lng')  double longitude)?  $default,) {final _that = this;
switch (_that) {
case _Location() when $default != null:
return $default(_that.id,_that.partnerId,_that.name,_that.address,_that.createdAt,_that.updatedAt,_that.addressDetail,_that.region1,_that.region2,_that.region3,_that.directionsGuide,_that.postalCode,_that.geoPoint,_that.latitude,_that.longitude);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Location implements Location {
  const _Location({required this.id, @JsonKey(name: 'partner_id') required this.partnerId, required this.name, required this.address, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt, @JsonKey(name: 'address_detail') this.addressDetail, @JsonKey(name: 'region_1') this.region1, @JsonKey(name: 'region_2') this.region2, @JsonKey(name: 'region_3') this.region3, @JsonKey(name: 'directions_guide') this.directionsGuide, @JsonKey(name: 'postal_code') this.postalCode, @JsonKey(includeFromJson: false, includeToJson: false) this.geoPoint, @JsonKey(name: 'lat') this.latitude = 0.0, @JsonKey(name: 'lng') this.longitude = 0.0});
  factory _Location.fromJson(Map<String, dynamic> json) => _$LocationFromJson(json);

@override final  String id;
@override@JsonKey(name: 'partner_id') final  String partnerId;
@override final  String name;
@override final  String address;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;
@override@JsonKey(name: 'address_detail') final  String? addressDetail;
@override@JsonKey(name: 'region_1') final  String? region1;
@override@JsonKey(name: 'region_2') final  String? region2;
@override@JsonKey(name: 'region_3') final  String? region3;
@override@JsonKey(name: 'directions_guide') final  String? directionsGuide;
@override@JsonKey(name: 'postal_code') final  String? postalCode;
// GeoJSON Point or lat/lng handled manually if needed.
@override@JsonKey(includeFromJson: false, includeToJson: false) final  dynamic geoPoint;
// UI Convenience fields
@override@JsonKey(name: 'lat') final  double latitude;
@override@JsonKey(name: 'lng') final  double longitude;

/// Create a copy of Location
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LocationCopyWith<_Location> get copyWith => __$LocationCopyWithImpl<_Location>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LocationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Location&&(identical(other.id, id) || other.id == id)&&(identical(other.partnerId, partnerId) || other.partnerId == partnerId)&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.addressDetail, addressDetail) || other.addressDetail == addressDetail)&&(identical(other.region1, region1) || other.region1 == region1)&&(identical(other.region2, region2) || other.region2 == region2)&&(identical(other.region3, region3) || other.region3 == region3)&&(identical(other.directionsGuide, directionsGuide) || other.directionsGuide == directionsGuide)&&(identical(other.postalCode, postalCode) || other.postalCode == postalCode)&&const DeepCollectionEquality().equals(other.geoPoint, geoPoint)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,partnerId,name,address,createdAt,updatedAt,addressDetail,region1,region2,region3,directionsGuide,postalCode,const DeepCollectionEquality().hash(geoPoint),latitude,longitude);

@override
String toString() {
  return 'Location(id: $id, partnerId: $partnerId, name: $name, address: $address, createdAt: $createdAt, updatedAt: $updatedAt, addressDetail: $addressDetail, region1: $region1, region2: $region2, region3: $region3, directionsGuide: $directionsGuide, postalCode: $postalCode, geoPoint: $geoPoint, latitude: $latitude, longitude: $longitude)';
}


}

/// @nodoc
abstract mixin class _$LocationCopyWith<$Res> implements $LocationCopyWith<$Res> {
  factory _$LocationCopyWith(_Location value, $Res Function(_Location) _then) = __$LocationCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'partner_id') String partnerId, String name, String address,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'address_detail') String? addressDetail,@JsonKey(name: 'region_1') String? region1,@JsonKey(name: 'region_2') String? region2,@JsonKey(name: 'region_3') String? region3,@JsonKey(name: 'directions_guide') String? directionsGuide,@JsonKey(name: 'postal_code') String? postalCode,@JsonKey(includeFromJson: false, includeToJson: false) dynamic geoPoint,@JsonKey(name: 'lat') double latitude,@JsonKey(name: 'lng') double longitude
});




}
/// @nodoc
class __$LocationCopyWithImpl<$Res>
    implements _$LocationCopyWith<$Res> {
  __$LocationCopyWithImpl(this._self, this._then);

  final _Location _self;
  final $Res Function(_Location) _then;

/// Create a copy of Location
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? partnerId = null,Object? name = null,Object? address = null,Object? createdAt = null,Object? updatedAt = null,Object? addressDetail = freezed,Object? region1 = freezed,Object? region2 = freezed,Object? region3 = freezed,Object? directionsGuide = freezed,Object? postalCode = freezed,Object? geoPoint = freezed,Object? latitude = null,Object? longitude = null,}) {
  return _then(_Location(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,partnerId: null == partnerId ? _self.partnerId : partnerId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,addressDetail: freezed == addressDetail ? _self.addressDetail : addressDetail // ignore: cast_nullable_to_non_nullable
as String?,region1: freezed == region1 ? _self.region1 : region1 // ignore: cast_nullable_to_non_nullable
as String?,region2: freezed == region2 ? _self.region2 : region2 // ignore: cast_nullable_to_non_nullable
as String?,region3: freezed == region3 ? _self.region3 : region3 // ignore: cast_nullable_to_non_nullable
as String?,directionsGuide: freezed == directionsGuide ? _self.directionsGuide : directionsGuide // ignore: cast_nullable_to_non_nullable
as String?,postalCode: freezed == postalCode ? _self.postalCode : postalCode // ignore: cast_nullable_to_non_nullable
as String?,geoPoint: freezed == geoPoint ? _self.geoPoint : geoPoint // ignore: cast_nullable_to_non_nullable
as dynamic,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$Party {

 String get id;@JsonKey(name: 'partner_id') String get partnerId; String get title;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt;@JsonKey(name: 'location_id') String? get locationId;@JsonKey(includeToJson: false) Location? get location; Map<String, dynamic>? get description;// Quill Delta JSON
@JsonKey(name: 'image_url') String? get imageUrl;@JsonKey(name: 'contact_options') Map<String, dynamic> get contactOptions; List<dynamic> get conditions;// JSONB Array of condition sets
@JsonKey(name: 'required_verification_ids') List<String> get requiredVerificationIds;@JsonKey(name: 'min_confirmed_count') int get minConfirmedCount;@JsonKey(name: 'max_participants') int get maxParticipants; String get status;
/// Create a copy of Party
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PartyCopyWith<Party> get copyWith => _$PartyCopyWithImpl<Party>(this as Party, _$identity);

  /// Serializes this Party to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Party&&(identical(other.id, id) || other.id == id)&&(identical(other.partnerId, partnerId) || other.partnerId == partnerId)&&(identical(other.title, title) || other.title == title)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.locationId, locationId) || other.locationId == locationId)&&(identical(other.location, location) || other.location == location)&&const DeepCollectionEquality().equals(other.description, description)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&const DeepCollectionEquality().equals(other.contactOptions, contactOptions)&&const DeepCollectionEquality().equals(other.conditions, conditions)&&const DeepCollectionEquality().equals(other.requiredVerificationIds, requiredVerificationIds)&&(identical(other.minConfirmedCount, minConfirmedCount) || other.minConfirmedCount == minConfirmedCount)&&(identical(other.maxParticipants, maxParticipants) || other.maxParticipants == maxParticipants)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,partnerId,title,createdAt,updatedAt,locationId,location,const DeepCollectionEquality().hash(description),imageUrl,const DeepCollectionEquality().hash(contactOptions),const DeepCollectionEquality().hash(conditions),const DeepCollectionEquality().hash(requiredVerificationIds),minConfirmedCount,maxParticipants,status);

@override
String toString() {
  return 'Party(id: $id, partnerId: $partnerId, title: $title, createdAt: $createdAt, updatedAt: $updatedAt, locationId: $locationId, location: $location, description: $description, imageUrl: $imageUrl, contactOptions: $contactOptions, conditions: $conditions, requiredVerificationIds: $requiredVerificationIds, minConfirmedCount: $minConfirmedCount, maxParticipants: $maxParticipants, status: $status)';
}


}

/// @nodoc
abstract mixin class $PartyCopyWith<$Res>  {
  factory $PartyCopyWith(Party value, $Res Function(Party) _then) = _$PartyCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'partner_id') String partnerId, String title,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'location_id') String? locationId,@JsonKey(includeToJson: false) Location? location, Map<String, dynamic>? description,@JsonKey(name: 'image_url') String? imageUrl,@JsonKey(name: 'contact_options') Map<String, dynamic> contactOptions, List<dynamic> conditions,@JsonKey(name: 'required_verification_ids') List<String> requiredVerificationIds,@JsonKey(name: 'min_confirmed_count') int minConfirmedCount,@JsonKey(name: 'max_participants') int maxParticipants, String status
});


$LocationCopyWith<$Res>? get location;

}
/// @nodoc
class _$PartyCopyWithImpl<$Res>
    implements $PartyCopyWith<$Res> {
  _$PartyCopyWithImpl(this._self, this._then);

  final Party _self;
  final $Res Function(Party) _then;

/// Create a copy of Party
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? partnerId = null,Object? title = null,Object? createdAt = null,Object? updatedAt = null,Object? locationId = freezed,Object? location = freezed,Object? description = freezed,Object? imageUrl = freezed,Object? contactOptions = null,Object? conditions = null,Object? requiredVerificationIds = null,Object? minConfirmedCount = null,Object? maxParticipants = null,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,partnerId: null == partnerId ? _self.partnerId : partnerId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,locationId: freezed == locationId ? _self.locationId : locationId // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as Location?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,contactOptions: null == contactOptions ? _self.contactOptions : contactOptions // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,conditions: null == conditions ? _self.conditions : conditions // ignore: cast_nullable_to_non_nullable
as List<dynamic>,requiredVerificationIds: null == requiredVerificationIds ? _self.requiredVerificationIds : requiredVerificationIds // ignore: cast_nullable_to_non_nullable
as List<String>,minConfirmedCount: null == minConfirmedCount ? _self.minConfirmedCount : minConfirmedCount // ignore: cast_nullable_to_non_nullable
as int,maxParticipants: null == maxParticipants ? _self.maxParticipants : maxParticipants // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of Party
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


/// Adds pattern-matching-related methods to [Party].
extension PartyPatterns on Party {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Party value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Party() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Party value)  $default,){
final _that = this;
switch (_that) {
case _Party():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Party value)?  $default,){
final _that = this;
switch (_that) {
case _Party() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'partner_id')  String partnerId,  String title, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'location_id')  String? locationId, @JsonKey(includeToJson: false)  Location? location,  Map<String, dynamic>? description, @JsonKey(name: 'image_url')  String? imageUrl, @JsonKey(name: 'contact_options')  Map<String, dynamic> contactOptions,  List<dynamic> conditions, @JsonKey(name: 'required_verification_ids')  List<String> requiredVerificationIds, @JsonKey(name: 'min_confirmed_count')  int minConfirmedCount, @JsonKey(name: 'max_participants')  int maxParticipants,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Party() when $default != null:
return $default(_that.id,_that.partnerId,_that.title,_that.createdAt,_that.updatedAt,_that.locationId,_that.location,_that.description,_that.imageUrl,_that.contactOptions,_that.conditions,_that.requiredVerificationIds,_that.minConfirmedCount,_that.maxParticipants,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'partner_id')  String partnerId,  String title, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'location_id')  String? locationId, @JsonKey(includeToJson: false)  Location? location,  Map<String, dynamic>? description, @JsonKey(name: 'image_url')  String? imageUrl, @JsonKey(name: 'contact_options')  Map<String, dynamic> contactOptions,  List<dynamic> conditions, @JsonKey(name: 'required_verification_ids')  List<String> requiredVerificationIds, @JsonKey(name: 'min_confirmed_count')  int minConfirmedCount, @JsonKey(name: 'max_participants')  int maxParticipants,  String status)  $default,) {final _that = this;
switch (_that) {
case _Party():
return $default(_that.id,_that.partnerId,_that.title,_that.createdAt,_that.updatedAt,_that.locationId,_that.location,_that.description,_that.imageUrl,_that.contactOptions,_that.conditions,_that.requiredVerificationIds,_that.minConfirmedCount,_that.maxParticipants,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'partner_id')  String partnerId,  String title, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'location_id')  String? locationId, @JsonKey(includeToJson: false)  Location? location,  Map<String, dynamic>? description, @JsonKey(name: 'image_url')  String? imageUrl, @JsonKey(name: 'contact_options')  Map<String, dynamic> contactOptions,  List<dynamic> conditions, @JsonKey(name: 'required_verification_ids')  List<String> requiredVerificationIds, @JsonKey(name: 'min_confirmed_count')  int minConfirmedCount, @JsonKey(name: 'max_participants')  int maxParticipants,  String status)?  $default,) {final _that = this;
switch (_that) {
case _Party() when $default != null:
return $default(_that.id,_that.partnerId,_that.title,_that.createdAt,_that.updatedAt,_that.locationId,_that.location,_that.description,_that.imageUrl,_that.contactOptions,_that.conditions,_that.requiredVerificationIds,_that.minConfirmedCount,_that.maxParticipants,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Party implements Party {
  const _Party({required this.id, @JsonKey(name: 'partner_id') required this.partnerId, required this.title, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt, @JsonKey(name: 'location_id') this.locationId, @JsonKey(includeToJson: false) this.location, final  Map<String, dynamic>? description, @JsonKey(name: 'image_url') this.imageUrl, @JsonKey(name: 'contact_options') final  Map<String, dynamic> contactOptions = const {}, final  List<dynamic> conditions = const [], @JsonKey(name: 'required_verification_ids') final  List<String> requiredVerificationIds = const [], @JsonKey(name: 'min_confirmed_count') this.minConfirmedCount = 0, @JsonKey(name: 'max_participants') this.maxParticipants = 20, this.status = 'active'}): _description = description,_contactOptions = contactOptions,_conditions = conditions,_requiredVerificationIds = requiredVerificationIds;
  factory _Party.fromJson(Map<String, dynamic> json) => _$PartyFromJson(json);

@override final  String id;
@override@JsonKey(name: 'partner_id') final  String partnerId;
@override final  String title;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;
@override@JsonKey(name: 'location_id') final  String? locationId;
@override@JsonKey(includeToJson: false) final  Location? location;
 final  Map<String, dynamic>? _description;
@override Map<String, dynamic>? get description {
  final value = _description;
  if (value == null) return null;
  if (_description is EqualUnmodifiableMapView) return _description;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

// Quill Delta JSON
@override@JsonKey(name: 'image_url') final  String? imageUrl;
 final  Map<String, dynamic> _contactOptions;
@override@JsonKey(name: 'contact_options') Map<String, dynamic> get contactOptions {
  if (_contactOptions is EqualUnmodifiableMapView) return _contactOptions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_contactOptions);
}

 final  List<dynamic> _conditions;
@override@JsonKey() List<dynamic> get conditions {
  if (_conditions is EqualUnmodifiableListView) return _conditions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_conditions);
}

// JSONB Array of condition sets
 final  List<String> _requiredVerificationIds;
// JSONB Array of condition sets
@override@JsonKey(name: 'required_verification_ids') List<String> get requiredVerificationIds {
  if (_requiredVerificationIds is EqualUnmodifiableListView) return _requiredVerificationIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_requiredVerificationIds);
}

@override@JsonKey(name: 'min_confirmed_count') final  int minConfirmedCount;
@override@JsonKey(name: 'max_participants') final  int maxParticipants;
@override@JsonKey() final  String status;

/// Create a copy of Party
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PartyCopyWith<_Party> get copyWith => __$PartyCopyWithImpl<_Party>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PartyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Party&&(identical(other.id, id) || other.id == id)&&(identical(other.partnerId, partnerId) || other.partnerId == partnerId)&&(identical(other.title, title) || other.title == title)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.locationId, locationId) || other.locationId == locationId)&&(identical(other.location, location) || other.location == location)&&const DeepCollectionEquality().equals(other._description, _description)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&const DeepCollectionEquality().equals(other._contactOptions, _contactOptions)&&const DeepCollectionEquality().equals(other._conditions, _conditions)&&const DeepCollectionEquality().equals(other._requiredVerificationIds, _requiredVerificationIds)&&(identical(other.minConfirmedCount, minConfirmedCount) || other.minConfirmedCount == minConfirmedCount)&&(identical(other.maxParticipants, maxParticipants) || other.maxParticipants == maxParticipants)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,partnerId,title,createdAt,updatedAt,locationId,location,const DeepCollectionEquality().hash(_description),imageUrl,const DeepCollectionEquality().hash(_contactOptions),const DeepCollectionEquality().hash(_conditions),const DeepCollectionEquality().hash(_requiredVerificationIds),minConfirmedCount,maxParticipants,status);

@override
String toString() {
  return 'Party(id: $id, partnerId: $partnerId, title: $title, createdAt: $createdAt, updatedAt: $updatedAt, locationId: $locationId, location: $location, description: $description, imageUrl: $imageUrl, contactOptions: $contactOptions, conditions: $conditions, requiredVerificationIds: $requiredVerificationIds, minConfirmedCount: $minConfirmedCount, maxParticipants: $maxParticipants, status: $status)';
}


}

/// @nodoc
abstract mixin class _$PartyCopyWith<$Res> implements $PartyCopyWith<$Res> {
  factory _$PartyCopyWith(_Party value, $Res Function(_Party) _then) = __$PartyCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'partner_id') String partnerId, String title,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'location_id') String? locationId,@JsonKey(includeToJson: false) Location? location, Map<String, dynamic>? description,@JsonKey(name: 'image_url') String? imageUrl,@JsonKey(name: 'contact_options') Map<String, dynamic> contactOptions, List<dynamic> conditions,@JsonKey(name: 'required_verification_ids') List<String> requiredVerificationIds,@JsonKey(name: 'min_confirmed_count') int minConfirmedCount,@JsonKey(name: 'max_participants') int maxParticipants, String status
});


@override $LocationCopyWith<$Res>? get location;

}
/// @nodoc
class __$PartyCopyWithImpl<$Res>
    implements _$PartyCopyWith<$Res> {
  __$PartyCopyWithImpl(this._self, this._then);

  final _Party _self;
  final $Res Function(_Party) _then;

/// Create a copy of Party
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? partnerId = null,Object? title = null,Object? createdAt = null,Object? updatedAt = null,Object? locationId = freezed,Object? location = freezed,Object? description = freezed,Object? imageUrl = freezed,Object? contactOptions = null,Object? conditions = null,Object? requiredVerificationIds = null,Object? minConfirmedCount = null,Object? maxParticipants = null,Object? status = null,}) {
  return _then(_Party(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,partnerId: null == partnerId ? _self.partnerId : partnerId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,locationId: freezed == locationId ? _self.locationId : locationId // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as Location?,description: freezed == description ? _self._description : description // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,contactOptions: null == contactOptions ? _self._contactOptions : contactOptions // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,conditions: null == conditions ? _self._conditions : conditions // ignore: cast_nullable_to_non_nullable
as List<dynamic>,requiredVerificationIds: null == requiredVerificationIds ? _self._requiredVerificationIds : requiredVerificationIds // ignore: cast_nullable_to_non_nullable
as List<String>,minConfirmedCount: null == minConfirmedCount ? _self.minConfirmedCount : minConfirmedCount // ignore: cast_nullable_to_non_nullable
as int,maxParticipants: null == maxParticipants ? _self.maxParticipants : maxParticipants // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of Party
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

// dart format on
