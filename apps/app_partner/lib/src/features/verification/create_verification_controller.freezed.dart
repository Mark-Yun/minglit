// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'create_verification_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CreateVerificationState {

 String get displayName; String get internalName; String get description; List<VerificationFormField> get fields; bool get isSubmitting; String? get error;
/// Create a copy of CreateVerificationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateVerificationStateCopyWith<CreateVerificationState> get copyWith => _$CreateVerificationStateCopyWithImpl<CreateVerificationState>(this as CreateVerificationState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateVerificationState&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.internalName, internalName) || other.internalName == internalName)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.fields, fields)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,displayName,internalName,description,const DeepCollectionEquality().hash(fields),isSubmitting,error);

@override
String toString() {
  return 'CreateVerificationState(displayName: $displayName, internalName: $internalName, description: $description, fields: $fields, isSubmitting: $isSubmitting, error: $error)';
}


}

/// @nodoc
abstract mixin class $CreateVerificationStateCopyWith<$Res>  {
  factory $CreateVerificationStateCopyWith(CreateVerificationState value, $Res Function(CreateVerificationState) _then) = _$CreateVerificationStateCopyWithImpl;
@useResult
$Res call({
 String displayName, String internalName, String description, List<VerificationFormField> fields, bool isSubmitting, String? error
});




}
/// @nodoc
class _$CreateVerificationStateCopyWithImpl<$Res>
    implements $CreateVerificationStateCopyWith<$Res> {
  _$CreateVerificationStateCopyWithImpl(this._self, this._then);

  final CreateVerificationState _self;
  final $Res Function(CreateVerificationState) _then;

/// Create a copy of CreateVerificationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? displayName = null,Object? internalName = null,Object? description = null,Object? fields = null,Object? isSubmitting = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,internalName: null == internalName ? _self.internalName : internalName // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,fields: null == fields ? _self.fields : fields // ignore: cast_nullable_to_non_nullable
as List<VerificationFormField>,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateVerificationState].
extension CreateVerificationStatePatterns on CreateVerificationState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateVerificationState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateVerificationState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateVerificationState value)  $default,){
final _that = this;
switch (_that) {
case _CreateVerificationState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateVerificationState value)?  $default,){
final _that = this;
switch (_that) {
case _CreateVerificationState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String displayName,  String internalName,  String description,  List<VerificationFormField> fields,  bool isSubmitting,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateVerificationState() when $default != null:
return $default(_that.displayName,_that.internalName,_that.description,_that.fields,_that.isSubmitting,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String displayName,  String internalName,  String description,  List<VerificationFormField> fields,  bool isSubmitting,  String? error)  $default,) {final _that = this;
switch (_that) {
case _CreateVerificationState():
return $default(_that.displayName,_that.internalName,_that.description,_that.fields,_that.isSubmitting,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String displayName,  String internalName,  String description,  List<VerificationFormField> fields,  bool isSubmitting,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _CreateVerificationState() when $default != null:
return $default(_that.displayName,_that.internalName,_that.description,_that.fields,_that.isSubmitting,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _CreateVerificationState implements CreateVerificationState {
  const _CreateVerificationState({this.displayName = '', this.internalName = '', this.description = '', final  List<VerificationFormField> fields = const [], this.isSubmitting = false, this.error}): _fields = fields;
  

@override@JsonKey() final  String displayName;
@override@JsonKey() final  String internalName;
@override@JsonKey() final  String description;
 final  List<VerificationFormField> _fields;
@override@JsonKey() List<VerificationFormField> get fields {
  if (_fields is EqualUnmodifiableListView) return _fields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fields);
}

@override@JsonKey() final  bool isSubmitting;
@override final  String? error;

/// Create a copy of CreateVerificationState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateVerificationStateCopyWith<_CreateVerificationState> get copyWith => __$CreateVerificationStateCopyWithImpl<_CreateVerificationState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateVerificationState&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.internalName, internalName) || other.internalName == internalName)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._fields, _fields)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,displayName,internalName,description,const DeepCollectionEquality().hash(_fields),isSubmitting,error);

@override
String toString() {
  return 'CreateVerificationState(displayName: $displayName, internalName: $internalName, description: $description, fields: $fields, isSubmitting: $isSubmitting, error: $error)';
}


}

/// @nodoc
abstract mixin class _$CreateVerificationStateCopyWith<$Res> implements $CreateVerificationStateCopyWith<$Res> {
  factory _$CreateVerificationStateCopyWith(_CreateVerificationState value, $Res Function(_CreateVerificationState) _then) = __$CreateVerificationStateCopyWithImpl;
@override @useResult
$Res call({
 String displayName, String internalName, String description, List<VerificationFormField> fields, bool isSubmitting, String? error
});




}
/// @nodoc
class __$CreateVerificationStateCopyWithImpl<$Res>
    implements _$CreateVerificationStateCopyWith<$Res> {
  __$CreateVerificationStateCopyWithImpl(this._self, this._then);

  final _CreateVerificationState _self;
  final $Res Function(_CreateVerificationState) _then;

/// Create a copy of CreateVerificationState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? displayName = null,Object? internalName = null,Object? description = null,Object? fields = null,Object? isSubmitting = null,Object? error = freezed,}) {
  return _then(_CreateVerificationState(
displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,internalName: null == internalName ? _self.internalName : internalName // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,fields: null == fields ? _self._fields : fields // ignore: cast_nullable_to_non_nullable
as List<VerificationFormField>,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
