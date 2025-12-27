// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'partner_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PartnerEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PartnerEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PartnerEvent()';
}


}

/// @nodoc
class $PartnerEventCopyWith<$Res>  {
$PartnerEventCopyWith(PartnerEvent _, $Res Function(PartnerEvent) __);
}


/// Adds pattern-matching-related methods to [PartnerEvent].
extension PartnerEventPatterns on PartnerEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _CheckApplicationStatus value)?  checkApplicationStatus,TResult Function( _SubmitApplication value)?  submitApplication,TResult Function( _LoadMembers value)?  loadMembers,TResult Function( _LoadAllApplications value)?  loadAllApplications,TResult Function( _ReviewApplication value)?  reviewApplication,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CheckApplicationStatus() when checkApplicationStatus != null:
return checkApplicationStatus(_that);case _SubmitApplication() when submitApplication != null:
return submitApplication(_that);case _LoadMembers() when loadMembers != null:
return loadMembers(_that);case _LoadAllApplications() when loadAllApplications != null:
return loadAllApplications(_that);case _ReviewApplication() when reviewApplication != null:
return reviewApplication(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _CheckApplicationStatus value)  checkApplicationStatus,required TResult Function( _SubmitApplication value)  submitApplication,required TResult Function( _LoadMembers value)  loadMembers,required TResult Function( _LoadAllApplications value)  loadAllApplications,required TResult Function( _ReviewApplication value)  reviewApplication,}){
final _that = this;
switch (_that) {
case _CheckApplicationStatus():
return checkApplicationStatus(_that);case _SubmitApplication():
return submitApplication(_that);case _LoadMembers():
return loadMembers(_that);case _LoadAllApplications():
return loadAllApplications(_that);case _ReviewApplication():
return reviewApplication(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _CheckApplicationStatus value)?  checkApplicationStatus,TResult? Function( _SubmitApplication value)?  submitApplication,TResult? Function( _LoadMembers value)?  loadMembers,TResult? Function( _LoadAllApplications value)?  loadAllApplications,TResult? Function( _ReviewApplication value)?  reviewApplication,}){
final _that = this;
switch (_that) {
case _CheckApplicationStatus() when checkApplicationStatus != null:
return checkApplicationStatus(_that);case _SubmitApplication() when submitApplication != null:
return submitApplication(_that);case _LoadMembers() when loadMembers != null:
return loadMembers(_that);case _LoadAllApplications() when loadAllApplications != null:
return loadAllApplications(_that);case _ReviewApplication() when reviewApplication != null:
return reviewApplication(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  checkApplicationStatus,TResult Function( Map<String, dynamic> applicationData,  XFile bizRegistrationFile,  XFile bankbookFile)?  submitApplication,TResult Function( String partnerId)?  loadMembers,TResult Function( String status,  String? searchTerm)?  loadAllApplications,TResult Function( String applicationId,  String status,  String? adminComment)?  reviewApplication,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CheckApplicationStatus() when checkApplicationStatus != null:
return checkApplicationStatus();case _SubmitApplication() when submitApplication != null:
return submitApplication(_that.applicationData,_that.bizRegistrationFile,_that.bankbookFile);case _LoadMembers() when loadMembers != null:
return loadMembers(_that.partnerId);case _LoadAllApplications() when loadAllApplications != null:
return loadAllApplications(_that.status,_that.searchTerm);case _ReviewApplication() when reviewApplication != null:
return reviewApplication(_that.applicationId,_that.status,_that.adminComment);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  checkApplicationStatus,required TResult Function( Map<String, dynamic> applicationData,  XFile bizRegistrationFile,  XFile bankbookFile)  submitApplication,required TResult Function( String partnerId)  loadMembers,required TResult Function( String status,  String? searchTerm)  loadAllApplications,required TResult Function( String applicationId,  String status,  String? adminComment)  reviewApplication,}) {final _that = this;
switch (_that) {
case _CheckApplicationStatus():
return checkApplicationStatus();case _SubmitApplication():
return submitApplication(_that.applicationData,_that.bizRegistrationFile,_that.bankbookFile);case _LoadMembers():
return loadMembers(_that.partnerId);case _LoadAllApplications():
return loadAllApplications(_that.status,_that.searchTerm);case _ReviewApplication():
return reviewApplication(_that.applicationId,_that.status,_that.adminComment);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  checkApplicationStatus,TResult? Function( Map<String, dynamic> applicationData,  XFile bizRegistrationFile,  XFile bankbookFile)?  submitApplication,TResult? Function( String partnerId)?  loadMembers,TResult? Function( String status,  String? searchTerm)?  loadAllApplications,TResult? Function( String applicationId,  String status,  String? adminComment)?  reviewApplication,}) {final _that = this;
switch (_that) {
case _CheckApplicationStatus() when checkApplicationStatus != null:
return checkApplicationStatus();case _SubmitApplication() when submitApplication != null:
return submitApplication(_that.applicationData,_that.bizRegistrationFile,_that.bankbookFile);case _LoadMembers() when loadMembers != null:
return loadMembers(_that.partnerId);case _LoadAllApplications() when loadAllApplications != null:
return loadAllApplications(_that.status,_that.searchTerm);case _ReviewApplication() when reviewApplication != null:
return reviewApplication(_that.applicationId,_that.status,_that.adminComment);case _:
  return null;

}
}

}

/// @nodoc


class _CheckApplicationStatus implements PartnerEvent {
  const _CheckApplicationStatus();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CheckApplicationStatus);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PartnerEvent.checkApplicationStatus()';
}


}




/// @nodoc


class _SubmitApplication implements PartnerEvent {
  const _SubmitApplication({required final  Map<String, dynamic> applicationData, required this.bizRegistrationFile, required this.bankbookFile}): _applicationData = applicationData;
  

 final  Map<String, dynamic> _applicationData;
 Map<String, dynamic> get applicationData {
  if (_applicationData is EqualUnmodifiableMapView) return _applicationData;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_applicationData);
}

 final  XFile bizRegistrationFile;
 final  XFile bankbookFile;

/// Create a copy of PartnerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubmitApplicationCopyWith<_SubmitApplication> get copyWith => __$SubmitApplicationCopyWithImpl<_SubmitApplication>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubmitApplication&&const DeepCollectionEquality().equals(other._applicationData, _applicationData)&&(identical(other.bizRegistrationFile, bizRegistrationFile) || other.bizRegistrationFile == bizRegistrationFile)&&(identical(other.bankbookFile, bankbookFile) || other.bankbookFile == bankbookFile));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_applicationData),bizRegistrationFile,bankbookFile);

@override
String toString() {
  return 'PartnerEvent.submitApplication(applicationData: $applicationData, bizRegistrationFile: $bizRegistrationFile, bankbookFile: $bankbookFile)';
}


}

/// @nodoc
abstract mixin class _$SubmitApplicationCopyWith<$Res> implements $PartnerEventCopyWith<$Res> {
  factory _$SubmitApplicationCopyWith(_SubmitApplication value, $Res Function(_SubmitApplication) _then) = __$SubmitApplicationCopyWithImpl;
@useResult
$Res call({
 Map<String, dynamic> applicationData, XFile bizRegistrationFile, XFile bankbookFile
});




}
/// @nodoc
class __$SubmitApplicationCopyWithImpl<$Res>
    implements _$SubmitApplicationCopyWith<$Res> {
  __$SubmitApplicationCopyWithImpl(this._self, this._then);

  final _SubmitApplication _self;
  final $Res Function(_SubmitApplication) _then;

/// Create a copy of PartnerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? applicationData = null,Object? bizRegistrationFile = null,Object? bankbookFile = null,}) {
  return _then(_SubmitApplication(
applicationData: null == applicationData ? _self._applicationData : applicationData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,bizRegistrationFile: null == bizRegistrationFile ? _self.bizRegistrationFile : bizRegistrationFile // ignore: cast_nullable_to_non_nullable
as XFile,bankbookFile: null == bankbookFile ? _self.bankbookFile : bankbookFile // ignore: cast_nullable_to_non_nullable
as XFile,
  ));
}


}

/// @nodoc


class _LoadMembers implements PartnerEvent {
  const _LoadMembers({required this.partnerId});
  

 final  String partnerId;

/// Create a copy of PartnerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadMembersCopyWith<_LoadMembers> get copyWith => __$LoadMembersCopyWithImpl<_LoadMembers>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadMembers&&(identical(other.partnerId, partnerId) || other.partnerId == partnerId));
}


@override
int get hashCode => Object.hash(runtimeType,partnerId);

@override
String toString() {
  return 'PartnerEvent.loadMembers(partnerId: $partnerId)';
}


}

/// @nodoc
abstract mixin class _$LoadMembersCopyWith<$Res> implements $PartnerEventCopyWith<$Res> {
  factory _$LoadMembersCopyWith(_LoadMembers value, $Res Function(_LoadMembers) _then) = __$LoadMembersCopyWithImpl;
@useResult
$Res call({
 String partnerId
});




}
/// @nodoc
class __$LoadMembersCopyWithImpl<$Res>
    implements _$LoadMembersCopyWith<$Res> {
  __$LoadMembersCopyWithImpl(this._self, this._then);

  final _LoadMembers _self;
  final $Res Function(_LoadMembers) _then;

/// Create a copy of PartnerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? partnerId = null,}) {
  return _then(_LoadMembers(
partnerId: null == partnerId ? _self.partnerId : partnerId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _LoadAllApplications implements PartnerEvent {
  const _LoadAllApplications({this.status = 'all', this.searchTerm});
  

@JsonKey() final  String status;
 final  String? searchTerm;

/// Create a copy of PartnerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadAllApplicationsCopyWith<_LoadAllApplications> get copyWith => __$LoadAllApplicationsCopyWithImpl<_LoadAllApplications>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadAllApplications&&(identical(other.status, status) || other.status == status)&&(identical(other.searchTerm, searchTerm) || other.searchTerm == searchTerm));
}


@override
int get hashCode => Object.hash(runtimeType,status,searchTerm);

@override
String toString() {
  return 'PartnerEvent.loadAllApplications(status: $status, searchTerm: $searchTerm)';
}


}

/// @nodoc
abstract mixin class _$LoadAllApplicationsCopyWith<$Res> implements $PartnerEventCopyWith<$Res> {
  factory _$LoadAllApplicationsCopyWith(_LoadAllApplications value, $Res Function(_LoadAllApplications) _then) = __$LoadAllApplicationsCopyWithImpl;
@useResult
$Res call({
 String status, String? searchTerm
});




}
/// @nodoc
class __$LoadAllApplicationsCopyWithImpl<$Res>
    implements _$LoadAllApplicationsCopyWith<$Res> {
  __$LoadAllApplicationsCopyWithImpl(this._self, this._then);

  final _LoadAllApplications _self;
  final $Res Function(_LoadAllApplications) _then;

/// Create a copy of PartnerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? status = null,Object? searchTerm = freezed,}) {
  return _then(_LoadAllApplications(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,searchTerm: freezed == searchTerm ? _self.searchTerm : searchTerm // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class _ReviewApplication implements PartnerEvent {
  const _ReviewApplication({required this.applicationId, required this.status, this.adminComment});
  

 final  String applicationId;
 final  String status;
 final  String? adminComment;

/// Create a copy of PartnerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReviewApplicationCopyWith<_ReviewApplication> get copyWith => __$ReviewApplicationCopyWithImpl<_ReviewApplication>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReviewApplication&&(identical(other.applicationId, applicationId) || other.applicationId == applicationId)&&(identical(other.status, status) || other.status == status)&&(identical(other.adminComment, adminComment) || other.adminComment == adminComment));
}


@override
int get hashCode => Object.hash(runtimeType,applicationId,status,adminComment);

@override
String toString() {
  return 'PartnerEvent.reviewApplication(applicationId: $applicationId, status: $status, adminComment: $adminComment)';
}


}

/// @nodoc
abstract mixin class _$ReviewApplicationCopyWith<$Res> implements $PartnerEventCopyWith<$Res> {
  factory _$ReviewApplicationCopyWith(_ReviewApplication value, $Res Function(_ReviewApplication) _then) = __$ReviewApplicationCopyWithImpl;
@useResult
$Res call({
 String applicationId, String status, String? adminComment
});




}
/// @nodoc
class __$ReviewApplicationCopyWithImpl<$Res>
    implements _$ReviewApplicationCopyWith<$Res> {
  __$ReviewApplicationCopyWithImpl(this._self, this._then);

  final _ReviewApplication _self;
  final $Res Function(_ReviewApplication) _then;

/// Create a copy of PartnerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? applicationId = null,Object? status = null,Object? adminComment = freezed,}) {
  return _then(_ReviewApplication(
applicationId: null == applicationId ? _self.applicationId : applicationId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,adminComment: freezed == adminComment ? _self.adminComment : adminComment // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
