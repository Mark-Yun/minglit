// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'event_application.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EventApplication {

 String get id;@JsonKey(name: 'event_id') String get eventId;@JsonKey(name: 'ticket_id') String get ticketId;@JsonKey(name: 'user_id') String get userId; String get status;// pending, pending_review, approved, rejected, cancelled, paid
@JsonKey(name: 'payment_id') String? get paymentId;@JsonKey(name: 'payment_amount') int? get paymentAmount;@JsonKey(name: 'refund_status') String get refundStatus;@JsonKey(name: 'rejection_reason') String? get rejectionReason;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt;// Relations (Nullable)
 UserProfile? get user; VerificationSubmission? get submission;
/// Create a copy of EventApplication
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventApplicationCopyWith<EventApplication> get copyWith => _$EventApplicationCopyWithImpl<EventApplication>(this as EventApplication, _$identity);

  /// Serializes this EventApplication to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventApplication&&(identical(other.id, id) || other.id == id)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.ticketId, ticketId) || other.ticketId == ticketId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.status, status) || other.status == status)&&(identical(other.paymentId, paymentId) || other.paymentId == paymentId)&&(identical(other.paymentAmount, paymentAmount) || other.paymentAmount == paymentAmount)&&(identical(other.refundStatus, refundStatus) || other.refundStatus == refundStatus)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.user, user) || other.user == user)&&(identical(other.submission, submission) || other.submission == submission));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,eventId,ticketId,userId,status,paymentId,paymentAmount,refundStatus,rejectionReason,createdAt,updatedAt,user,submission);

@override
String toString() {
  return 'EventApplication(id: $id, eventId: $eventId, ticketId: $ticketId, userId: $userId, status: $status, paymentId: $paymentId, paymentAmount: $paymentAmount, refundStatus: $refundStatus, rejectionReason: $rejectionReason, createdAt: $createdAt, updatedAt: $updatedAt, user: $user, submission: $submission)';
}


}

/// @nodoc
abstract mixin class $EventApplicationCopyWith<$Res>  {
  factory $EventApplicationCopyWith(EventApplication value, $Res Function(EventApplication) _then) = _$EventApplicationCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'event_id') String eventId,@JsonKey(name: 'ticket_id') String ticketId,@JsonKey(name: 'user_id') String userId, String status,@JsonKey(name: 'payment_id') String? paymentId,@JsonKey(name: 'payment_amount') int? paymentAmount,@JsonKey(name: 'refund_status') String refundStatus,@JsonKey(name: 'rejection_reason') String? rejectionReason,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt, UserProfile? user, VerificationSubmission? submission
});


$UserProfileCopyWith<$Res>? get user;$VerificationSubmissionCopyWith<$Res>? get submission;

}
/// @nodoc
class _$EventApplicationCopyWithImpl<$Res>
    implements $EventApplicationCopyWith<$Res> {
  _$EventApplicationCopyWithImpl(this._self, this._then);

  final EventApplication _self;
  final $Res Function(EventApplication) _then;

/// Create a copy of EventApplication
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? eventId = null,Object? ticketId = null,Object? userId = null,Object? status = null,Object? paymentId = freezed,Object? paymentAmount = freezed,Object? refundStatus = null,Object? rejectionReason = freezed,Object? createdAt = null,Object? updatedAt = null,Object? user = freezed,Object? submission = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,ticketId: null == ticketId ? _self.ticketId : ticketId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,paymentId: freezed == paymentId ? _self.paymentId : paymentId // ignore: cast_nullable_to_non_nullable
as String?,paymentAmount: freezed == paymentAmount ? _self.paymentAmount : paymentAmount // ignore: cast_nullable_to_non_nullable
as int?,refundStatus: null == refundStatus ? _self.refundStatus : refundStatus // ignore: cast_nullable_to_non_nullable
as String,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as UserProfile?,submission: freezed == submission ? _self.submission : submission // ignore: cast_nullable_to_non_nullable
as VerificationSubmission?,
  ));
}
/// Create a copy of EventApplication
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserProfileCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $UserProfileCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}/// Create a copy of EventApplication
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VerificationSubmissionCopyWith<$Res>? get submission {
    if (_self.submission == null) {
    return null;
  }

  return $VerificationSubmissionCopyWith<$Res>(_self.submission!, (value) {
    return _then(_self.copyWith(submission: value));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'event_id')  String eventId, @JsonKey(name: 'ticket_id')  String ticketId, @JsonKey(name: 'user_id')  String userId,  String status, @JsonKey(name: 'payment_id')  String? paymentId, @JsonKey(name: 'payment_amount')  int? paymentAmount, @JsonKey(name: 'refund_status')  String refundStatus, @JsonKey(name: 'rejection_reason')  String? rejectionReason, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt,  UserProfile? user,  VerificationSubmission? submission)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventApplication() when $default != null:
return $default(_that.id,_that.eventId,_that.ticketId,_that.userId,_that.status,_that.paymentId,_that.paymentAmount,_that.refundStatus,_that.rejectionReason,_that.createdAt,_that.updatedAt,_that.user,_that.submission);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'event_id')  String eventId, @JsonKey(name: 'ticket_id')  String ticketId, @JsonKey(name: 'user_id')  String userId,  String status, @JsonKey(name: 'payment_id')  String? paymentId, @JsonKey(name: 'payment_amount')  int? paymentAmount, @JsonKey(name: 'refund_status')  String refundStatus, @JsonKey(name: 'rejection_reason')  String? rejectionReason, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt,  UserProfile? user,  VerificationSubmission? submission)  $default,) {final _that = this;
switch (_that) {
case _EventApplication():
return $default(_that.id,_that.eventId,_that.ticketId,_that.userId,_that.status,_that.paymentId,_that.paymentAmount,_that.refundStatus,_that.rejectionReason,_that.createdAt,_that.updatedAt,_that.user,_that.submission);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'event_id')  String eventId, @JsonKey(name: 'ticket_id')  String ticketId, @JsonKey(name: 'user_id')  String userId,  String status, @JsonKey(name: 'payment_id')  String? paymentId, @JsonKey(name: 'payment_amount')  int? paymentAmount, @JsonKey(name: 'refund_status')  String refundStatus, @JsonKey(name: 'rejection_reason')  String? rejectionReason, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt,  UserProfile? user,  VerificationSubmission? submission)?  $default,) {final _that = this;
switch (_that) {
case _EventApplication() when $default != null:
return $default(_that.id,_that.eventId,_that.ticketId,_that.userId,_that.status,_that.paymentId,_that.paymentAmount,_that.refundStatus,_that.rejectionReason,_that.createdAt,_that.updatedAt,_that.user,_that.submission);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EventApplication implements EventApplication {
  const _EventApplication({required this.id, @JsonKey(name: 'event_id') required this.eventId, @JsonKey(name: 'ticket_id') required this.ticketId, @JsonKey(name: 'user_id') required this.userId, required this.status, @JsonKey(name: 'payment_id') this.paymentId, @JsonKey(name: 'payment_amount') this.paymentAmount, @JsonKey(name: 'refund_status') this.refundStatus = 'none', @JsonKey(name: 'rejection_reason') this.rejectionReason, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt, this.user, this.submission});
  factory _EventApplication.fromJson(Map<String, dynamic> json) => _$EventApplicationFromJson(json);

@override final  String id;
@override@JsonKey(name: 'event_id') final  String eventId;
@override@JsonKey(name: 'ticket_id') final  String ticketId;
@override@JsonKey(name: 'user_id') final  String userId;
@override final  String status;
// pending, pending_review, approved, rejected, cancelled, paid
@override@JsonKey(name: 'payment_id') final  String? paymentId;
@override@JsonKey(name: 'payment_amount') final  int? paymentAmount;
@override@JsonKey(name: 'refund_status') final  String refundStatus;
@override@JsonKey(name: 'rejection_reason') final  String? rejectionReason;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;
// Relations (Nullable)
@override final  UserProfile? user;
@override final  VerificationSubmission? submission;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventApplication&&(identical(other.id, id) || other.id == id)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.ticketId, ticketId) || other.ticketId == ticketId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.status, status) || other.status == status)&&(identical(other.paymentId, paymentId) || other.paymentId == paymentId)&&(identical(other.paymentAmount, paymentAmount) || other.paymentAmount == paymentAmount)&&(identical(other.refundStatus, refundStatus) || other.refundStatus == refundStatus)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.user, user) || other.user == user)&&(identical(other.submission, submission) || other.submission == submission));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,eventId,ticketId,userId,status,paymentId,paymentAmount,refundStatus,rejectionReason,createdAt,updatedAt,user,submission);

@override
String toString() {
  return 'EventApplication(id: $id, eventId: $eventId, ticketId: $ticketId, userId: $userId, status: $status, paymentId: $paymentId, paymentAmount: $paymentAmount, refundStatus: $refundStatus, rejectionReason: $rejectionReason, createdAt: $createdAt, updatedAt: $updatedAt, user: $user, submission: $submission)';
}


}

/// @nodoc
abstract mixin class _$EventApplicationCopyWith<$Res> implements $EventApplicationCopyWith<$Res> {
  factory _$EventApplicationCopyWith(_EventApplication value, $Res Function(_EventApplication) _then) = __$EventApplicationCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'event_id') String eventId,@JsonKey(name: 'ticket_id') String ticketId,@JsonKey(name: 'user_id') String userId, String status,@JsonKey(name: 'payment_id') String? paymentId,@JsonKey(name: 'payment_amount') int? paymentAmount,@JsonKey(name: 'refund_status') String refundStatus,@JsonKey(name: 'rejection_reason') String? rejectionReason,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt, UserProfile? user, VerificationSubmission? submission
});


@override $UserProfileCopyWith<$Res>? get user;@override $VerificationSubmissionCopyWith<$Res>? get submission;

}
/// @nodoc
class __$EventApplicationCopyWithImpl<$Res>
    implements _$EventApplicationCopyWith<$Res> {
  __$EventApplicationCopyWithImpl(this._self, this._then);

  final _EventApplication _self;
  final $Res Function(_EventApplication) _then;

/// Create a copy of EventApplication
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? eventId = null,Object? ticketId = null,Object? userId = null,Object? status = null,Object? paymentId = freezed,Object? paymentAmount = freezed,Object? refundStatus = null,Object? rejectionReason = freezed,Object? createdAt = null,Object? updatedAt = null,Object? user = freezed,Object? submission = freezed,}) {
  return _then(_EventApplication(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,ticketId: null == ticketId ? _self.ticketId : ticketId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,paymentId: freezed == paymentId ? _self.paymentId : paymentId // ignore: cast_nullable_to_non_nullable
as String?,paymentAmount: freezed == paymentAmount ? _self.paymentAmount : paymentAmount // ignore: cast_nullable_to_non_nullable
as int?,refundStatus: null == refundStatus ? _self.refundStatus : refundStatus // ignore: cast_nullable_to_non_nullable
as String,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as UserProfile?,submission: freezed == submission ? _self.submission : submission // ignore: cast_nullable_to_non_nullable
as VerificationSubmission?,
  ));
}

/// Create a copy of EventApplication
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserProfileCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $UserProfileCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}/// Create a copy of EventApplication
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VerificationSubmissionCopyWith<$Res>? get submission {
    if (_self.submission == null) {
    return null;
  }

  return $VerificationSubmissionCopyWith<$Res>(_self.submission!, (value) {
    return _then(_self.copyWith(submission: value));
  });
}
}

// dart format on
