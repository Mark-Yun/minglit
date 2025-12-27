// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'verification_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$VerificationState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerificationState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'VerificationState()';
}


}

/// @nodoc
class $VerificationStateCopyWith<$Res>  {
$VerificationStateCopyWith(VerificationState _, $Res Function(VerificationState) __);
}


/// Adds pattern-matching-related methods to [VerificationState].
extension VerificationStatePatterns on VerificationState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Initial value)?  initial,TResult Function( _Loading value)?  loading,TResult Function( _RequirementsLoaded value)?  requirementsLoaded,TResult Function( _PendingRequestsLoaded value)?  pendingRequestsLoaded,TResult Function( _CorrectionRequestsLoaded value)?  correctionRequestsLoaded,TResult Function( _CommentsLoaded value)?  commentsLoaded,TResult Function( _Success value)?  success,TResult Function( _Failure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _RequirementsLoaded() when requirementsLoaded != null:
return requirementsLoaded(_that);case _PendingRequestsLoaded() when pendingRequestsLoaded != null:
return pendingRequestsLoaded(_that);case _CorrectionRequestsLoaded() when correctionRequestsLoaded != null:
return correctionRequestsLoaded(_that);case _CommentsLoaded() when commentsLoaded != null:
return commentsLoaded(_that);case _Success() when success != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Initial value)  initial,required TResult Function( _Loading value)  loading,required TResult Function( _RequirementsLoaded value)  requirementsLoaded,required TResult Function( _PendingRequestsLoaded value)  pendingRequestsLoaded,required TResult Function( _CorrectionRequestsLoaded value)  correctionRequestsLoaded,required TResult Function( _CommentsLoaded value)  commentsLoaded,required TResult Function( _Success value)  success,required TResult Function( _Failure value)  failure,}){
final _that = this;
switch (_that) {
case _Initial():
return initial(_that);case _Loading():
return loading(_that);case _RequirementsLoaded():
return requirementsLoaded(_that);case _PendingRequestsLoaded():
return pendingRequestsLoaded(_that);case _CorrectionRequestsLoaded():
return correctionRequestsLoaded(_that);case _CommentsLoaded():
return commentsLoaded(_that);case _Success():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Initial value)?  initial,TResult? Function( _Loading value)?  loading,TResult? Function( _RequirementsLoaded value)?  requirementsLoaded,TResult? Function( _PendingRequestsLoaded value)?  pendingRequestsLoaded,TResult? Function( _CorrectionRequestsLoaded value)?  correctionRequestsLoaded,TResult? Function( _CommentsLoaded value)?  commentsLoaded,TResult? Function( _Success value)?  success,TResult? Function( _Failure value)?  failure,}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _RequirementsLoaded() when requirementsLoaded != null:
return requirementsLoaded(_that);case _PendingRequestsLoaded() when pendingRequestsLoaded != null:
return pendingRequestsLoaded(_that);case _CorrectionRequestsLoaded() when correctionRequestsLoaded != null:
return correctionRequestsLoaded(_that);case _CommentsLoaded() when commentsLoaded != null:
return commentsLoaded(_that);case _Success() when success != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<VerificationRequirementStatus> requirements)?  requirementsLoaded,TResult Function( List<Map<String, dynamic>> requests)?  pendingRequestsLoaded,TResult Function( List<Map<String, dynamic>> requests)?  correctionRequestsLoaded,TResult Function( List<Map<String, dynamic>> comments)?  commentsLoaded,TResult Function()?  success,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _RequirementsLoaded() when requirementsLoaded != null:
return requirementsLoaded(_that.requirements);case _PendingRequestsLoaded() when pendingRequestsLoaded != null:
return pendingRequestsLoaded(_that.requests);case _CorrectionRequestsLoaded() when correctionRequestsLoaded != null:
return correctionRequestsLoaded(_that.requests);case _CommentsLoaded() when commentsLoaded != null:
return commentsLoaded(_that.comments);case _Success() when success != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<VerificationRequirementStatus> requirements)  requirementsLoaded,required TResult Function( List<Map<String, dynamic>> requests)  pendingRequestsLoaded,required TResult Function( List<Map<String, dynamic>> requests)  correctionRequestsLoaded,required TResult Function( List<Map<String, dynamic>> comments)  commentsLoaded,required TResult Function()  success,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading();case _RequirementsLoaded():
return requirementsLoaded(_that.requirements);case _PendingRequestsLoaded():
return pendingRequestsLoaded(_that.requests);case _CorrectionRequestsLoaded():
return correctionRequestsLoaded(_that.requests);case _CommentsLoaded():
return commentsLoaded(_that.comments);case _Success():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<VerificationRequirementStatus> requirements)?  requirementsLoaded,TResult? Function( List<Map<String, dynamic>> requests)?  pendingRequestsLoaded,TResult? Function( List<Map<String, dynamic>> requests)?  correctionRequestsLoaded,TResult? Function( List<Map<String, dynamic>> comments)?  commentsLoaded,TResult? Function()?  success,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _RequirementsLoaded() when requirementsLoaded != null:
return requirementsLoaded(_that.requirements);case _PendingRequestsLoaded() when pendingRequestsLoaded != null:
return pendingRequestsLoaded(_that.requests);case _CorrectionRequestsLoaded() when correctionRequestsLoaded != null:
return correctionRequestsLoaded(_that.requests);case _CommentsLoaded() when commentsLoaded != null:
return commentsLoaded(_that.comments);case _Success() when success != null:
return success();case _Failure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements VerificationState {
  const _Initial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'VerificationState.initial()';
}


}




/// @nodoc


class _Loading implements VerificationState {
  const _Loading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'VerificationState.loading()';
}


}




/// @nodoc


class _RequirementsLoaded implements VerificationState {
  const _RequirementsLoaded(final  List<VerificationRequirementStatus> requirements): _requirements = requirements;
  

 final  List<VerificationRequirementStatus> _requirements;
 List<VerificationRequirementStatus> get requirements {
  if (_requirements is EqualUnmodifiableListView) return _requirements;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_requirements);
}


/// Create a copy of VerificationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RequirementsLoadedCopyWith<_RequirementsLoaded> get copyWith => __$RequirementsLoadedCopyWithImpl<_RequirementsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RequirementsLoaded&&const DeepCollectionEquality().equals(other._requirements, _requirements));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_requirements));

@override
String toString() {
  return 'VerificationState.requirementsLoaded(requirements: $requirements)';
}


}

/// @nodoc
abstract mixin class _$RequirementsLoadedCopyWith<$Res> implements $VerificationStateCopyWith<$Res> {
  factory _$RequirementsLoadedCopyWith(_RequirementsLoaded value, $Res Function(_RequirementsLoaded) _then) = __$RequirementsLoadedCopyWithImpl;
@useResult
$Res call({
 List<VerificationRequirementStatus> requirements
});




}
/// @nodoc
class __$RequirementsLoadedCopyWithImpl<$Res>
    implements _$RequirementsLoadedCopyWith<$Res> {
  __$RequirementsLoadedCopyWithImpl(this._self, this._then);

  final _RequirementsLoaded _self;
  final $Res Function(_RequirementsLoaded) _then;

/// Create a copy of VerificationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? requirements = null,}) {
  return _then(_RequirementsLoaded(
null == requirements ? _self._requirements : requirements // ignore: cast_nullable_to_non_nullable
as List<VerificationRequirementStatus>,
  ));
}


}

/// @nodoc


class _PendingRequestsLoaded implements VerificationState {
  const _PendingRequestsLoaded(final  List<Map<String, dynamic>> requests): _requests = requests;
  

 final  List<Map<String, dynamic>> _requests;
 List<Map<String, dynamic>> get requests {
  if (_requests is EqualUnmodifiableListView) return _requests;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_requests);
}


/// Create a copy of VerificationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingRequestsLoadedCopyWith<_PendingRequestsLoaded> get copyWith => __$PendingRequestsLoadedCopyWithImpl<_PendingRequestsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingRequestsLoaded&&const DeepCollectionEquality().equals(other._requests, _requests));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_requests));

@override
String toString() {
  return 'VerificationState.pendingRequestsLoaded(requests: $requests)';
}


}

/// @nodoc
abstract mixin class _$PendingRequestsLoadedCopyWith<$Res> implements $VerificationStateCopyWith<$Res> {
  factory _$PendingRequestsLoadedCopyWith(_PendingRequestsLoaded value, $Res Function(_PendingRequestsLoaded) _then) = __$PendingRequestsLoadedCopyWithImpl;
@useResult
$Res call({
 List<Map<String, dynamic>> requests
});




}
/// @nodoc
class __$PendingRequestsLoadedCopyWithImpl<$Res>
    implements _$PendingRequestsLoadedCopyWith<$Res> {
  __$PendingRequestsLoadedCopyWithImpl(this._self, this._then);

  final _PendingRequestsLoaded _self;
  final $Res Function(_PendingRequestsLoaded) _then;

/// Create a copy of VerificationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? requests = null,}) {
  return _then(_PendingRequestsLoaded(
null == requests ? _self._requests : requests // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,
  ));
}


}

/// @nodoc


class _CorrectionRequestsLoaded implements VerificationState {
  const _CorrectionRequestsLoaded(final  List<Map<String, dynamic>> requests): _requests = requests;
  

 final  List<Map<String, dynamic>> _requests;
 List<Map<String, dynamic>> get requests {
  if (_requests is EqualUnmodifiableListView) return _requests;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_requests);
}


/// Create a copy of VerificationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CorrectionRequestsLoadedCopyWith<_CorrectionRequestsLoaded> get copyWith => __$CorrectionRequestsLoadedCopyWithImpl<_CorrectionRequestsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CorrectionRequestsLoaded&&const DeepCollectionEquality().equals(other._requests, _requests));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_requests));

@override
String toString() {
  return 'VerificationState.correctionRequestsLoaded(requests: $requests)';
}


}

/// @nodoc
abstract mixin class _$CorrectionRequestsLoadedCopyWith<$Res> implements $VerificationStateCopyWith<$Res> {
  factory _$CorrectionRequestsLoadedCopyWith(_CorrectionRequestsLoaded value, $Res Function(_CorrectionRequestsLoaded) _then) = __$CorrectionRequestsLoadedCopyWithImpl;
@useResult
$Res call({
 List<Map<String, dynamic>> requests
});




}
/// @nodoc
class __$CorrectionRequestsLoadedCopyWithImpl<$Res>
    implements _$CorrectionRequestsLoadedCopyWith<$Res> {
  __$CorrectionRequestsLoadedCopyWithImpl(this._self, this._then);

  final _CorrectionRequestsLoaded _self;
  final $Res Function(_CorrectionRequestsLoaded) _then;

/// Create a copy of VerificationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? requests = null,}) {
  return _then(_CorrectionRequestsLoaded(
null == requests ? _self._requests : requests // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,
  ));
}


}

/// @nodoc


class _CommentsLoaded implements VerificationState {
  const _CommentsLoaded(final  List<Map<String, dynamic>> comments): _comments = comments;
  

 final  List<Map<String, dynamic>> _comments;
 List<Map<String, dynamic>> get comments {
  if (_comments is EqualUnmodifiableListView) return _comments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_comments);
}


/// Create a copy of VerificationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommentsLoadedCopyWith<_CommentsLoaded> get copyWith => __$CommentsLoadedCopyWithImpl<_CommentsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommentsLoaded&&const DeepCollectionEquality().equals(other._comments, _comments));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_comments));

@override
String toString() {
  return 'VerificationState.commentsLoaded(comments: $comments)';
}


}

/// @nodoc
abstract mixin class _$CommentsLoadedCopyWith<$Res> implements $VerificationStateCopyWith<$Res> {
  factory _$CommentsLoadedCopyWith(_CommentsLoaded value, $Res Function(_CommentsLoaded) _then) = __$CommentsLoadedCopyWithImpl;
@useResult
$Res call({
 List<Map<String, dynamic>> comments
});




}
/// @nodoc
class __$CommentsLoadedCopyWithImpl<$Res>
    implements _$CommentsLoadedCopyWith<$Res> {
  __$CommentsLoadedCopyWithImpl(this._self, this._then);

  final _CommentsLoaded _self;
  final $Res Function(_CommentsLoaded) _then;

/// Create a copy of VerificationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? comments = null,}) {
  return _then(_CommentsLoaded(
null == comments ? _self._comments : comments // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,
  ));
}


}

/// @nodoc


class _Success implements VerificationState {
  const _Success();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Success);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'VerificationState.success()';
}


}




/// @nodoc


class _Failure implements VerificationState {
  const _Failure(this.failure);
  

 final  Failure failure;

/// Create a copy of VerificationState
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
  return 'VerificationState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$FailureCopyWith<$Res> implements $VerificationStateCopyWith<$Res> {
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

/// Create a copy of VerificationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(_Failure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of VerificationState
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
