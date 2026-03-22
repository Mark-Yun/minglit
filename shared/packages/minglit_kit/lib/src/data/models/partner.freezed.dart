// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'partner.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Partner {

 String get id; String get name; String? get introduction; String? get address;@JsonKey(name: 'contact_phone') String? get contactPhone;@JsonKey(name: 'contact_email') String? get contactEmail;@JsonKey(name: 'representative_name') String? get representativeName;@JsonKey(name: 'biz_name') String? get bizName;@JsonKey(name: 'biz_number') String? get bizNumber;@JsonKey(name: 'profile_image_url') String? get profileImageUrl;@JsonKey(name: 'is_active') bool get isActive;
/// Create a copy of Partner
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PartnerCopyWith<Partner> get copyWith => _$PartnerCopyWithImpl<Partner>(this as Partner, _$identity);

  /// Serializes this Partner to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Partner&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.introduction, introduction) || other.introduction == introduction)&&(identical(other.address, address) || other.address == address)&&(identical(other.contactPhone, contactPhone) || other.contactPhone == contactPhone)&&(identical(other.contactEmail, contactEmail) || other.contactEmail == contactEmail)&&(identical(other.representativeName, representativeName) || other.representativeName == representativeName)&&(identical(other.bizName, bizName) || other.bizName == bizName)&&(identical(other.bizNumber, bizNumber) || other.bizNumber == bizNumber)&&(identical(other.profileImageUrl, profileImageUrl) || other.profileImageUrl == profileImageUrl)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,introduction,address,contactPhone,contactEmail,representativeName,bizName,bizNumber,profileImageUrl,isActive);

@override
String toString() {
  return 'Partner(id: $id, name: $name, introduction: $introduction, address: $address, contactPhone: $contactPhone, contactEmail: $contactEmail, representativeName: $representativeName, bizName: $bizName, bizNumber: $bizNumber, profileImageUrl: $profileImageUrl, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class $PartnerCopyWith<$Res>  {
  factory $PartnerCopyWith(Partner value, $Res Function(Partner) _then) = _$PartnerCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? introduction, String? address,@JsonKey(name: 'contact_phone') String? contactPhone,@JsonKey(name: 'contact_email') String? contactEmail,@JsonKey(name: 'representative_name') String? representativeName,@JsonKey(name: 'biz_name') String? bizName,@JsonKey(name: 'biz_number') String? bizNumber,@JsonKey(name: 'profile_image_url') String? profileImageUrl,@JsonKey(name: 'is_active') bool isActive
});




}
/// @nodoc
class _$PartnerCopyWithImpl<$Res>
    implements $PartnerCopyWith<$Res> {
  _$PartnerCopyWithImpl(this._self, this._then);

  final Partner _self;
  final $Res Function(Partner) _then;

/// Create a copy of Partner
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? introduction = freezed,Object? address = freezed,Object? contactPhone = freezed,Object? contactEmail = freezed,Object? representativeName = freezed,Object? bizName = freezed,Object? bizNumber = freezed,Object? profileImageUrl = freezed,Object? isActive = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,introduction: freezed == introduction ? _self.introduction : introduction // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,contactPhone: freezed == contactPhone ? _self.contactPhone : contactPhone // ignore: cast_nullable_to_non_nullable
as String?,contactEmail: freezed == contactEmail ? _self.contactEmail : contactEmail // ignore: cast_nullable_to_non_nullable
as String?,representativeName: freezed == representativeName ? _self.representativeName : representativeName // ignore: cast_nullable_to_non_nullable
as String?,bizName: freezed == bizName ? _self.bizName : bizName // ignore: cast_nullable_to_non_nullable
as String?,bizNumber: freezed == bizNumber ? _self.bizNumber : bizNumber // ignore: cast_nullable_to_non_nullable
as String?,profileImageUrl: freezed == profileImageUrl ? _self.profileImageUrl : profileImageUrl // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Partner].
extension PartnerPatterns on Partner {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Partner value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Partner() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Partner value)  $default,){
final _that = this;
switch (_that) {
case _Partner():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Partner value)?  $default,){
final _that = this;
switch (_that) {
case _Partner() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? introduction,  String? address, @JsonKey(name: 'contact_phone')  String? contactPhone, @JsonKey(name: 'contact_email')  String? contactEmail, @JsonKey(name: 'representative_name')  String? representativeName, @JsonKey(name: 'biz_name')  String? bizName, @JsonKey(name: 'biz_number')  String? bizNumber, @JsonKey(name: 'profile_image_url')  String? profileImageUrl, @JsonKey(name: 'is_active')  bool isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Partner() when $default != null:
return $default(_that.id,_that.name,_that.introduction,_that.address,_that.contactPhone,_that.contactEmail,_that.representativeName,_that.bizName,_that.bizNumber,_that.profileImageUrl,_that.isActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? introduction,  String? address, @JsonKey(name: 'contact_phone')  String? contactPhone, @JsonKey(name: 'contact_email')  String? contactEmail, @JsonKey(name: 'representative_name')  String? representativeName, @JsonKey(name: 'biz_name')  String? bizName, @JsonKey(name: 'biz_number')  String? bizNumber, @JsonKey(name: 'profile_image_url')  String? profileImageUrl, @JsonKey(name: 'is_active')  bool isActive)  $default,) {final _that = this;
switch (_that) {
case _Partner():
return $default(_that.id,_that.name,_that.introduction,_that.address,_that.contactPhone,_that.contactEmail,_that.representativeName,_that.bizName,_that.bizNumber,_that.profileImageUrl,_that.isActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? introduction,  String? address, @JsonKey(name: 'contact_phone')  String? contactPhone, @JsonKey(name: 'contact_email')  String? contactEmail, @JsonKey(name: 'representative_name')  String? representativeName, @JsonKey(name: 'biz_name')  String? bizName, @JsonKey(name: 'biz_number')  String? bizNumber, @JsonKey(name: 'profile_image_url')  String? profileImageUrl, @JsonKey(name: 'is_active')  bool isActive)?  $default,) {final _that = this;
switch (_that) {
case _Partner() when $default != null:
return $default(_that.id,_that.name,_that.introduction,_that.address,_that.contactPhone,_that.contactEmail,_that.representativeName,_that.bizName,_that.bizNumber,_that.profileImageUrl,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Partner implements Partner {
  const _Partner({required this.id, required this.name, this.introduction, this.address, @JsonKey(name: 'contact_phone') this.contactPhone, @JsonKey(name: 'contact_email') this.contactEmail, @JsonKey(name: 'representative_name') this.representativeName, @JsonKey(name: 'biz_name') this.bizName, @JsonKey(name: 'biz_number') this.bizNumber, @JsonKey(name: 'profile_image_url') this.profileImageUrl, @JsonKey(name: 'is_active') this.isActive = true});
  factory _Partner.fromJson(Map<String, dynamic> json) => _$PartnerFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? introduction;
@override final  String? address;
@override@JsonKey(name: 'contact_phone') final  String? contactPhone;
@override@JsonKey(name: 'contact_email') final  String? contactEmail;
@override@JsonKey(name: 'representative_name') final  String? representativeName;
@override@JsonKey(name: 'biz_name') final  String? bizName;
@override@JsonKey(name: 'biz_number') final  String? bizNumber;
@override@JsonKey(name: 'profile_image_url') final  String? profileImageUrl;
@override@JsonKey(name: 'is_active') final  bool isActive;

/// Create a copy of Partner
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PartnerCopyWith<_Partner> get copyWith => __$PartnerCopyWithImpl<_Partner>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PartnerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Partner&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.introduction, introduction) || other.introduction == introduction)&&(identical(other.address, address) || other.address == address)&&(identical(other.contactPhone, contactPhone) || other.contactPhone == contactPhone)&&(identical(other.contactEmail, contactEmail) || other.contactEmail == contactEmail)&&(identical(other.representativeName, representativeName) || other.representativeName == representativeName)&&(identical(other.bizName, bizName) || other.bizName == bizName)&&(identical(other.bizNumber, bizNumber) || other.bizNumber == bizNumber)&&(identical(other.profileImageUrl, profileImageUrl) || other.profileImageUrl == profileImageUrl)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,introduction,address,contactPhone,contactEmail,representativeName,bizName,bizNumber,profileImageUrl,isActive);

@override
String toString() {
  return 'Partner(id: $id, name: $name, introduction: $introduction, address: $address, contactPhone: $contactPhone, contactEmail: $contactEmail, representativeName: $representativeName, bizName: $bizName, bizNumber: $bizNumber, profileImageUrl: $profileImageUrl, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$PartnerCopyWith<$Res> implements $PartnerCopyWith<$Res> {
  factory _$PartnerCopyWith(_Partner value, $Res Function(_Partner) _then) = __$PartnerCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? introduction, String? address,@JsonKey(name: 'contact_phone') String? contactPhone,@JsonKey(name: 'contact_email') String? contactEmail,@JsonKey(name: 'representative_name') String? representativeName,@JsonKey(name: 'biz_name') String? bizName,@JsonKey(name: 'biz_number') String? bizNumber,@JsonKey(name: 'profile_image_url') String? profileImageUrl,@JsonKey(name: 'is_active') bool isActive
});




}
/// @nodoc
class __$PartnerCopyWithImpl<$Res>
    implements _$PartnerCopyWith<$Res> {
  __$PartnerCopyWithImpl(this._self, this._then);

  final _Partner _self;
  final $Res Function(_Partner) _then;

/// Create a copy of Partner
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? introduction = freezed,Object? address = freezed,Object? contactPhone = freezed,Object? contactEmail = freezed,Object? representativeName = freezed,Object? bizName = freezed,Object? bizNumber = freezed,Object? profileImageUrl = freezed,Object? isActive = null,}) {
  return _then(_Partner(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,introduction: freezed == introduction ? _self.introduction : introduction // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,contactPhone: freezed == contactPhone ? _self.contactPhone : contactPhone // ignore: cast_nullable_to_non_nullable
as String?,contactEmail: freezed == contactEmail ? _self.contactEmail : contactEmail // ignore: cast_nullable_to_non_nullable
as String?,representativeName: freezed == representativeName ? _self.representativeName : representativeName // ignore: cast_nullable_to_non_nullable
as String?,bizName: freezed == bizName ? _self.bizName : bizName // ignore: cast_nullable_to_non_nullable
as String?,bizNumber: freezed == bizNumber ? _self.bizNumber : bizNumber // ignore: cast_nullable_to_non_nullable
as String?,profileImageUrl: freezed == profileImageUrl ? _self.profileImageUrl : profileImageUrl // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
