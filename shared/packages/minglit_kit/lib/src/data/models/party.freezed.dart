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

 String get id;@JsonKey(name: 'partner_id') String get partnerId; String get name; String get address;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt;@JsonKey(name: 'address_detail') String? get addressDetail; String? get sido; String? get sigungu;// GeoJSON Point or lat/lng handled manually if needed.
@JsonKey(includeFromJson: false, includeToJson: false) dynamic get geoPoint;
/// Create a copy of Location
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocationCopyWith<Location> get copyWith => _$LocationCopyWithImpl<Location>(this as Location, _$identity);

  /// Serializes this Location to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Location&&(identical(other.id, id) || other.id == id)&&(identical(other.partnerId, partnerId) || other.partnerId == partnerId)&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.addressDetail, addressDetail) || other.addressDetail == addressDetail)&&(identical(other.sido, sido) || other.sido == sido)&&(identical(other.sigungu, sigungu) || other.sigungu == sigungu)&&const DeepCollectionEquality().equals(other.geoPoint, geoPoint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,partnerId,name,address,createdAt,updatedAt,addressDetail,sido,sigungu,const DeepCollectionEquality().hash(geoPoint));

@override
String toString() {
  return 'Location(id: $id, partnerId: $partnerId, name: $name, address: $address, createdAt: $createdAt, updatedAt: $updatedAt, addressDetail: $addressDetail, sido: $sido, sigungu: $sigungu, geoPoint: $geoPoint)';
}


}

/// @nodoc
abstract mixin class $LocationCopyWith<$Res>  {
  factory $LocationCopyWith(Location value, $Res Function(Location) _then) = _$LocationCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'partner_id') String partnerId, String name, String address,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'address_detail') String? addressDetail, String? sido, String? sigungu,@JsonKey(includeFromJson: false, includeToJson: false) dynamic geoPoint
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? partnerId = null,Object? name = null,Object? address = null,Object? createdAt = null,Object? updatedAt = null,Object? addressDetail = freezed,Object? sido = freezed,Object? sigungu = freezed,Object? geoPoint = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,partnerId: null == partnerId ? _self.partnerId : partnerId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,addressDetail: freezed == addressDetail ? _self.addressDetail : addressDetail // ignore: cast_nullable_to_non_nullable
as String?,sido: freezed == sido ? _self.sido : sido // ignore: cast_nullable_to_non_nullable
as String?,sigungu: freezed == sigungu ? _self.sigungu : sigungu // ignore: cast_nullable_to_non_nullable
as String?,geoPoint: freezed == geoPoint ? _self.geoPoint : geoPoint // ignore: cast_nullable_to_non_nullable
as dynamic,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'partner_id')  String partnerId,  String name,  String address, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'address_detail')  String? addressDetail,  String? sido,  String? sigungu, @JsonKey(includeFromJson: false, includeToJson: false)  dynamic geoPoint)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Location() when $default != null:
return $default(_that.id,_that.partnerId,_that.name,_that.address,_that.createdAt,_that.updatedAt,_that.addressDetail,_that.sido,_that.sigungu,_that.geoPoint);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'partner_id')  String partnerId,  String name,  String address, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'address_detail')  String? addressDetail,  String? sido,  String? sigungu, @JsonKey(includeFromJson: false, includeToJson: false)  dynamic geoPoint)  $default,) {final _that = this;
switch (_that) {
case _Location():
return $default(_that.id,_that.partnerId,_that.name,_that.address,_that.createdAt,_that.updatedAt,_that.addressDetail,_that.sido,_that.sigungu,_that.geoPoint);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'partner_id')  String partnerId,  String name,  String address, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'address_detail')  String? addressDetail,  String? sido,  String? sigungu, @JsonKey(includeFromJson: false, includeToJson: false)  dynamic geoPoint)?  $default,) {final _that = this;
switch (_that) {
case _Location() when $default != null:
return $default(_that.id,_that.partnerId,_that.name,_that.address,_that.createdAt,_that.updatedAt,_that.addressDetail,_that.sido,_that.sigungu,_that.geoPoint);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Location implements Location {
  const _Location({required this.id, @JsonKey(name: 'partner_id') required this.partnerId, required this.name, required this.address, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt, @JsonKey(name: 'address_detail') this.addressDetail, this.sido, this.sigungu, @JsonKey(includeFromJson: false, includeToJson: false) this.geoPoint});
  factory _Location.fromJson(Map<String, dynamic> json) => _$LocationFromJson(json);

@override final  String id;
@override@JsonKey(name: 'partner_id') final  String partnerId;
@override final  String name;
@override final  String address;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;
@override@JsonKey(name: 'address_detail') final  String? addressDetail;
@override final  String? sido;
@override final  String? sigungu;
// GeoJSON Point or lat/lng handled manually if needed.
@override@JsonKey(includeFromJson: false, includeToJson: false) final  dynamic geoPoint;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Location&&(identical(other.id, id) || other.id == id)&&(identical(other.partnerId, partnerId) || other.partnerId == partnerId)&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.addressDetail, addressDetail) || other.addressDetail == addressDetail)&&(identical(other.sido, sido) || other.sido == sido)&&(identical(other.sigungu, sigungu) || other.sigungu == sigungu)&&const DeepCollectionEquality().equals(other.geoPoint, geoPoint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,partnerId,name,address,createdAt,updatedAt,addressDetail,sido,sigungu,const DeepCollectionEquality().hash(geoPoint));

@override
String toString() {
  return 'Location(id: $id, partnerId: $partnerId, name: $name, address: $address, createdAt: $createdAt, updatedAt: $updatedAt, addressDetail: $addressDetail, sido: $sido, sigungu: $sigungu, geoPoint: $geoPoint)';
}


}

/// @nodoc
abstract mixin class _$LocationCopyWith<$Res> implements $LocationCopyWith<$Res> {
  factory _$LocationCopyWith(_Location value, $Res Function(_Location) _then) = __$LocationCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'partner_id') String partnerId, String name, String address,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'address_detail') String? addressDetail, String? sido, String? sigungu,@JsonKey(includeFromJson: false, includeToJson: false) dynamic geoPoint
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? partnerId = null,Object? name = null,Object? address = null,Object? createdAt = null,Object? updatedAt = null,Object? addressDetail = freezed,Object? sido = freezed,Object? sigungu = freezed,Object? geoPoint = freezed,}) {
  return _then(_Location(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,partnerId: null == partnerId ? _self.partnerId : partnerId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,addressDetail: freezed == addressDetail ? _self.addressDetail : addressDetail // ignore: cast_nullable_to_non_nullable
as String?,sido: freezed == sido ? _self.sido : sido // ignore: cast_nullable_to_non_nullable
as String?,sigungu: freezed == sigungu ? _self.sigungu : sigungu // ignore: cast_nullable_to_non_nullable
as String?,geoPoint: freezed == geoPoint ? _self.geoPoint : geoPoint // ignore: cast_nullable_to_non_nullable
as dynamic,
  ));
}


}


/// @nodoc
mixin _$Party {

 String get id;@JsonKey(name: 'partner_id') String get partnerId; String get title;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt; Map<String, dynamic>? get description;// Quill Delta JSON
@JsonKey(name: 'image_url') String? get imageUrl;@JsonKey(name: 'contact_phone') String? get contactPhone;@JsonKey(name: 'contact_email') String? get contactEmail;@JsonKey(name: 'required_verification_ids') List<String> get requiredVerificationIds; String get status;
/// Create a copy of Party
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PartyCopyWith<Party> get copyWith => _$PartyCopyWithImpl<Party>(this as Party, _$identity);

  /// Serializes this Party to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Party&&(identical(other.id, id) || other.id == id)&&(identical(other.partnerId, partnerId) || other.partnerId == partnerId)&&(identical(other.title, title) || other.title == title)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other.description, description)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.contactPhone, contactPhone) || other.contactPhone == contactPhone)&&(identical(other.contactEmail, contactEmail) || other.contactEmail == contactEmail)&&const DeepCollectionEquality().equals(other.requiredVerificationIds, requiredVerificationIds)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,partnerId,title,createdAt,updatedAt,const DeepCollectionEquality().hash(description),imageUrl,contactPhone,contactEmail,const DeepCollectionEquality().hash(requiredVerificationIds),status);

@override
String toString() {
  return 'Party(id: $id, partnerId: $partnerId, title: $title, createdAt: $createdAt, updatedAt: $updatedAt, description: $description, imageUrl: $imageUrl, contactPhone: $contactPhone, contactEmail: $contactEmail, requiredVerificationIds: $requiredVerificationIds, status: $status)';
}


}

/// @nodoc
abstract mixin class $PartyCopyWith<$Res>  {
  factory $PartyCopyWith(Party value, $Res Function(Party) _then) = _$PartyCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'partner_id') String partnerId, String title,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt, Map<String, dynamic>? description,@JsonKey(name: 'image_url') String? imageUrl,@JsonKey(name: 'contact_phone') String? contactPhone,@JsonKey(name: 'contact_email') String? contactEmail,@JsonKey(name: 'required_verification_ids') List<String> requiredVerificationIds, String status
});




}
/// @nodoc
class _$PartyCopyWithImpl<$Res>
    implements $PartyCopyWith<$Res> {
  _$PartyCopyWithImpl(this._self, this._then);

  final Party _self;
  final $Res Function(Party) _then;

/// Create a copy of Party
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? partnerId = null,Object? title = null,Object? createdAt = null,Object? updatedAt = null,Object? description = freezed,Object? imageUrl = freezed,Object? contactPhone = freezed,Object? contactEmail = freezed,Object? requiredVerificationIds = null,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,partnerId: null == partnerId ? _self.partnerId : partnerId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,contactPhone: freezed == contactPhone ? _self.contactPhone : contactPhone // ignore: cast_nullable_to_non_nullable
as String?,contactEmail: freezed == contactEmail ? _self.contactEmail : contactEmail // ignore: cast_nullable_to_non_nullable
as String?,requiredVerificationIds: null == requiredVerificationIds ? _self.requiredVerificationIds : requiredVerificationIds // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'partner_id')  String partnerId,  String title, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt,  Map<String, dynamic>? description, @JsonKey(name: 'image_url')  String? imageUrl, @JsonKey(name: 'contact_phone')  String? contactPhone, @JsonKey(name: 'contact_email')  String? contactEmail, @JsonKey(name: 'required_verification_ids')  List<String> requiredVerificationIds,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Party() when $default != null:
return $default(_that.id,_that.partnerId,_that.title,_that.createdAt,_that.updatedAt,_that.description,_that.imageUrl,_that.contactPhone,_that.contactEmail,_that.requiredVerificationIds,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'partner_id')  String partnerId,  String title, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt,  Map<String, dynamic>? description, @JsonKey(name: 'image_url')  String? imageUrl, @JsonKey(name: 'contact_phone')  String? contactPhone, @JsonKey(name: 'contact_email')  String? contactEmail, @JsonKey(name: 'required_verification_ids')  List<String> requiredVerificationIds,  String status)  $default,) {final _that = this;
switch (_that) {
case _Party():
return $default(_that.id,_that.partnerId,_that.title,_that.createdAt,_that.updatedAt,_that.description,_that.imageUrl,_that.contactPhone,_that.contactEmail,_that.requiredVerificationIds,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'partner_id')  String partnerId,  String title, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt,  Map<String, dynamic>? description, @JsonKey(name: 'image_url')  String? imageUrl, @JsonKey(name: 'contact_phone')  String? contactPhone, @JsonKey(name: 'contact_email')  String? contactEmail, @JsonKey(name: 'required_verification_ids')  List<String> requiredVerificationIds,  String status)?  $default,) {final _that = this;
switch (_that) {
case _Party() when $default != null:
return $default(_that.id,_that.partnerId,_that.title,_that.createdAt,_that.updatedAt,_that.description,_that.imageUrl,_that.contactPhone,_that.contactEmail,_that.requiredVerificationIds,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Party implements Party {
  const _Party({required this.id, @JsonKey(name: 'partner_id') required this.partnerId, required this.title, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt, final  Map<String, dynamic>? description, @JsonKey(name: 'image_url') this.imageUrl, @JsonKey(name: 'contact_phone') this.contactPhone, @JsonKey(name: 'contact_email') this.contactEmail, @JsonKey(name: 'required_verification_ids') final  List<String> requiredVerificationIds = const [], this.status = 'active'}): _description = description,_requiredVerificationIds = requiredVerificationIds;
  factory _Party.fromJson(Map<String, dynamic> json) => _$PartyFromJson(json);

@override final  String id;
@override@JsonKey(name: 'partner_id') final  String partnerId;
@override final  String title;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;
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
@override@JsonKey(name: 'contact_phone') final  String? contactPhone;
@override@JsonKey(name: 'contact_email') final  String? contactEmail;
 final  List<String> _requiredVerificationIds;
@override@JsonKey(name: 'required_verification_ids') List<String> get requiredVerificationIds {
  if (_requiredVerificationIds is EqualUnmodifiableListView) return _requiredVerificationIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_requiredVerificationIds);
}

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Party&&(identical(other.id, id) || other.id == id)&&(identical(other.partnerId, partnerId) || other.partnerId == partnerId)&&(identical(other.title, title) || other.title == title)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other._description, _description)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.contactPhone, contactPhone) || other.contactPhone == contactPhone)&&(identical(other.contactEmail, contactEmail) || other.contactEmail == contactEmail)&&const DeepCollectionEquality().equals(other._requiredVerificationIds, _requiredVerificationIds)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,partnerId,title,createdAt,updatedAt,const DeepCollectionEquality().hash(_description),imageUrl,contactPhone,contactEmail,const DeepCollectionEquality().hash(_requiredVerificationIds),status);

@override
String toString() {
  return 'Party(id: $id, partnerId: $partnerId, title: $title, createdAt: $createdAt, updatedAt: $updatedAt, description: $description, imageUrl: $imageUrl, contactPhone: $contactPhone, contactEmail: $contactEmail, requiredVerificationIds: $requiredVerificationIds, status: $status)';
}


}

/// @nodoc
abstract mixin class _$PartyCopyWith<$Res> implements $PartyCopyWith<$Res> {
  factory _$PartyCopyWith(_Party value, $Res Function(_Party) _then) = __$PartyCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'partner_id') String partnerId, String title,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt, Map<String, dynamic>? description,@JsonKey(name: 'image_url') String? imageUrl,@JsonKey(name: 'contact_phone') String? contactPhone,@JsonKey(name: 'contact_email') String? contactEmail,@JsonKey(name: 'required_verification_ids') List<String> requiredVerificationIds, String status
});




}
/// @nodoc
class __$PartyCopyWithImpl<$Res>
    implements _$PartyCopyWith<$Res> {
  __$PartyCopyWithImpl(this._self, this._then);

  final _Party _self;
  final $Res Function(_Party) _then;

/// Create a copy of Party
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? partnerId = null,Object? title = null,Object? createdAt = null,Object? updatedAt = null,Object? description = freezed,Object? imageUrl = freezed,Object? contactPhone = freezed,Object? contactEmail = freezed,Object? requiredVerificationIds = null,Object? status = null,}) {
  return _then(_Party(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,partnerId: null == partnerId ? _self.partnerId : partnerId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,description: freezed == description ? _self._description : description // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,contactPhone: freezed == contactPhone ? _self.contactPhone : contactPhone // ignore: cast_nullable_to_non_nullable
as String?,contactEmail: freezed == contactEmail ? _self.contactEmail : contactEmail // ignore: cast_nullable_to_non_nullable
as String?,requiredVerificationIds: null == requiredVerificationIds ? _self._requiredVerificationIds : requiredVerificationIds // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
