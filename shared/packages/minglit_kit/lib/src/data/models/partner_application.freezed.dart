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

 String get id;@JsonKey(name: 'user_id') String get userId; String get status;@JsonKey(name: 'brand_name') String? get brandName; String? get introduction; String? get address;@JsonKey(name: 'contact_phone') String? get contactPhone;@JsonKey(name: 'contact_email') String? get contactEmail;@JsonKey(name: 'biz_type') String? get bizType;@JsonKey(name: 'biz_name') String? get bizName;@JsonKey(name: 'biz_number') String? get bizNumber;@JsonKey(name: 'representative_name') String? get representativeName;@JsonKey(name: 'bank_name') String? get bankName;@JsonKey(name: 'account_number') String? get accountNumber;@JsonKey(name: 'account_holder') String? get accountHolder;@JsonKey(name: 'biz_registration_path') String? get bizRegistrationPath;@JsonKey(name: 'bankbook_path') String? get bankbookPath;@JsonKey(name: 'tax_email') String? get taxEmail;@JsonKey(name: 'profile_image_path') String? get profileImagePath;@JsonKey(name: 'current_step') int get currentStep;@JsonKey(name: 'admin_comment') String? get adminComment;@JsonKey(name: 'created_at') String? get createdAt;@JsonKey(name: 'updated_at') String? get updatedAt;
/// Create a copy of PartnerApplication
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PartnerApplicationCopyWith<PartnerApplication> get copyWith => _$PartnerApplicationCopyWithImpl<PartnerApplication>(this as PartnerApplication, _$identity);

  /// Serializes this PartnerApplication to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PartnerApplication&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.status, status) || other.status == status)&&(identical(other.brandName, brandName) || other.brandName == brandName)&&(identical(other.introduction, introduction) || other.introduction == introduction)&&(identical(other.address, address) || other.address == address)&&(identical(other.contactPhone, contactPhone) || other.contactPhone == contactPhone)&&(identical(other.contactEmail, contactEmail) || other.contactEmail == contactEmail)&&(identical(other.bizType, bizType) || other.bizType == bizType)&&(identical(other.bizName, bizName) || other.bizName == bizName)&&(identical(other.bizNumber, bizNumber) || other.bizNumber == bizNumber)&&(identical(other.representativeName, representativeName) || other.representativeName == representativeName)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.accountNumber, accountNumber) || other.accountNumber == accountNumber)&&(identical(other.accountHolder, accountHolder) || other.accountHolder == accountHolder)&&(identical(other.bizRegistrationPath, bizRegistrationPath) || other.bizRegistrationPath == bizRegistrationPath)&&(identical(other.bankbookPath, bankbookPath) || other.bankbookPath == bankbookPath)&&(identical(other.taxEmail, taxEmail) || other.taxEmail == taxEmail)&&(identical(other.profileImagePath, profileImagePath) || other.profileImagePath == profileImagePath)&&(identical(other.currentStep, currentStep) || other.currentStep == currentStep)&&(identical(other.adminComment, adminComment) || other.adminComment == adminComment)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,userId,status,brandName,introduction,address,contactPhone,contactEmail,bizType,bizName,bizNumber,representativeName,bankName,accountNumber,accountHolder,bizRegistrationPath,bankbookPath,taxEmail,profileImagePath,currentStep,adminComment,createdAt,updatedAt]);

@override
String toString() {
  return 'PartnerApplication(id: $id, userId: $userId, status: $status, brandName: $brandName, introduction: $introduction, address: $address, contactPhone: $contactPhone, contactEmail: $contactEmail, bizType: $bizType, bizName: $bizName, bizNumber: $bizNumber, representativeName: $representativeName, bankName: $bankName, accountNumber: $accountNumber, accountHolder: $accountHolder, bizRegistrationPath: $bizRegistrationPath, bankbookPath: $bankbookPath, taxEmail: $taxEmail, profileImagePath: $profileImagePath, currentStep: $currentStep, adminComment: $adminComment, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $PartnerApplicationCopyWith<$Res>  {
  factory $PartnerApplicationCopyWith(PartnerApplication value, $Res Function(PartnerApplication) _then) = _$PartnerApplicationCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId, String status,@JsonKey(name: 'brand_name') String? brandName, String? introduction, String? address,@JsonKey(name: 'contact_phone') String? contactPhone,@JsonKey(name: 'contact_email') String? contactEmail,@JsonKey(name: 'biz_type') String? bizType,@JsonKey(name: 'biz_name') String? bizName,@JsonKey(name: 'biz_number') String? bizNumber,@JsonKey(name: 'representative_name') String? representativeName,@JsonKey(name: 'bank_name') String? bankName,@JsonKey(name: 'account_number') String? accountNumber,@JsonKey(name: 'account_holder') String? accountHolder,@JsonKey(name: 'biz_registration_path') String? bizRegistrationPath,@JsonKey(name: 'bankbook_path') String? bankbookPath,@JsonKey(name: 'tax_email') String? taxEmail,@JsonKey(name: 'profile_image_path') String? profileImagePath,@JsonKey(name: 'current_step') int currentStep,@JsonKey(name: 'admin_comment') String? adminComment,@JsonKey(name: 'created_at') String? createdAt,@JsonKey(name: 'updated_at') String? updatedAt
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? status = null,Object? brandName = freezed,Object? introduction = freezed,Object? address = freezed,Object? contactPhone = freezed,Object? contactEmail = freezed,Object? bizType = freezed,Object? bizName = freezed,Object? bizNumber = freezed,Object? representativeName = freezed,Object? bankName = freezed,Object? accountNumber = freezed,Object? accountHolder = freezed,Object? bizRegistrationPath = freezed,Object? bankbookPath = freezed,Object? taxEmail = freezed,Object? profileImagePath = freezed,Object? currentStep = null,Object? adminComment = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,brandName: freezed == brandName ? _self.brandName : brandName // ignore: cast_nullable_to_non_nullable
as String?,introduction: freezed == introduction ? _self.introduction : introduction // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,contactPhone: freezed == contactPhone ? _self.contactPhone : contactPhone // ignore: cast_nullable_to_non_nullable
as String?,contactEmail: freezed == contactEmail ? _self.contactEmail : contactEmail // ignore: cast_nullable_to_non_nullable
as String?,bizType: freezed == bizType ? _self.bizType : bizType // ignore: cast_nullable_to_non_nullable
as String?,bizName: freezed == bizName ? _self.bizName : bizName // ignore: cast_nullable_to_non_nullable
as String?,bizNumber: freezed == bizNumber ? _self.bizNumber : bizNumber // ignore: cast_nullable_to_non_nullable
as String?,representativeName: freezed == representativeName ? _self.representativeName : representativeName // ignore: cast_nullable_to_non_nullable
as String?,bankName: freezed == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String?,accountNumber: freezed == accountNumber ? _self.accountNumber : accountNumber // ignore: cast_nullable_to_non_nullable
as String?,accountHolder: freezed == accountHolder ? _self.accountHolder : accountHolder // ignore: cast_nullable_to_non_nullable
as String?,bizRegistrationPath: freezed == bizRegistrationPath ? _self.bizRegistrationPath : bizRegistrationPath // ignore: cast_nullable_to_non_nullable
as String?,bankbookPath: freezed == bankbookPath ? _self.bankbookPath : bankbookPath // ignore: cast_nullable_to_non_nullable
as String?,taxEmail: freezed == taxEmail ? _self.taxEmail : taxEmail // ignore: cast_nullable_to_non_nullable
as String?,profileImagePath: freezed == profileImagePath ? _self.profileImagePath : profileImagePath // ignore: cast_nullable_to_non_nullable
as String?,currentStep: null == currentStep ? _self.currentStep : currentStep // ignore: cast_nullable_to_non_nullable
as int,adminComment: freezed == adminComment ? _self.adminComment : adminComment // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId,  String status, @JsonKey(name: 'brand_name')  String? brandName,  String? introduction,  String? address, @JsonKey(name: 'contact_phone')  String? contactPhone, @JsonKey(name: 'contact_email')  String? contactEmail, @JsonKey(name: 'biz_type')  String? bizType, @JsonKey(name: 'biz_name')  String? bizName, @JsonKey(name: 'biz_number')  String? bizNumber, @JsonKey(name: 'representative_name')  String? representativeName, @JsonKey(name: 'bank_name')  String? bankName, @JsonKey(name: 'account_number')  String? accountNumber, @JsonKey(name: 'account_holder')  String? accountHolder, @JsonKey(name: 'biz_registration_path')  String? bizRegistrationPath, @JsonKey(name: 'bankbook_path')  String? bankbookPath, @JsonKey(name: 'tax_email')  String? taxEmail, @JsonKey(name: 'profile_image_path')  String? profileImagePath, @JsonKey(name: 'current_step')  int currentStep, @JsonKey(name: 'admin_comment')  String? adminComment, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'updated_at')  String? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PartnerApplication() when $default != null:
return $default(_that.id,_that.userId,_that.status,_that.brandName,_that.introduction,_that.address,_that.contactPhone,_that.contactEmail,_that.bizType,_that.bizName,_that.bizNumber,_that.representativeName,_that.bankName,_that.accountNumber,_that.accountHolder,_that.bizRegistrationPath,_that.bankbookPath,_that.taxEmail,_that.profileImagePath,_that.currentStep,_that.adminComment,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId,  String status, @JsonKey(name: 'brand_name')  String? brandName,  String? introduction,  String? address, @JsonKey(name: 'contact_phone')  String? contactPhone, @JsonKey(name: 'contact_email')  String? contactEmail, @JsonKey(name: 'biz_type')  String? bizType, @JsonKey(name: 'biz_name')  String? bizName, @JsonKey(name: 'biz_number')  String? bizNumber, @JsonKey(name: 'representative_name')  String? representativeName, @JsonKey(name: 'bank_name')  String? bankName, @JsonKey(name: 'account_number')  String? accountNumber, @JsonKey(name: 'account_holder')  String? accountHolder, @JsonKey(name: 'biz_registration_path')  String? bizRegistrationPath, @JsonKey(name: 'bankbook_path')  String? bankbookPath, @JsonKey(name: 'tax_email')  String? taxEmail, @JsonKey(name: 'profile_image_path')  String? profileImagePath, @JsonKey(name: 'current_step')  int currentStep, @JsonKey(name: 'admin_comment')  String? adminComment, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'updated_at')  String? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _PartnerApplication():
return $default(_that.id,_that.userId,_that.status,_that.brandName,_that.introduction,_that.address,_that.contactPhone,_that.contactEmail,_that.bizType,_that.bizName,_that.bizNumber,_that.representativeName,_that.bankName,_that.accountNumber,_that.accountHolder,_that.bizRegistrationPath,_that.bankbookPath,_that.taxEmail,_that.profileImagePath,_that.currentStep,_that.adminComment,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'user_id')  String userId,  String status, @JsonKey(name: 'brand_name')  String? brandName,  String? introduction,  String? address, @JsonKey(name: 'contact_phone')  String? contactPhone, @JsonKey(name: 'contact_email')  String? contactEmail, @JsonKey(name: 'biz_type')  String? bizType, @JsonKey(name: 'biz_name')  String? bizName, @JsonKey(name: 'biz_number')  String? bizNumber, @JsonKey(name: 'representative_name')  String? representativeName, @JsonKey(name: 'bank_name')  String? bankName, @JsonKey(name: 'account_number')  String? accountNumber, @JsonKey(name: 'account_holder')  String? accountHolder, @JsonKey(name: 'biz_registration_path')  String? bizRegistrationPath, @JsonKey(name: 'bankbook_path')  String? bankbookPath, @JsonKey(name: 'tax_email')  String? taxEmail, @JsonKey(name: 'profile_image_path')  String? profileImagePath, @JsonKey(name: 'current_step')  int currentStep, @JsonKey(name: 'admin_comment')  String? adminComment, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'updated_at')  String? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _PartnerApplication() when $default != null:
return $default(_that.id,_that.userId,_that.status,_that.brandName,_that.introduction,_that.address,_that.contactPhone,_that.contactEmail,_that.bizType,_that.bizName,_that.bizNumber,_that.representativeName,_that.bankName,_that.accountNumber,_that.accountHolder,_that.bizRegistrationPath,_that.bankbookPath,_that.taxEmail,_that.profileImagePath,_that.currentStep,_that.adminComment,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PartnerApplication implements PartnerApplication {
  const _PartnerApplication({required this.id, @JsonKey(name: 'user_id') required this.userId, this.status = 'draft', @JsonKey(name: 'brand_name') this.brandName, this.introduction, this.address, @JsonKey(name: 'contact_phone') this.contactPhone, @JsonKey(name: 'contact_email') this.contactEmail, @JsonKey(name: 'biz_type') this.bizType, @JsonKey(name: 'biz_name') this.bizName, @JsonKey(name: 'biz_number') this.bizNumber, @JsonKey(name: 'representative_name') this.representativeName, @JsonKey(name: 'bank_name') this.bankName, @JsonKey(name: 'account_number') this.accountNumber, @JsonKey(name: 'account_holder') this.accountHolder, @JsonKey(name: 'biz_registration_path') this.bizRegistrationPath, @JsonKey(name: 'bankbook_path') this.bankbookPath, @JsonKey(name: 'tax_email') this.taxEmail, @JsonKey(name: 'profile_image_path') this.profileImagePath, @JsonKey(name: 'current_step') this.currentStep = 0, @JsonKey(name: 'admin_comment') this.adminComment, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt});
  factory _PartnerApplication.fromJson(Map<String, dynamic> json) => _$PartnerApplicationFromJson(json);

@override final  String id;
@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey() final  String status;
@override@JsonKey(name: 'brand_name') final  String? brandName;
@override final  String? introduction;
@override final  String? address;
@override@JsonKey(name: 'contact_phone') final  String? contactPhone;
@override@JsonKey(name: 'contact_email') final  String? contactEmail;
@override@JsonKey(name: 'biz_type') final  String? bizType;
@override@JsonKey(name: 'biz_name') final  String? bizName;
@override@JsonKey(name: 'biz_number') final  String? bizNumber;
@override@JsonKey(name: 'representative_name') final  String? representativeName;
@override@JsonKey(name: 'bank_name') final  String? bankName;
@override@JsonKey(name: 'account_number') final  String? accountNumber;
@override@JsonKey(name: 'account_holder') final  String? accountHolder;
@override@JsonKey(name: 'biz_registration_path') final  String? bizRegistrationPath;
@override@JsonKey(name: 'bankbook_path') final  String? bankbookPath;
@override@JsonKey(name: 'tax_email') final  String? taxEmail;
@override@JsonKey(name: 'profile_image_path') final  String? profileImagePath;
@override@JsonKey(name: 'current_step') final  int currentStep;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PartnerApplication&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.status, status) || other.status == status)&&(identical(other.brandName, brandName) || other.brandName == brandName)&&(identical(other.introduction, introduction) || other.introduction == introduction)&&(identical(other.address, address) || other.address == address)&&(identical(other.contactPhone, contactPhone) || other.contactPhone == contactPhone)&&(identical(other.contactEmail, contactEmail) || other.contactEmail == contactEmail)&&(identical(other.bizType, bizType) || other.bizType == bizType)&&(identical(other.bizName, bizName) || other.bizName == bizName)&&(identical(other.bizNumber, bizNumber) || other.bizNumber == bizNumber)&&(identical(other.representativeName, representativeName) || other.representativeName == representativeName)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.accountNumber, accountNumber) || other.accountNumber == accountNumber)&&(identical(other.accountHolder, accountHolder) || other.accountHolder == accountHolder)&&(identical(other.bizRegistrationPath, bizRegistrationPath) || other.bizRegistrationPath == bizRegistrationPath)&&(identical(other.bankbookPath, bankbookPath) || other.bankbookPath == bankbookPath)&&(identical(other.taxEmail, taxEmail) || other.taxEmail == taxEmail)&&(identical(other.profileImagePath, profileImagePath) || other.profileImagePath == profileImagePath)&&(identical(other.currentStep, currentStep) || other.currentStep == currentStep)&&(identical(other.adminComment, adminComment) || other.adminComment == adminComment)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,userId,status,brandName,introduction,address,contactPhone,contactEmail,bizType,bizName,bizNumber,representativeName,bankName,accountNumber,accountHolder,bizRegistrationPath,bankbookPath,taxEmail,profileImagePath,currentStep,adminComment,createdAt,updatedAt]);

@override
String toString() {
  return 'PartnerApplication(id: $id, userId: $userId, status: $status, brandName: $brandName, introduction: $introduction, address: $address, contactPhone: $contactPhone, contactEmail: $contactEmail, bizType: $bizType, bizName: $bizName, bizNumber: $bizNumber, representativeName: $representativeName, bankName: $bankName, accountNumber: $accountNumber, accountHolder: $accountHolder, bizRegistrationPath: $bizRegistrationPath, bankbookPath: $bankbookPath, taxEmail: $taxEmail, profileImagePath: $profileImagePath, currentStep: $currentStep, adminComment: $adminComment, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PartnerApplicationCopyWith<$Res> implements $PartnerApplicationCopyWith<$Res> {
  factory _$PartnerApplicationCopyWith(_PartnerApplication value, $Res Function(_PartnerApplication) _then) = __$PartnerApplicationCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId, String status,@JsonKey(name: 'brand_name') String? brandName, String? introduction, String? address,@JsonKey(name: 'contact_phone') String? contactPhone,@JsonKey(name: 'contact_email') String? contactEmail,@JsonKey(name: 'biz_type') String? bizType,@JsonKey(name: 'biz_name') String? bizName,@JsonKey(name: 'biz_number') String? bizNumber,@JsonKey(name: 'representative_name') String? representativeName,@JsonKey(name: 'bank_name') String? bankName,@JsonKey(name: 'account_number') String? accountNumber,@JsonKey(name: 'account_holder') String? accountHolder,@JsonKey(name: 'biz_registration_path') String? bizRegistrationPath,@JsonKey(name: 'bankbook_path') String? bankbookPath,@JsonKey(name: 'tax_email') String? taxEmail,@JsonKey(name: 'profile_image_path') String? profileImagePath,@JsonKey(name: 'current_step') int currentStep,@JsonKey(name: 'admin_comment') String? adminComment,@JsonKey(name: 'created_at') String? createdAt,@JsonKey(name: 'updated_at') String? updatedAt
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? status = null,Object? brandName = freezed,Object? introduction = freezed,Object? address = freezed,Object? contactPhone = freezed,Object? contactEmail = freezed,Object? bizType = freezed,Object? bizName = freezed,Object? bizNumber = freezed,Object? representativeName = freezed,Object? bankName = freezed,Object? accountNumber = freezed,Object? accountHolder = freezed,Object? bizRegistrationPath = freezed,Object? bankbookPath = freezed,Object? taxEmail = freezed,Object? profileImagePath = freezed,Object? currentStep = null,Object? adminComment = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_PartnerApplication(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,brandName: freezed == brandName ? _self.brandName : brandName // ignore: cast_nullable_to_non_nullable
as String?,introduction: freezed == introduction ? _self.introduction : introduction // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,contactPhone: freezed == contactPhone ? _self.contactPhone : contactPhone // ignore: cast_nullable_to_non_nullable
as String?,contactEmail: freezed == contactEmail ? _self.contactEmail : contactEmail // ignore: cast_nullable_to_non_nullable
as String?,bizType: freezed == bizType ? _self.bizType : bizType // ignore: cast_nullable_to_non_nullable
as String?,bizName: freezed == bizName ? _self.bizName : bizName // ignore: cast_nullable_to_non_nullable
as String?,bizNumber: freezed == bizNumber ? _self.bizNumber : bizNumber // ignore: cast_nullable_to_non_nullable
as String?,representativeName: freezed == representativeName ? _self.representativeName : representativeName // ignore: cast_nullable_to_non_nullable
as String?,bankName: freezed == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String?,accountNumber: freezed == accountNumber ? _self.accountNumber : accountNumber // ignore: cast_nullable_to_non_nullable
as String?,accountHolder: freezed == accountHolder ? _self.accountHolder : accountHolder // ignore: cast_nullable_to_non_nullable
as String?,bizRegistrationPath: freezed == bizRegistrationPath ? _self.bizRegistrationPath : bizRegistrationPath // ignore: cast_nullable_to_non_nullable
as String?,bankbookPath: freezed == bankbookPath ? _self.bankbookPath : bankbookPath // ignore: cast_nullable_to_non_nullable
as String?,taxEmail: freezed == taxEmail ? _self.taxEmail : taxEmail // ignore: cast_nullable_to_non_nullable
as String?,profileImagePath: freezed == profileImagePath ? _self.profileImagePath : profileImagePath // ignore: cast_nullable_to_non_nullable
as String?,currentStep: null == currentStep ? _self.currentStep : currentStep // ignore: cast_nullable_to_non_nullable
as int,adminComment: freezed == adminComment ? _self.adminComment : adminComment // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
