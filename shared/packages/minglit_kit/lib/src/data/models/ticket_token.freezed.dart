// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ticket_token.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TicketToken {

 String get ticketId; String get eventId; String get userId; String get signature; DateTime get expiresAt;
/// Create a copy of TicketToken
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TicketTokenCopyWith<TicketToken> get copyWith => _$TicketTokenCopyWithImpl<TicketToken>(this as TicketToken, _$identity);

  /// Serializes this TicketToken to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TicketToken&&(identical(other.ticketId, ticketId) || other.ticketId == ticketId)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.signature, signature) || other.signature == signature)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ticketId,eventId,userId,signature,expiresAt);

@override
String toString() {
  return 'TicketToken(ticketId: $ticketId, eventId: $eventId, userId: $userId, signature: $signature, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $TicketTokenCopyWith<$Res>  {
  factory $TicketTokenCopyWith(TicketToken value, $Res Function(TicketToken) _then) = _$TicketTokenCopyWithImpl;
@useResult
$Res call({
 String ticketId, String eventId, String userId, String signature, DateTime expiresAt
});




}
/// @nodoc
class _$TicketTokenCopyWithImpl<$Res>
    implements $TicketTokenCopyWith<$Res> {
  _$TicketTokenCopyWithImpl(this._self, this._then);

  final TicketToken _self;
  final $Res Function(TicketToken) _then;

/// Create a copy of TicketToken
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ticketId = null,Object? eventId = null,Object? userId = null,Object? signature = null,Object? expiresAt = null,}) {
  return _then(_self.copyWith(
ticketId: null == ticketId ? _self.ticketId : ticketId // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,signature: null == signature ? _self.signature : signature // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [TicketToken].
extension TicketTokenPatterns on TicketToken {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TicketToken value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TicketToken() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TicketToken value)  $default,){
final _that = this;
switch (_that) {
case _TicketToken():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TicketToken value)?  $default,){
final _that = this;
switch (_that) {
case _TicketToken() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String ticketId,  String eventId,  String userId,  String signature,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TicketToken() when $default != null:
return $default(_that.ticketId,_that.eventId,_that.userId,_that.signature,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String ticketId,  String eventId,  String userId,  String signature,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _TicketToken():
return $default(_that.ticketId,_that.eventId,_that.userId,_that.signature,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String ticketId,  String eventId,  String userId,  String signature,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _TicketToken() when $default != null:
return $default(_that.ticketId,_that.eventId,_that.userId,_that.signature,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TicketToken implements TicketToken {
  const _TicketToken({required this.ticketId, required this.eventId, required this.userId, required this.signature, required this.expiresAt});
  factory _TicketToken.fromJson(Map<String, dynamic> json) => _$TicketTokenFromJson(json);

@override final  String ticketId;
@override final  String eventId;
@override final  String userId;
@override final  String signature;
@override final  DateTime expiresAt;

/// Create a copy of TicketToken
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TicketTokenCopyWith<_TicketToken> get copyWith => __$TicketTokenCopyWithImpl<_TicketToken>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TicketTokenToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TicketToken&&(identical(other.ticketId, ticketId) || other.ticketId == ticketId)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.signature, signature) || other.signature == signature)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ticketId,eventId,userId,signature,expiresAt);

@override
String toString() {
  return 'TicketToken(ticketId: $ticketId, eventId: $eventId, userId: $userId, signature: $signature, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$TicketTokenCopyWith<$Res> implements $TicketTokenCopyWith<$Res> {
  factory _$TicketTokenCopyWith(_TicketToken value, $Res Function(_TicketToken) _then) = __$TicketTokenCopyWithImpl;
@override @useResult
$Res call({
 String ticketId, String eventId, String userId, String signature, DateTime expiresAt
});




}
/// @nodoc
class __$TicketTokenCopyWithImpl<$Res>
    implements _$TicketTokenCopyWith<$Res> {
  __$TicketTokenCopyWithImpl(this._self, this._then);

  final _TicketToken _self;
  final $Res Function(_TicketToken) _then;

/// Create a copy of TicketToken
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ticketId = null,Object? eventId = null,Object? userId = null,Object? signature = null,Object? expiresAt = null,}) {
  return _then(_TicketToken(
ticketId: null == ticketId ? _self.ticketId : ticketId // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,signature: null == signature ? _self.signature : signature // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
