// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'partner_application.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PartnerApplication {

 String get id;@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'brand_name') String get brandName; String get introduction; String get address;@JsonKey(name: 'contact_phone') String get contactPhone;@JsonKey(name: 'contact_email') String get contactEmail;@JsonKey(name: 'biz_type') String get bizType;@JsonKey(name: 'biz_name') String get bizName;@JsonKey(name: 'biz_number') String get bizNumber;@JsonKey(name: 'representative_name') String get representativeName;@JsonKey(name: 'bank_name') String get bankName;@JsonKey(name: 'account_number') String get accountNumber;@JsonKey(name: 'account_holder') String get accountHolder;@JsonKey(name: 'biz_registration_path') String get bizRegistrationPath;@JsonKey(name: 'bankbook_path') String get bankbookPath; String get status;@JsonKey(name: 'admin_comment') String? get adminComment;@JsonKey(name: 'created_at') String? get createdAt;@JsonKey(name: 'updated_at') String? get updatedAt;
/// Create a copy of PartnerApplication
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PartnerApplicationCopyWith<PartnerApplication> get copyWith => _$PartnerApplicationCopyWithImpl<PartnerApplication>(this as PartnerApplication, _$identity);

  /// Serializes this PartnerApplication to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PartnerApplication&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.brandName, brandName) || other.brandName == brandName)&&(identical(other.introduction, introduction) || other.introduction == introduction)&&(identical(other.address, address) || other.address == address)&&(identical(other.contactPhone, contactPhone) || other.contactPhone == contactPhone)&&(identical(other.contactEmail, contactEmail) || other.contactEmail == contactEmail)&&(identical(other.bizType, bizType) || other.bizType == bizType)&&(identical(other.bizName, bizName) || other.bizName == bizName)&&(identical(other.bizNumber, bizNumber) || other.bizNumber == bizNumber)&&(identical(other.representativeName, representativeName) || other.representativeName == representativeName)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.accountNumber, accountNumber) || other.accountNumber == accountNumber)&&(identical(other.accountHolder, accountHolder) || other.accountHolder == accountHolder)&&(identical(other.bizRegistrationPath, bizRegistrationPath) || other.bizRegistrationPath == bizRegistrationPath)&&(identical(other.bankbookPath, bankbookPath) || other.bankbookPath == bankbookPath)&&(identical(other.status, status) || other.status == status)&&(identical(other.adminComment, adminComment) || other.adminComment == adminComment)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,userId,brandName,introduction,address,contactPhone,contactEmail,bizType,bizName,bizNumber,representativeName,bankName,accountNumber,accountHolder,bizRegistrationPath,bankbookPath,status,adminComment,createdAt,updatedAt]);

@override
String toString() {
  return 'PartnerApplication(id: $id, userId: $userId, brandName: $brandName, introduction: $introduction, address: $address, contactPhone: $contactPhone, contactEmail: $contactEmail, bizType: $bizType, bizName: $bizName, bizNumber: $bizNumber, representativeName: $representativeName, bankName: $bankName, accountNumber: $accountNumber, accountHolder: $accountHolder, bizRegistrationPath: $bizRegistrationPath, bankbookPath: $bankbookPath, status: $status, adminComment: $adminComment, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $PartnerApplicationCopyWith<$Res>  {
  factory $PartnerApplicationCopyWith(PartnerApplication value, $Res Function(PartnerApplication) _then) = _$PartnerApplicationCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'brand_name') String brandName, String introduction, String address,@JsonKey(name: 'contact_phone') String contactPhone,@JsonKey(name: 'contact_email') String contactEmail,@JsonKey(name: 'biz_type') String bizType,@JsonKey(name: 'biz_name') String bizName,@JsonKey(name: 'biz_number') String bizNumber,@JsonKey(name: 'representative_name') String representativeName,@JsonKey(name: 'bank_name') String bankName,@JsonKey(name: 'account_number') String accountNumber,@JsonKey(name: 'account_holder') String accountHolder,@JsonKey(name: 'biz_registration_path') String bizRegistrationPath,@JsonKey(name: 'bankbook_path') String bankbookPath, String status,@JsonKey(name: 'admin_comment') String? adminComment,@JsonKey(name: 'created_at') String? createdAt,@JsonKey(name: 'updated_at') String? updatedAt
});




}
/// @nodoc
class _$PartnerApplicationCopyWithImpl<$Res>
    implements $PartnerApplicationCopyWith<$Res> {
  _$PartnerApplicationCopyWithImpl(this._self, this._then);

  final PartnerApplication _self;
  final $Res Function(PartnerApplication) _then;

/// Create a copy of PartnerApplication
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? brandName = null,Object? introduction = null,Object? address = null,Object? contactPhone = null,Object? contactEmail = null,Object? bizType = null,Object? bizName = null,Object? bizNumber = null,Object? representativeName = null,Object? bankName = null,Object? accountNumber = null,Object? accountHolder = null,Object? bizRegistrationPath = null,Object? bankbookPath = null,Object? status = null,Object? adminComment = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,brandName: null == brandName ? _self.brandName : brandName // ignore: cast_nullable_to_non_nullable
as String,introduction: null == introduction ? _self.introduction : introduction // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,contactPhone: null == contactPhone ? _self.contactPhone : contactPhone // ignore: cast_nullable_to_non_nullable
as String,contactEmail: null == contactEmail ? _self.contactEmail : contactEmail // ignore: cast_nullable_to_non_nullable
as String,bizType: null == bizType ? _self.bizType : bizType // ignore: cast_nullable_to_non_nullable
as String,bizName: null == bizName ? _self.bizName : bizName // ignore: cast_nullable_to_non_nullable
as String,bizNumber: null == bizNumber ? _self.bizNumber : bizNumber // ignore: cast_nullable_to_non_nullable
as String,representativeName: null == representativeName ? _self.representativeName : representativeName // ignore: cast_nullable_to_non_nullable
as String,bankName: null == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String,accountNumber: null == accountNumber ? _self.accountNumber : accountNumber // ignore: cast_nullable_to_non_nullable
as String,accountHolder: null == accountHolder ? _self.accountHolder : accountHolder // ignore: cast_nullable_to_non_nullable
as String,bizRegistrationPath: null == bizRegistrationPath ? _self.bizRegistrationPath : bizRegistrationPath // ignore: cast_nullable_to_non_nullable
as String,bankbookPath: null == bankbookPath ? _self.bankbookPath : bankbookPath // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,adminComment: freezed == adminComment ? _self.adminComment : adminComment // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PartnerApplication].
extension PartnerApplicationPatterns on PartnerApplication {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PartnerApplication value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PartnerApplication() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PartnerApplication value)  $default,){
final _that = this;
switch (_that) {
case _PartnerApplication():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PartnerApplication value)?  $default,){
final _that = this;
switch (_that) {
case _PartnerApplication() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'brand_name')  String brandName,  String introduction,  String address, @JsonKey(name: 'contact_phone')  String contactPhone, @JsonKey(name: 'contact_email')  String contactEmail, @JsonKey(name: 'biz_type')  String bizType, @JsonKey(name: 'biz_name')  String bizName, @JsonKey(name: 'biz_number')  String bizNumber, @JsonKey(name: 'representative_name')  String representativeName, @JsonKey(name: 'bank_name')  String bankName, @JsonKey(name: 'account_number')  String accountNumber, @JsonKey(name: 'account_holder')  String accountHolder, @JsonKey(name: 'biz_registration_path')  String bizRegistrationPath, @JsonKey(name: 'bankbook_path')  String bankbookPath,  String status, @JsonKey(name: 'admin_comment')  String? adminComment, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'updated_at')  String? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PartnerApplication() when $default != null:
return $default(_that.id,_that.userId,_that.brandName,_that.introduction,_that.address,_that.contactPhone,_that.contactEmail,_that.bizType,_that.bizName,_that.bizNumber,_that.representativeName,_that.bankName,_that.accountNumber,_that.accountHolder,_that.bizRegistrationPath,_that.bankbookPath,_that.status,_that.adminComment,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'brand_name')  String brandName,  String introduction,  String address, @JsonKey(name: 'contact_phone')  String contactPhone, @JsonKey(name: 'contact_email')  String contactEmail, @JsonKey(name: 'biz_type')  String bizType, @JsonKey(name: 'biz_name')  String bizName, @JsonKey(name: 'biz_number')  String bizNumber, @JsonKey(name: 'representative_name')  String representativeName, @JsonKey(name: 'bank_name')  String bankName, @JsonKey(name: 'account_number')  String accountNumber, @JsonKey(name: 'account_holder')  String accountHolder, @JsonKey(name: 'biz_registration_path')  String bizRegistrationPath, @JsonKey(name: 'bankbook_path')  String bankbookPath,  String status, @JsonKey(name: 'admin_comment')  String? adminComment, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'updated_at')  String? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _PartnerApplication():
return $default(_that.id,_that.userId,_that.brandName,_that.introduction,_that.address,_that.contactPhone,_that.contactEmail,_that.bizType,_that.bizName,_that.bizNumber,_that.representativeName,_that.bankName,_that.accountNumber,_that.accountHolder,_that.bizRegistrationPath,_that.bankbookPath,_that.status,_that.adminComment,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'brand_name')  String brandName,  String introduction,  String address, @JsonKey(name: 'contact_phone')  String contactPhone, @JsonKey(name: 'contact_email')  String contactEmail, @JsonKey(name: 'biz_type')  String bizType, @JsonKey(name: 'biz_name')  String bizName, @JsonKey(name: 'biz_number')  String bizNumber, @JsonKey(name: 'representative_name')  String representativeName, @JsonKey(name: 'bank_name')  String bankName, @JsonKey(name: 'account_number')  String accountNumber, @JsonKey(name: 'account_holder')  String accountHolder, @JsonKey(name: 'biz_registration_path')  String bizRegistrationPath, @JsonKey(name: 'bankbook_path')  String bankbookPath,  String status, @JsonKey(name: 'admin_comment')  String? adminComment, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'updated_at')  String? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _PartnerApplication() when $default != null:
return $default(_that.id,_that.userId,_that.brandName,_that.introduction,_that.address,_that.contactPhone,_that.contactEmail,_that.bizType,_that.bizName,_that.bizNumber,_that.representativeName,_that.bankName,_that.accountNumber,_that.accountHolder,_that.bizRegistrationPath,_that.bankbookPath,_that.status,_that.adminComment,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PartnerApplication implements PartnerApplication {
  const _PartnerApplication({required this.id, @JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'brand_name') required this.brandName, required this.introduction, required this.address, @JsonKey(name: 'contact_phone') required this.contactPhone, @JsonKey(name: 'contact_email') required this.contactEmail, @JsonKey(name: 'biz_type') required this.bizType, @JsonKey(name: 'biz_name') required this.bizName, @JsonKey(name: 'biz_number') required this.bizNumber, @JsonKey(name: 'representative_name') required this.representativeName, @JsonKey(name: 'bank_name') required this.bankName, @JsonKey(name: 'account_number') required this.accountNumber, @JsonKey(name: 'account_holder') required this.accountHolder, @JsonKey(name: 'biz_registration_path') required this.bizRegistrationPath, @JsonKey(name: 'bankbook_path') required this.bankbookPath, this.status = 'pending', @JsonKey(name: 'admin_comment') this.adminComment, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt});
  factory _PartnerApplication.fromJson(Map<String, dynamic> json) => _$PartnerApplicationFromJson(json);

@override final  String id;
@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'brand_name') final  String brandName;
@override final  String introduction;
@override final  String address;
@override@JsonKey(name: 'contact_phone') final  String contactPhone;
@override@JsonKey(name: 'contact_email') final  String contactEmail;
@override@JsonKey(name: 'biz_type') final  String bizType;
@override@JsonKey(name: 'biz_name') final  String bizName;
@override@JsonKey(name: 'biz_number') final  String bizNumber;
@override@JsonKey(name: 'representative_name') final  String representativeName;
@override@JsonKey(name: 'bank_name') final  String bankName;
@override@JsonKey(name: 'account_number') final  String accountNumber;
@override@JsonKey(name: 'account_holder') final  String accountHolder;
@override@JsonKey(name: 'biz_registration_path') final  String bizRegistrationPath;
@override@JsonKey(name: 'bankbook_path') final  String bankbookPath;
@override@JsonKey() final  String status;
@override@JsonKey(name: 'admin_comment') final  String? adminComment;
@override@JsonKey(name: 'created_at') final  String? createdAt;
@override@JsonKey(name: 'updated_at') final  String? updatedAt;

/// Create a copy of PartnerApplication
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PartnerApplicationCopyWith<_PartnerApplication> get copyWith => __$PartnerApplicationCopyWithImpl<_PartnerApplication>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PartnerApplicationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PartnerApplication&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.brandName, brandName) || other.brandName == brandName)&&(identical(other.introduction, introduction) || other.introduction == introduction)&&(identical(other.address, address) || other.address == address)&&(identical(other.contactPhone, contactPhone) || other.contactPhone == contactPhone)&&(identical(other.contactEmail, contactEmail) || other.contactEmail == contactEmail)&&(identical(other.bizType, bizType) || other.bizType == bizType)&&(identical(other.bizName, bizName) || other.bizName == bizName)&&(identical(other.bizNumber, bizNumber) || other.bizNumber == bizNumber)&&(identical(other.representativeName, representativeName) || other.representativeName == representativeName)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.accountNumber, accountNumber) || other.accountNumber == accountNumber)&&(identical(other.accountHolder, accountHolder) || other.accountHolder == accountHolder)&&(identical(other.bizRegistrationPath, bizRegistrationPath) || other.bizRegistrationPath == bizRegistrationPath)&&(identical(other.bankbookPath, bankbookPath) || other.bankbookPath == bankbookPath)&&(identical(other.status, status) || other.status == status)&&(identical(other.adminComment, adminComment) || other.adminComment == adminComment)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,userId,brandName,introduction,address,contactPhone,contactEmail,bizType,bizName,bizNumber,representativeName,bankName,accountNumber,accountHolder,bizRegistrationPath,bankbookPath,status,adminComment,createdAt,updatedAt]);

@override
String toString() {
  return 'PartnerApplication(id: $id, userId: $userId, brandName: $brandName, introduction: $introduction, address: $address, contactPhone: $contactPhone, contactEmail: $contactEmail, bizType: $bizType, bizName: $bizName, bizNumber: $bizNumber, representativeName: $representativeName, bankName: $bankName, accountNumber: $accountNumber, accountHolder: $accountHolder, bizRegistrationPath: $bizRegistrationPath, bankbookPath: $bankbookPath, status: $status, adminComment: $adminComment, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PartnerApplicationCopyWith<$Res> implements $PartnerApplicationCopyWith<$Res> {
  factory _$PartnerApplicationCopyWith(_PartnerApplication value, $Res Function(_PartnerApplication) _then) = __$PartnerApplicationCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'brand_name') String brandName, String introduction, String address,@JsonKey(name: 'contact_phone') String contactPhone,@JsonKey(name: 'contact_email') String contactEmail,@JsonKey(name: 'biz_type') String bizType,@JsonKey(name: 'biz_name') String bizName,@JsonKey(name: 'biz_number') String bizNumber,@JsonKey(name: 'representative_name') String representativeName,@JsonKey(name: 'bank_name') String bankName,@JsonKey(name: 'account_number') String accountNumber,@JsonKey(name: 'account_holder') String accountHolder,@JsonKey(name: 'biz_registration_path') String bizRegistrationPath,@JsonKey(name: 'bankbook_path') String bankbookPath, String status,@JsonKey(name: 'admin_comment') String? adminComment,@JsonKey(name: 'created_at') String? createdAt,@JsonKey(name: 'updated_at') String? updatedAt
});




}
/// @nodoc
class __$PartnerApplicationCopyWithImpl<$Res>
    implements _$PartnerApplicationCopyWith<$Res> {
  __$PartnerApplicationCopyWithImpl(this._self, this._then);

  final _PartnerApplication _self;
  final $Res Function(_PartnerApplication) _then;

/// Create a copy of PartnerApplication
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? brandName = null,Object? introduction = null,Object? address = null,Object? contactPhone = null,Object? contactEmail = null,Object? bizType = null,Object? bizName = null,Object? bizNumber = null,Object? representativeName = null,Object? bankName = null,Object? accountNumber = null,Object? accountHolder = null,Object? bizRegistrationPath = null,Object? bankbookPath = null,Object? status = null,Object? adminComment = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_PartnerApplication(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,brandName: null == brandName ? _self.brandName : brandName // ignore: cast_nullable_to_non_nullable
as String,introduction: null == introduction ? _self.introduction : introduction // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,contactPhone: null == contactPhone ? _self.contactPhone : contactPhone // ignore: cast_nullable_to_non_nullable
as String,contactEmail: null == contactEmail ? _self.contactEmail : contactEmail // ignore: cast_nullable_to_non_nullable
as String,bizType: null == bizType ? _self.bizType : bizType // ignore: cast_nullable_to_non_nullable
as String,bizName: null == bizName ? _self.bizName : bizName // ignore: cast_nullable_to_non_nullable
as String,bizNumber: null == bizNumber ? _self.bizNumber : bizNumber // ignore: cast_nullable_to_non_nullable
as String,representativeName: null == representativeName ? _self.representativeName : representativeName // ignore: cast_nullable_to_non_nullable
as String,bankName: null == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String,accountNumber: null == accountNumber ? _self.accountNumber : accountNumber // ignore: cast_nullable_to_non_nullable
as String,accountHolder: null == accountHolder ? _self.accountHolder : accountHolder // ignore: cast_nullable_to_non_nullable
as String,bizRegistrationPath: null == bizRegistrationPath ? _self.bizRegistrationPath : bizRegistrationPath // ignore: cast_nullable_to_non_nullable
as String,bankbookPath: null == bankbookPath ? _self.bankbookPath : bankbookPath // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,adminComment: freezed == adminComment ? _self.adminComment : adminComment // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
