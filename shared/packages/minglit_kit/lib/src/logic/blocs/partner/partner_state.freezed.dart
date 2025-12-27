// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'partner_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PartnerState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PartnerState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PartnerState()';
}


}

/// @nodoc
class $PartnerStateCopyWith<$Res>  {
$PartnerStateCopyWith(PartnerState _, $Res Function(PartnerState) __);
}


/// Adds pattern-matching-related methods to [PartnerState].
extension PartnerStatePatterns on PartnerState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Initial value)?  initial,TResult Function( _Loading value)?  loading,TResult Function( _ApplicationLoaded value)?  applicationLoaded,TResult Function( _MembersLoaded value)?  membersLoaded,TResult Function( _ApplicationsLoaded value)?  applicationsLoaded,TResult Function( _Success value)?  success,TResult Function( _Failure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _ApplicationLoaded() when applicationLoaded != null:
return applicationLoaded(_that);case _MembersLoaded() when membersLoaded != null:
return membersLoaded(_that);case _ApplicationsLoaded() when applicationsLoaded != null:
return applicationsLoaded(_that);case _Success() when success != null:
return success(_that);case _Failure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Initial value)  initial,required TResult Function( _Loading value)  loading,required TResult Function( _ApplicationLoaded value)  applicationLoaded,required TResult Function( _MembersLoaded value)  membersLoaded,required TResult Function( _ApplicationsLoaded value)  applicationsLoaded,required TResult Function( _Success value)  success,required TResult Function( _Failure value)  failure,}){
final _that = this;
switch (_that) {
case _Initial():
return initial(_that);case _Loading():
return loading(_that);case _ApplicationLoaded():
return applicationLoaded(_that);case _MembersLoaded():
return membersLoaded(_that);case _ApplicationsLoaded():
return applicationsLoaded(_that);case _Success():
return success(_that);case _Failure():
return failure(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Initial value)?  initial,TResult? Function( _Loading value)?  loading,TResult? Function( _ApplicationLoaded value)?  applicationLoaded,TResult? Function( _MembersLoaded value)?  membersLoaded,TResult? Function( _ApplicationsLoaded value)?  applicationsLoaded,TResult? Function( _Success value)?  success,TResult? Function( _Failure value)?  failure,}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _ApplicationLoaded() when applicationLoaded != null:
return applicationLoaded(_that);case _MembersLoaded() when membersLoaded != null:
return membersLoaded(_that);case _ApplicationsLoaded() when applicationsLoaded != null:
return applicationsLoaded(_that);case _Success() when success != null:
return success(_that);case _Failure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( PartnerApplication? application)?  applicationLoaded,TResult Function( List<Map<String, dynamic>> members)?  membersLoaded,TResult Function( List<PartnerApplication> applications)?  applicationsLoaded,TResult Function()?  success,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _ApplicationLoaded() when applicationLoaded != null:
return applicationLoaded(_that.application);case _MembersLoaded() when membersLoaded != null:
return membersLoaded(_that.members);case _ApplicationsLoaded() when applicationsLoaded != null:
return applicationsLoaded(_that.applications);case _Success() when success != null:
return success();case _Failure() when failure != null:
return failure(_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( PartnerApplication? application)  applicationLoaded,required TResult Function( List<Map<String, dynamic>> members)  membersLoaded,required TResult Function( List<PartnerApplication> applications)  applicationsLoaded,required TResult Function()  success,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading();case _ApplicationLoaded():
return applicationLoaded(_that.application);case _MembersLoaded():
return membersLoaded(_that.members);case _ApplicationsLoaded():
return applicationsLoaded(_that.applications);case _Success():
return success();case _Failure():
return failure(_that.failure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( PartnerApplication? application)?  applicationLoaded,TResult? Function( List<Map<String, dynamic>> members)?  membersLoaded,TResult? Function( List<PartnerApplication> applications)?  applicationsLoaded,TResult? Function()?  success,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _ApplicationLoaded() when applicationLoaded != null:
return applicationLoaded(_that.application);case _MembersLoaded() when membersLoaded != null:
return membersLoaded(_that.members);case _ApplicationsLoaded() when applicationsLoaded != null:
return applicationsLoaded(_that.applications);case _Success() when success != null:
return success();case _Failure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements PartnerState {
  const _Initial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PartnerState.initial()';
}


}




/// @nodoc


class _Loading implements PartnerState {
  const _Loading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PartnerState.loading()';
}


}




/// @nodoc


class _ApplicationLoaded implements PartnerState {
  const _ApplicationLoaded(this.application);
  

 final  PartnerApplication? application;

/// Create a copy of PartnerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApplicationLoadedCopyWith<_ApplicationLoaded> get copyWith => __$ApplicationLoadedCopyWithImpl<_ApplicationLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApplicationLoaded&&(identical(other.application, application) || other.application == application));
}


@override
int get hashCode => Object.hash(runtimeType,application);

@override
String toString() {
  return 'PartnerState.applicationLoaded(application: $application)';
}


}

/// @nodoc
abstract mixin class _$ApplicationLoadedCopyWith<$Res> implements $PartnerStateCopyWith<$Res> {
  factory _$ApplicationLoadedCopyWith(_ApplicationLoaded value, $Res Function(_ApplicationLoaded) _then) = __$ApplicationLoadedCopyWithImpl;
@useResult
$Res call({
 PartnerApplication? application
});


$PartnerApplicationCopyWith<$Res>? get application;

}
/// @nodoc
class __$ApplicationLoadedCopyWithImpl<$Res>
    implements _$ApplicationLoadedCopyWith<$Res> {
  __$ApplicationLoadedCopyWithImpl(this._self, this._then);

  final _ApplicationLoaded _self;
  final $Res Function(_ApplicationLoaded) _then;

/// Create a copy of PartnerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? application = freezed,}) {
  return _then(_ApplicationLoaded(
freezed == application ? _self.application : application // ignore: cast_nullable_to_non_nullable
as PartnerApplication?,
  ));
}

/// Create a copy of PartnerState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PartnerApplicationCopyWith<$Res>? get application {
    if (_self.application == null) {
    return null;
  }

  return $PartnerApplicationCopyWith<$Res>(_self.application!, (value) {
    return _then(_self.copyWith(application: value));
  });
}
}

/// @nodoc


class _MembersLoaded implements PartnerState {
  const _MembersLoaded(final  List<Map<String, dynamic>> members): _members = members;
  

 final  List<Map<String, dynamic>> _members;
 List<Map<String, dynamic>> get members {
  if (_members is EqualUnmodifiableListView) return _members;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_members);
}


/// Create a copy of PartnerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MembersLoadedCopyWith<_MembersLoaded> get copyWith => __$MembersLoadedCopyWithImpl<_MembersLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MembersLoaded&&const DeepCollectionEquality().equals(other._members, _members));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_members));

@override
String toString() {
  return 'PartnerState.membersLoaded(members: $members)';
}


}

/// @nodoc
abstract mixin class _$MembersLoadedCopyWith<$Res> implements $PartnerStateCopyWith<$Res> {
  factory _$MembersLoadedCopyWith(_MembersLoaded value, $Res Function(_MembersLoaded) _then) = __$MembersLoadedCopyWithImpl;
@useResult
$Res call({
 List<Map<String, dynamic>> members
});




}
/// @nodoc
class __$MembersLoadedCopyWithImpl<$Res>
    implements _$MembersLoadedCopyWith<$Res> {
  __$MembersLoadedCopyWithImpl(this._self, this._then);

  final _MembersLoaded _self;
  final $Res Function(_MembersLoaded) _then;

/// Create a copy of PartnerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? members = null,}) {
  return _then(_MembersLoaded(
null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,
  ));
}


}

/// @nodoc


class _ApplicationsLoaded implements PartnerState {
  const _ApplicationsLoaded(final  List<PartnerApplication> applications): _applications = applications;
  

 final  List<PartnerApplication> _applications;
 List<PartnerApplication> get applications {
  if (_applications is EqualUnmodifiableListView) return _applications;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_applications);
}


/// Create a copy of PartnerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApplicationsLoadedCopyWith<_ApplicationsLoaded> get copyWith => __$ApplicationsLoadedCopyWithImpl<_ApplicationsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApplicationsLoaded&&const DeepCollectionEquality().equals(other._applications, _applications));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_applications));

@override
String toString() {
  return 'PartnerState.applicationsLoaded(applications: $applications)';
}


}

/// @nodoc
abstract mixin class _$ApplicationsLoadedCopyWith<$Res> implements $PartnerStateCopyWith<$Res> {
  factory _$ApplicationsLoadedCopyWith(_ApplicationsLoaded value, $Res Function(_ApplicationsLoaded) _then) = __$ApplicationsLoadedCopyWithImpl;
@useResult
$Res call({
 List<PartnerApplication> applications
});




}
/// @nodoc
class __$ApplicationsLoadedCopyWithImpl<$Res>
    implements _$ApplicationsLoadedCopyWith<$Res> {
  __$ApplicationsLoadedCopyWithImpl(this._self, this._then);

  final _ApplicationsLoaded _self;
  final $Res Function(_ApplicationsLoaded) _then;

/// Create a copy of PartnerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? applications = null,}) {
  return _then(_ApplicationsLoaded(
null == applications ? _self._applications : applications // ignore: cast_nullable_to_non_nullable
as List<PartnerApplication>,
  ));
}


}

/// @nodoc


class _Success implements PartnerState {
  const _Success();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Success);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PartnerState.success()';
}


}




/// @nodoc


class _Failure implements PartnerState {
  const _Failure(this.failure);
  

 final  Failure failure;

/// Create a copy of PartnerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FailureCopyWith<_Failure> get copyWith => __$FailureCopyWithImpl<_Failure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Failure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'PartnerState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$FailureCopyWith<$Res> implements $PartnerStateCopyWith<$Res> {
  factory _$FailureCopyWith(_Failure value, $Res Function(_Failure) _then) = __$FailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class __$FailureCopyWithImpl<$Res>
    implements _$FailureCopyWith<$Res> {
  __$FailureCopyWithImpl(this._self, this._then);

  final _Failure _self;
  final $Res Function(_Failure) _then;

/// Create a copy of PartnerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(_Failure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of PartnerState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res> get failure {
  
  return $FailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

// dart format on
