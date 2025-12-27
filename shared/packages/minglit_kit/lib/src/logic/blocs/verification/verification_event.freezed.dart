// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'verification_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$VerificationEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerificationEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'VerificationEvent()';
}


}

/// @nodoc
class $VerificationEventCopyWith<$Res>  {
$VerificationEventCopyWith(VerificationEvent _, $Res Function(VerificationEvent) __);
}


/// Adds pattern-matching-related methods to [VerificationEvent].
extension VerificationEventPatterns on VerificationEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _LoadPartnerRequirements value)?  loadPartnerRequirements,TResult Function( _SubmitVerification value)?  submitVerification,TResult Function( _LoadPendingRequests value)?  loadPendingRequests,TResult Function( _LoadCorrectionRequests value)?  loadCorrectionRequests,TResult Function( _LoadComments value)?  loadComments,TResult Function( _ReviewRequest value)?  reviewRequest,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LoadPartnerRequirements() when loadPartnerRequirements != null:
return loadPartnerRequirements(_that);case _SubmitVerification() when submitVerification != null:
return submitVerification(_that);case _LoadPendingRequests() when loadPendingRequests != null:
return loadPendingRequests(_that);case _LoadCorrectionRequests() when loadCorrectionRequests != null:
return loadCorrectionRequests(_that);case _LoadComments() when loadComments != null:
return loadComments(_that);case _ReviewRequest() when reviewRequest != null:
return reviewRequest(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _LoadPartnerRequirements value)  loadPartnerRequirements,required TResult Function( _SubmitVerification value)  submitVerification,required TResult Function( _LoadPendingRequests value)  loadPendingRequests,required TResult Function( _LoadCorrectionRequests value)  loadCorrectionRequests,required TResult Function( _LoadComments value)  loadComments,required TResult Function( _ReviewRequest value)  reviewRequest,}){
final _that = this;
switch (_that) {
case _LoadPartnerRequirements():
return loadPartnerRequirements(_that);case _SubmitVerification():
return submitVerification(_that);case _LoadPendingRequests():
return loadPendingRequests(_that);case _LoadCorrectionRequests():
return loadCorrectionRequests(_that);case _LoadComments():
return loadComments(_that);case _ReviewRequest():
return reviewRequest(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _LoadPartnerRequirements value)?  loadPartnerRequirements,TResult? Function( _SubmitVerification value)?  submitVerification,TResult? Function( _LoadPendingRequests value)?  loadPendingRequests,TResult? Function( _LoadCorrectionRequests value)?  loadCorrectionRequests,TResult? Function( _LoadComments value)?  loadComments,TResult? Function( _ReviewRequest value)?  reviewRequest,}){
final _that = this;
switch (_that) {
case _LoadPartnerRequirements() when loadPartnerRequirements != null:
return loadPartnerRequirements(_that);case _SubmitVerification() when submitVerification != null:
return submitVerification(_that);case _LoadPendingRequests() when loadPendingRequests != null:
return loadPendingRequests(_that);case _LoadCorrectionRequests() when loadCorrectionRequests != null:
return loadCorrectionRequests(_that);case _LoadComments() when loadComments != null:
return loadComments(_that);case _ReviewRequest() when reviewRequest != null:
return reviewRequest(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String partnerId,  List<String> requiredIds)?  loadPartnerRequirements,TResult Function( String partnerId,  String verificationId,  Map<String, dynamic> claimData,  List<XFile> proofFiles,  String? existingRequestId)?  submitVerification,TResult Function()?  loadPendingRequests,TResult Function()?  loadCorrectionRequests,TResult Function( String requestId)?  loadComments,TResult Function( String requestId,  VerificationStatus status,  String? rejectionReason,  String? comment)?  reviewRequest,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LoadPartnerRequirements() when loadPartnerRequirements != null:
return loadPartnerRequirements(_that.partnerId,_that.requiredIds);case _SubmitVerification() when submitVerification != null:
return submitVerification(_that.partnerId,_that.verificationId,_that.claimData,_that.proofFiles,_that.existingRequestId);case _LoadPendingRequests() when loadPendingRequests != null:
return loadPendingRequests();case _LoadCorrectionRequests() when loadCorrectionRequests != null:
return loadCorrectionRequests();case _LoadComments() when loadComments != null:
return loadComments(_that.requestId);case _ReviewRequest() when reviewRequest != null:
return reviewRequest(_that.requestId,_that.status,_that.rejectionReason,_that.comment);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String partnerId,  List<String> requiredIds)  loadPartnerRequirements,required TResult Function( String partnerId,  String verificationId,  Map<String, dynamic> claimData,  List<XFile> proofFiles,  String? existingRequestId)  submitVerification,required TResult Function()  loadPendingRequests,required TResult Function()  loadCorrectionRequests,required TResult Function( String requestId)  loadComments,required TResult Function( String requestId,  VerificationStatus status,  String? rejectionReason,  String? comment)  reviewRequest,}) {final _that = this;
switch (_that) {
case _LoadPartnerRequirements():
return loadPartnerRequirements(_that.partnerId,_that.requiredIds);case _SubmitVerification():
return submitVerification(_that.partnerId,_that.verificationId,_that.claimData,_that.proofFiles,_that.existingRequestId);case _LoadPendingRequests():
return loadPendingRequests();case _LoadCorrectionRequests():
return loadCorrectionRequests();case _LoadComments():
return loadComments(_that.requestId);case _ReviewRequest():
return reviewRequest(_that.requestId,_that.status,_that.rejectionReason,_that.comment);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String partnerId,  List<String> requiredIds)?  loadPartnerRequirements,TResult? Function( String partnerId,  String verificationId,  Map<String, dynamic> claimData,  List<XFile> proofFiles,  String? existingRequestId)?  submitVerification,TResult? Function()?  loadPendingRequests,TResult? Function()?  loadCorrectionRequests,TResult? Function( String requestId)?  loadComments,TResult? Function( String requestId,  VerificationStatus status,  String? rejectionReason,  String? comment)?  reviewRequest,}) {final _that = this;
switch (_that) {
case _LoadPartnerRequirements() when loadPartnerRequirements != null:
return loadPartnerRequirements(_that.partnerId,_that.requiredIds);case _SubmitVerification() when submitVerification != null:
return submitVerification(_that.partnerId,_that.verificationId,_that.claimData,_that.proofFiles,_that.existingRequestId);case _LoadPendingRequests() when loadPendingRequests != null:
return loadPendingRequests();case _LoadCorrectionRequests() when loadCorrectionRequests != null:
return loadCorrectionRequests();case _LoadComments() when loadComments != null:
return loadComments(_that.requestId);case _ReviewRequest() when reviewRequest != null:
return reviewRequest(_that.requestId,_that.status,_that.rejectionReason,_that.comment);case _:
  return null;

}
}

}

/// @nodoc


class _LoadPartnerRequirements implements VerificationEvent {
  const _LoadPartnerRequirements({required this.partnerId, required final  List<String> requiredIds}): _requiredIds = requiredIds;
  

 final  String partnerId;
 final  List<String> _requiredIds;
 List<String> get requiredIds {
  if (_requiredIds is EqualUnmodifiableListView) return _requiredIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_requiredIds);
}


/// Create a copy of VerificationEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadPartnerRequirementsCopyWith<_LoadPartnerRequirements> get copyWith => __$LoadPartnerRequirementsCopyWithImpl<_LoadPartnerRequirements>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadPartnerRequirements&&(identical(other.partnerId, partnerId) || other.partnerId == partnerId)&&const DeepCollectionEquality().equals(other._requiredIds, _requiredIds));
}


@override
int get hashCode => Object.hash(runtimeType,partnerId,const DeepCollectionEquality().hash(_requiredIds));

@override
String toString() {
  return 'VerificationEvent.loadPartnerRequirements(partnerId: $partnerId, requiredIds: $requiredIds)';
}


}

/// @nodoc
abstract mixin class _$LoadPartnerRequirementsCopyWith<$Res> implements $VerificationEventCopyWith<$Res> {
  factory _$LoadPartnerRequirementsCopyWith(_LoadPartnerRequirements value, $Res Function(_LoadPartnerRequirements) _then) = __$LoadPartnerRequirementsCopyWithImpl;
@useResult
$Res call({
 String partnerId, List<String> requiredIds
});




}
/// @nodoc
class __$LoadPartnerRequirementsCopyWithImpl<$Res>
    implements _$LoadPartnerRequirementsCopyWith<$Res> {
  __$LoadPartnerRequirementsCopyWithImpl(this._self, this._then);

  final _LoadPartnerRequirements _self;
  final $Res Function(_LoadPartnerRequirements) _then;

/// Create a copy of VerificationEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? partnerId = null,Object? requiredIds = null,}) {
  return _then(_LoadPartnerRequirements(
partnerId: null == partnerId ? _self.partnerId : partnerId // ignore: cast_nullable_to_non_nullable
as String,requiredIds: null == requiredIds ? _self._requiredIds : requiredIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc


class _SubmitVerification implements VerificationEvent {
  const _SubmitVerification({required this.partnerId, required this.verificationId, required final  Map<String, dynamic> claimData, required final  List<XFile> proofFiles, this.existingRequestId}): _claimData = claimData,_proofFiles = proofFiles;
  

 final  String partnerId;
 final  String verificationId;
 final  Map<String, dynamic> _claimData;
 Map<String, dynamic> get claimData {
  if (_claimData is EqualUnmodifiableMapView) return _claimData;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_claimData);
}

 final  List<XFile> _proofFiles;
 List<XFile> get proofFiles {
  if (_proofFiles is EqualUnmodifiableListView) return _proofFiles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_proofFiles);
}

 final  String? existingRequestId;

/// Create a copy of VerificationEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubmitVerificationCopyWith<_SubmitVerification> get copyWith => __$SubmitVerificationCopyWithImpl<_SubmitVerification>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubmitVerification&&(identical(other.partnerId, partnerId) || other.partnerId == partnerId)&&(identical(other.verificationId, verificationId) || other.verificationId == verificationId)&&const DeepCollectionEquality().equals(other._claimData, _claimData)&&const DeepCollectionEquality().equals(other._proofFiles, _proofFiles)&&(identical(other.existingRequestId, existingRequestId) || other.existingRequestId == existingRequestId));
}


@override
int get hashCode => Object.hash(runtimeType,partnerId,verificationId,const DeepCollectionEquality().hash(_claimData),const DeepCollectionEquality().hash(_proofFiles),existingRequestId);

@override
String toString() {
  return 'VerificationEvent.submitVerification(partnerId: $partnerId, verificationId: $verificationId, claimData: $claimData, proofFiles: $proofFiles, existingRequestId: $existingRequestId)';
}


}

/// @nodoc
abstract mixin class _$SubmitVerificationCopyWith<$Res> implements $VerificationEventCopyWith<$Res> {
  factory _$SubmitVerificationCopyWith(_SubmitVerification value, $Res Function(_SubmitVerification) _then) = __$SubmitVerificationCopyWithImpl;
@useResult
$Res call({
 String partnerId, String verificationId, Map<String, dynamic> claimData, List<XFile> proofFiles, String? existingRequestId
});




}
/// @nodoc
class __$SubmitVerificationCopyWithImpl<$Res>
    implements _$SubmitVerificationCopyWith<$Res> {
  __$SubmitVerificationCopyWithImpl(this._self, this._then);

  final _SubmitVerification _self;
  final $Res Function(_SubmitVerification) _then;

/// Create a copy of VerificationEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? partnerId = null,Object? verificationId = null,Object? claimData = null,Object? proofFiles = null,Object? existingRequestId = freezed,}) {
  return _then(_SubmitVerification(
partnerId: null == partnerId ? _self.partnerId : partnerId // ignore: cast_nullable_to_non_nullable
as String,verificationId: null == verificationId ? _self.verificationId : verificationId // ignore: cast_nullable_to_non_nullable
as String,claimData: null == claimData ? _self._claimData : claimData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,proofFiles: null == proofFiles ? _self._proofFiles : proofFiles // ignore: cast_nullable_to_non_nullable
as List<XFile>,existingRequestId: freezed == existingRequestId ? _self.existingRequestId : existingRequestId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class _LoadPendingRequests implements VerificationEvent {
  const _LoadPendingRequests();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadPendingRequests);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'VerificationEvent.loadPendingRequests()';
}


}




/// @nodoc


class _LoadCorrectionRequests implements VerificationEvent {
  const _LoadCorrectionRequests();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadCorrectionRequests);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'VerificationEvent.loadCorrectionRequests()';
}


}




/// @nodoc


class _LoadComments implements VerificationEvent {
  const _LoadComments({required this.requestId});
  

 final  String requestId;

/// Create a copy of VerificationEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadCommentsCopyWith<_LoadComments> get copyWith => __$LoadCommentsCopyWithImpl<_LoadComments>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadComments&&(identical(other.requestId, requestId) || other.requestId == requestId));
}


@override
int get hashCode => Object.hash(runtimeType,requestId);

@override
String toString() {
  return 'VerificationEvent.loadComments(requestId: $requestId)';
}


}

/// @nodoc
abstract mixin class _$LoadCommentsCopyWith<$Res> implements $VerificationEventCopyWith<$Res> {
  factory _$LoadCommentsCopyWith(_LoadComments value, $Res Function(_LoadComments) _then) = __$LoadCommentsCopyWithImpl;
@useResult
$Res call({
 String requestId
});




}
/// @nodoc
class __$LoadCommentsCopyWithImpl<$Res>
    implements _$LoadCommentsCopyWith<$Res> {
  __$LoadCommentsCopyWithImpl(this._self, this._then);

  final _LoadComments _self;
  final $Res Function(_LoadComments) _then;

/// Create a copy of VerificationEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? requestId = null,}) {
  return _then(_LoadComments(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _ReviewRequest implements VerificationEvent {
  const _ReviewRequest({required this.requestId, required this.status, this.rejectionReason, this.comment});
  

 final  String requestId;
 final  VerificationStatus status;
 final  String? rejectionReason;
 final  String? comment;

/// Create a copy of VerificationEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReviewRequestCopyWith<_ReviewRequest> get copyWith => __$ReviewRequestCopyWithImpl<_ReviewRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReviewRequest&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.status, status) || other.status == status)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason)&&(identical(other.comment, comment) || other.comment == comment));
}


@override
int get hashCode => Object.hash(runtimeType,requestId,status,rejectionReason,comment);

@override
String toString() {
  return 'VerificationEvent.reviewRequest(requestId: $requestId, status: $status, rejectionReason: $rejectionReason, comment: $comment)';
}


}

/// @nodoc
abstract mixin class _$ReviewRequestCopyWith<$Res> implements $VerificationEventCopyWith<$Res> {
  factory _$ReviewRequestCopyWith(_ReviewRequest value, $Res Function(_ReviewRequest) _then) = __$ReviewRequestCopyWithImpl;
@useResult
$Res call({
 String requestId, VerificationStatus status, String? rejectionReason, String? comment
});




}
/// @nodoc
class __$ReviewRequestCopyWithImpl<$Res>
    implements _$ReviewRequestCopyWith<$Res> {
  __$ReviewRequestCopyWithImpl(this._self, this._then);

  final _ReviewRequest _self;
  final $Res Function(_ReviewRequest) _then;

/// Create a copy of VerificationEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? requestId = null,Object? status = null,Object? rejectionReason = freezed,Object? comment = freezed,}) {
  return _then(_ReviewRequest(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as VerificationStatus,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
