// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_consent.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserConsent {

String get id;@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'consent_key') ConsentType get consentKey;bool get consented;@JsonKey(name: 'policy_version') int? get policyVersion;@JsonKey(name: 'consented_at') DateTime get consentedAt;@JsonKey(name: 'withdrawn_at') DateTime? get withdrawnAt;@JsonKey(name: 'created_at') DateTime get createdAt;
/// Create a copy of UserConsent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserConsentCopyWith<UserConsent> get copyWith => _$UserConsentCopyWithImpl<UserConsent>(this as UserConsent, _$identity);

  /// Serializes this UserConsent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserConsent&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.consentKey, consentKey) || other.consentKey == consentKey)&&(identical(other.consented, consented) || other.consented == consented)&&(identical(other.policyVersion, policyVersion) || other.policyVersion == policyVersion)&&(identical(other.consentedAt, consentedAt) || other.consentedAt == consentedAt)&&(identical(other.withdrawnAt, withdrawnAt) || other.withdrawnAt == withdrawnAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,consentKey,consented,policyVersion,consentedAt,withdrawnAt,createdAt);

@override
String toString() {
  return 'UserConsent(id: $id, userId: $userId, consentKey: $consentKey, consented: $consented, policyVersion: $policyVersion, consentedAt: $consentedAt, withdrawnAt: $withdrawnAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $UserConsentCopyWith<$Res>  {
  factory $UserConsentCopyWith(UserConsent value, $Res Function(UserConsent) _then) = _$UserConsentCopyWithImpl;
@useResult
$Res call({
String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'consent_key') ConsentType consentKey,bool consented,@JsonKey(name: 'policy_version') int? policyVersion,@JsonKey(name: 'consented_at') DateTime consentedAt,@JsonKey(name: 'withdrawn_at') DateTime? withdrawnAt,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class _$UserConsentCopyWithImpl<$Res>
    implements $UserConsentCopyWith<$Res> {
  _$UserConsentCopyWithImpl(this._self, this._then);

  final UserConsent _self;
  final $Res Function(UserConsent) _then;

/// Create a copy of UserConsent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? consentKey = null,Object? consented = null,Object? policyVersion = freezed,Object? consentedAt = null,Object? withdrawnAt = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,consentKey: null == consentKey ? _self.consentKey : consentKey // ignore: cast_nullable_to_non_nullable
as ConsentType,consented: null == consented ? _self.consented : consented // ignore: cast_nullable_to_non_nullable
as bool,policyVersion: freezed == policyVersion ? _self.policyVersion : policyVersion // ignore: cast_nullable_to_non_nullable
as int?,consentedAt: null == consentedAt ? _self.consentedAt : consentedAt // ignore: cast_nullable_to_non_nullable
as DateTime,withdrawnAt: freezed == withdrawnAt ? _self.withdrawnAt : withdrawnAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [UserConsent].
extension UserConsentPatterns on UserConsent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserConsent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserConsent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserConsent value)  $default,){
final _that = this;
switch (_that) {
case _UserConsent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserConsent value)?  $default,){
final _that = this;
switch (_that) {
case _UserConsent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'consent_key')  ConsentType consentKey,  bool consented, @JsonKey(name: 'policy_version')  int? policyVersion, @JsonKey(name: 'consented_at')  DateTime consentedAt, @JsonKey(name: 'withdrawn_at')  DateTime? withdrawnAt, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserConsent() when $default != null:
return $default(_that.id,_that.userId,_that.consentKey,_that.consented,_that.policyVersion,_that.consentedAt,_that.withdrawnAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'consent_key')  ConsentType consentKey,  bool consented, @JsonKey(name: 'policy_version')  int? policyVersion, @JsonKey(name: 'consented_at')  DateTime consentedAt, @JsonKey(name: 'withdrawn_at')  DateTime? withdrawnAt, @JsonKey(name: 'created_at')  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _UserConsent():
return $default(_that.id,_that.userId,_that.consentKey,_that.consented,_that.policyVersion,_that.consentedAt,_that.withdrawnAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'consent_key')  ConsentType consentKey,  bool consented, @JsonKey(name: 'policy_version')  int? policyVersion, @JsonKey(name: 'consented_at')  DateTime consentedAt, @JsonKey(name: 'withdrawn_at')  DateTime? withdrawnAt, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _UserConsent() when $default != null:
return $default(_that.id,_that.userId,_that.consentKey,_that.consented,_that.policyVersion,_that.consentedAt,_that.withdrawnAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserConsent implements UserConsent {
  const _UserConsent({required this.id, @JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'consent_key') required this.consentKey, required this.consented, @JsonKey(name: 'policy_version') this.policyVersion, @JsonKey(name: 'consented_at') required this.consentedAt, @JsonKey(name: 'withdrawn_at') this.withdrawnAt, @JsonKey(name: 'created_at') required this.createdAt});
  factory _UserConsent.fromJson(Map<String, dynamic> json) => _$UserConsentFromJson(json);

@override final  String id;
@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'consent_key') final  ConsentType consentKey;
@override final  bool consented;
@override@JsonKey(name: 'policy_version') final  int? policyVersion;
@override@JsonKey(name: 'consented_at') final  DateTime consentedAt;
@override@JsonKey(name: 'withdrawn_at') final  DateTime? withdrawnAt;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;

/// Create a copy of UserConsent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserConsentCopyWith<_UserConsent> get copyWith => __$UserConsentCopyWithImpl<_UserConsent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserConsentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserConsent&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.consentKey, consentKey) || other.consentKey == consentKey)&&(identical(other.consented, consented) || other.consented == consented)&&(identical(other.policyVersion, policyVersion) || other.policyVersion == policyVersion)&&(identical(other.consentedAt, consentedAt) || other.consentedAt == consentedAt)&&(identical(other.withdrawnAt, withdrawnAt) || other.withdrawnAt == withdrawnAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,consentKey,consented,policyVersion,consentedAt,withdrawnAt,createdAt);

@override
String toString() {
  return 'UserConsent(id: $id, userId: $userId, consentKey: $consentKey, consented: $consented, policyVersion: $policyVersion, consentedAt: $consentedAt, withdrawnAt: $withdrawnAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$UserConsentCopyWith<$Res> implements $UserConsentCopyWith<$Res> {
  factory _$UserConsentCopyWith(_UserConsent value, $Res Function(_UserConsent) _then) = __$UserConsentCopyWithImpl;
@override @useResult
$Res call({
String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'consent_key') ConsentType consentKey,bool consented,@JsonKey(name: 'policy_version') int? policyVersion,@JsonKey(name: 'consented_at') DateTime consentedAt,@JsonKey(name: 'withdrawn_at') DateTime? withdrawnAt,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class __$UserConsentCopyWithImpl<$Res>
    implements _$UserConsentCopyWith<$Res> {
  __$UserConsentCopyWithImpl(this._self, this._then);

  final _UserConsent _self;
  final $Res Function(_UserConsent) _then;

/// Create a copy of UserConsent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? consentKey = null,Object? consented = null,Object? policyVersion = freezed,Object? consentedAt = null,Object? withdrawnAt = freezed,Object? createdAt = null,}) {
  return _then(_UserConsent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,consentKey: null == consentKey ? _self.consentKey : consentKey // ignore: cast_nullable_to_non_nullable
as ConsentType,consented: null == consented ? _self.consented : consented // ignore: cast_nullable_to_non_nullable
as bool,policyVersion: freezed == policyVersion ? _self.policyVersion : policyVersion // ignore: cast_nullable_to_non_nullable
as int?,consentedAt: null == consentedAt ? _self.consentedAt : consentedAt // ignore: cast_nullable_to_non_nullable
as DateTime,withdrawnAt: freezed == withdrawnAt ? _self.withdrawnAt : withdrawnAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$ConsentInput {

@JsonKey(name: 'consent_key') ConsentType get consentKey;bool get consented;@JsonKey(name: 'policy_version') int? get policyVersion;
/// Create a copy of ConsentInput
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConsentInputCopyWith<ConsentInput> get copyWith => _$ConsentInputCopyWithImpl<ConsentInput>(this as ConsentInput, _$identity);

  /// Serializes this ConsentInput to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConsentInput&&(identical(other.consentKey, consentKey) || other.consentKey == consentKey)&&(identical(other.consented, consented) || other.consented == consented)&&(identical(other.policyVersion, policyVersion) || other.policyVersion == policyVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,consentKey,consented,policyVersion);

@override
String toString() {
  return 'ConsentInput(consentKey: $consentKey, consented: $consented, policyVersion: $policyVersion)';
}


}

/// @nodoc
abstract mixin class $ConsentInputCopyWith<$Res>  {
  factory $ConsentInputCopyWith(ConsentInput value, $Res Function(ConsentInput) _then) = _$ConsentInputCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'consent_key') ConsentType consentKey,bool consented,@JsonKey(name: 'policy_version') int? policyVersion
});




}
/// @nodoc
class _$ConsentInputCopyWithImpl<$Res>
    implements $ConsentInputCopyWith<$Res> {
  _$ConsentInputCopyWithImpl(this._self, this._then);

  final ConsentInput _self;
  final $Res Function(ConsentInput) _then;

/// Create a copy of ConsentInput
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? consentKey = null,Object? consented = null,Object? policyVersion = freezed,}) {
  return _then(_self.copyWith(
consentKey: null == consentKey ? _self.consentKey : consentKey // ignore: cast_nullable_to_non_nullable
as ConsentType,consented: null == consented ? _self.consented : consented // ignore: cast_nullable_to_non_nullable
as bool,policyVersion: freezed == policyVersion ? _self.policyVersion : policyVersion // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ConsentInput].
extension ConsentInputPatterns on ConsentInput {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConsentInput value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConsentInput() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConsentInput value)  $default,){
final _that = this;
switch (_that) {
case _ConsentInput():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConsentInput value)?  $default,){
final _that = this;
switch (_that) {
case _ConsentInput() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'consent_key')  ConsentType consentKey,  bool consented, @JsonKey(name: 'policy_version')  int? policyVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConsentInput() when $default != null:
return $default(_that.consentKey,_that.consented,_that.policyVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'consent_key')  ConsentType consentKey,  bool consented, @JsonKey(name: 'policy_version')  int? policyVersion)  $default,) {final _that = this;
switch (_that) {
case _ConsentInput():
return $default(_that.consentKey,_that.consented,_that.policyVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'consent_key')  ConsentType consentKey,  bool consented, @JsonKey(name: 'policy_version')  int? policyVersion)?  $default,) {final _that = this;
switch (_that) {
case _ConsentInput() when $default != null:
return $default(_that.consentKey,_that.consented,_that.policyVersion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ConsentInput implements ConsentInput {
  const _ConsentInput({@JsonKey(name: 'consent_key') required this.consentKey, required this.consented, @JsonKey(name: 'policy_version') this.policyVersion});
  factory _ConsentInput.fromJson(Map<String, dynamic> json) => _$ConsentInputFromJson(json);

@override@JsonKey(name: 'consent_key') final  ConsentType consentKey;
@override final  bool consented;
@override@JsonKey(name: 'policy_version') final  int? policyVersion;

/// Create a copy of ConsentInput
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConsentInputCopyWith<_ConsentInput> get copyWith => __$ConsentInputCopyWithImpl<_ConsentInput>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConsentInputToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConsentInput&&(identical(other.consentKey, consentKey) || other.consentKey == consentKey)&&(identical(other.consented, consented) || other.consented == consented)&&(identical(other.policyVersion, policyVersion) || other.policyVersion == policyVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,consentKey,consented,policyVersion);

@override
String toString() {
  return 'ConsentInput(consentKey: $consentKey, consented: $consented, policyVersion: $policyVersion)';
}


}

/// @nodoc
abstract mixin class _$ConsentInputCopyWith<$Res> implements $ConsentInputCopyWith<$Res> {
  factory _$ConsentInputCopyWith(_ConsentInput value, $Res Function(_ConsentInput) _then) = __$ConsentInputCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'consent_key') ConsentType consentKey,bool consented,@JsonKey(name: 'policy_version') int? policyVersion
});




}
/// @nodoc
class __$ConsentInputCopyWithImpl<$Res>
    implements _$ConsentInputCopyWith<$Res> {
  __$ConsentInputCopyWithImpl(this._self, this._then);

  final _ConsentInput _self;
  final $Res Function(_ConsentInput) _then;

/// Create a copy of ConsentInput
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? consentKey = null,Object? consented = null,Object? policyVersion = freezed,}) {
  return _then(_ConsentInput(
consentKey: null == consentKey ? _self.consentKey : consentKey // ignore: cast_nullable_to_non_nullable
as ConsentType,consented: null == consented ? _self.consented : consented // ignore: cast_nullable_to_non_nullable
as bool,policyVersion: freezed == policyVersion ? _self.policyVersion : policyVersion // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
