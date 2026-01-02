// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'party_create_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PartyCreateState {

 List<String> get selectedVerificationIds; Set<String> get enabledContactMethods; AsyncValue<void> get status; Location? get selectedLocation; Map<String, dynamic> get conditions; List<Ticket> get ticketTemplates; String? get descriptionError;
/// Create a copy of PartyCreateState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PartyCreateStateCopyWith<PartyCreateState> get copyWith => _$PartyCreateStateCopyWithImpl<PartyCreateState>(this as PartyCreateState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PartyCreateState&&const DeepCollectionEquality().equals(other.selectedVerificationIds, selectedVerificationIds)&&const DeepCollectionEquality().equals(other.enabledContactMethods, enabledContactMethods)&&(identical(other.status, status) || other.status == status)&&(identical(other.selectedLocation, selectedLocation) || other.selectedLocation == selectedLocation)&&const DeepCollectionEquality().equals(other.conditions, conditions)&&const DeepCollectionEquality().equals(other.ticketTemplates, ticketTemplates)&&(identical(other.descriptionError, descriptionError) || other.descriptionError == descriptionError));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(selectedVerificationIds),const DeepCollectionEquality().hash(enabledContactMethods),status,selectedLocation,const DeepCollectionEquality().hash(conditions),const DeepCollectionEquality().hash(ticketTemplates),descriptionError);

@override
String toString() {
  return 'PartyCreateState(selectedVerificationIds: $selectedVerificationIds, enabledContactMethods: $enabledContactMethods, status: $status, selectedLocation: $selectedLocation, conditions: $conditions, ticketTemplates: $ticketTemplates, descriptionError: $descriptionError)';
}


}

/// @nodoc
abstract mixin class $PartyCreateStateCopyWith<$Res>  {
  factory $PartyCreateStateCopyWith(PartyCreateState value, $Res Function(PartyCreateState) _then) = _$PartyCreateStateCopyWithImpl;
@useResult
$Res call({
 List<String> selectedVerificationIds, Set<String> enabledContactMethods, AsyncValue<void> status, Location? selectedLocation, Map<String, dynamic> conditions, List<Ticket> ticketTemplates, String? descriptionError
});


$LocationCopyWith<$Res>? get selectedLocation;

}
/// @nodoc
class _$PartyCreateStateCopyWithImpl<$Res>
    implements $PartyCreateStateCopyWith<$Res> {
  _$PartyCreateStateCopyWithImpl(this._self, this._then);

  final PartyCreateState _self;
  final $Res Function(PartyCreateState) _then;

/// Create a copy of PartyCreateState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? selectedVerificationIds = null,Object? enabledContactMethods = null,Object? status = null,Object? selectedLocation = freezed,Object? conditions = null,Object? ticketTemplates = null,Object? descriptionError = freezed,}) {
  return _then(_self.copyWith(
selectedVerificationIds: null == selectedVerificationIds ? _self.selectedVerificationIds : selectedVerificationIds // ignore: cast_nullable_to_non_nullable
as List<String>,enabledContactMethods: null == enabledContactMethods ? _self.enabledContactMethods : enabledContactMethods // ignore: cast_nullable_to_non_nullable
as Set<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AsyncValue<void>,selectedLocation: freezed == selectedLocation ? _self.selectedLocation : selectedLocation // ignore: cast_nullable_to_non_nullable
as Location?,conditions: null == conditions ? _self.conditions : conditions // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,ticketTemplates: null == ticketTemplates ? _self.ticketTemplates : ticketTemplates // ignore: cast_nullable_to_non_nullable
as List<Ticket>,descriptionError: freezed == descriptionError ? _self.descriptionError : descriptionError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of PartyCreateState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocationCopyWith<$Res>? get selectedLocation {
    if (_self.selectedLocation == null) {
    return null;
  }

  return $LocationCopyWith<$Res>(_self.selectedLocation!, (value) {
    return _then(_self.copyWith(selectedLocation: value));
  });
}
}


/// Adds pattern-matching-related methods to [PartyCreateState].
extension PartyCreateStatePatterns on PartyCreateState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PartyCreateState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PartyCreateState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PartyCreateState value)  $default,){
final _that = this;
switch (_that) {
case _PartyCreateState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PartyCreateState value)?  $default,){
final _that = this;
switch (_that) {
case _PartyCreateState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> selectedVerificationIds,  Set<String> enabledContactMethods,  AsyncValue<void> status,  Location? selectedLocation,  Map<String, dynamic> conditions,  List<Ticket> ticketTemplates,  String? descriptionError)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PartyCreateState() when $default != null:
return $default(_that.selectedVerificationIds,_that.enabledContactMethods,_that.status,_that.selectedLocation,_that.conditions,_that.ticketTemplates,_that.descriptionError);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> selectedVerificationIds,  Set<String> enabledContactMethods,  AsyncValue<void> status,  Location? selectedLocation,  Map<String, dynamic> conditions,  List<Ticket> ticketTemplates,  String? descriptionError)  $default,) {final _that = this;
switch (_that) {
case _PartyCreateState():
return $default(_that.selectedVerificationIds,_that.enabledContactMethods,_that.status,_that.selectedLocation,_that.conditions,_that.ticketTemplates,_that.descriptionError);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> selectedVerificationIds,  Set<String> enabledContactMethods,  AsyncValue<void> status,  Location? selectedLocation,  Map<String, dynamic> conditions,  List<Ticket> ticketTemplates,  String? descriptionError)?  $default,) {final _that = this;
switch (_that) {
case _PartyCreateState() when $default != null:
return $default(_that.selectedVerificationIds,_that.enabledContactMethods,_that.status,_that.selectedLocation,_that.conditions,_that.ticketTemplates,_that.descriptionError);case _:
  return null;

}
}

}

/// @nodoc


class _PartyCreateState implements PartyCreateState {
  const _PartyCreateState({final  List<String> selectedVerificationIds = const [], final  Set<String> enabledContactMethods = const {}, this.status = const AsyncValue.data(null), this.selectedLocation, final  Map<String, dynamic> conditions = const {}, final  List<Ticket> ticketTemplates = const [], this.descriptionError}): _selectedVerificationIds = selectedVerificationIds,_enabledContactMethods = enabledContactMethods,_conditions = conditions,_ticketTemplates = ticketTemplates;
  

 final  List<String> _selectedVerificationIds;
@override@JsonKey() List<String> get selectedVerificationIds {
  if (_selectedVerificationIds is EqualUnmodifiableListView) return _selectedVerificationIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectedVerificationIds);
}

 final  Set<String> _enabledContactMethods;
@override@JsonKey() Set<String> get enabledContactMethods {
  if (_enabledContactMethods is EqualUnmodifiableSetView) return _enabledContactMethods;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_enabledContactMethods);
}

@override@JsonKey() final  AsyncValue<void> status;
@override final  Location? selectedLocation;
 final  Map<String, dynamic> _conditions;
@override@JsonKey() Map<String, dynamic> get conditions {
  if (_conditions is EqualUnmodifiableMapView) return _conditions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_conditions);
}

 final  List<Ticket> _ticketTemplates;
@override@JsonKey() List<Ticket> get ticketTemplates {
  if (_ticketTemplates is EqualUnmodifiableListView) return _ticketTemplates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ticketTemplates);
}

@override final  String? descriptionError;

/// Create a copy of PartyCreateState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PartyCreateStateCopyWith<_PartyCreateState> get copyWith => __$PartyCreateStateCopyWithImpl<_PartyCreateState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PartyCreateState&&const DeepCollectionEquality().equals(other._selectedVerificationIds, _selectedVerificationIds)&&const DeepCollectionEquality().equals(other._enabledContactMethods, _enabledContactMethods)&&(identical(other.status, status) || other.status == status)&&(identical(other.selectedLocation, selectedLocation) || other.selectedLocation == selectedLocation)&&const DeepCollectionEquality().equals(other._conditions, _conditions)&&const DeepCollectionEquality().equals(other._ticketTemplates, _ticketTemplates)&&(identical(other.descriptionError, descriptionError) || other.descriptionError == descriptionError));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_selectedVerificationIds),const DeepCollectionEquality().hash(_enabledContactMethods),status,selectedLocation,const DeepCollectionEquality().hash(_conditions),const DeepCollectionEquality().hash(_ticketTemplates),descriptionError);

@override
String toString() {
  return 'PartyCreateState(selectedVerificationIds: $selectedVerificationIds, enabledContactMethods: $enabledContactMethods, status: $status, selectedLocation: $selectedLocation, conditions: $conditions, ticketTemplates: $ticketTemplates, descriptionError: $descriptionError)';
}


}

/// @nodoc
abstract mixin class _$PartyCreateStateCopyWith<$Res> implements $PartyCreateStateCopyWith<$Res> {
  factory _$PartyCreateStateCopyWith(_PartyCreateState value, $Res Function(_PartyCreateState) _then) = __$PartyCreateStateCopyWithImpl;
@override @useResult
$Res call({
 List<String> selectedVerificationIds, Set<String> enabledContactMethods, AsyncValue<void> status, Location? selectedLocation, Map<String, dynamic> conditions, List<Ticket> ticketTemplates, String? descriptionError
});


@override $LocationCopyWith<$Res>? get selectedLocation;

}
/// @nodoc
class __$PartyCreateStateCopyWithImpl<$Res>
    implements _$PartyCreateStateCopyWith<$Res> {
  __$PartyCreateStateCopyWithImpl(this._self, this._then);

  final _PartyCreateState _self;
  final $Res Function(_PartyCreateState) _then;

/// Create a copy of PartyCreateState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? selectedVerificationIds = null,Object? enabledContactMethods = null,Object? status = null,Object? selectedLocation = freezed,Object? conditions = null,Object? ticketTemplates = null,Object? descriptionError = freezed,}) {
  return _then(_PartyCreateState(
selectedVerificationIds: null == selectedVerificationIds ? _self._selectedVerificationIds : selectedVerificationIds // ignore: cast_nullable_to_non_nullable
as List<String>,enabledContactMethods: null == enabledContactMethods ? _self._enabledContactMethods : enabledContactMethods // ignore: cast_nullable_to_non_nullable
as Set<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AsyncValue<void>,selectedLocation: freezed == selectedLocation ? _self.selectedLocation : selectedLocation // ignore: cast_nullable_to_non_nullable
as Location?,conditions: null == conditions ? _self._conditions : conditions // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,ticketTemplates: null == ticketTemplates ? _self._ticketTemplates : ticketTemplates // ignore: cast_nullable_to_non_nullable
as List<Ticket>,descriptionError: freezed == descriptionError ? _self.descriptionError : descriptionError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of PartyCreateState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocationCopyWith<$Res>? get selectedLocation {
    if (_self.selectedLocation == null) {
    return null;
  }

  return $LocationCopyWith<$Res>(_self.selectedLocation!, (value) {
    return _then(_self.copyWith(selectedLocation: value));
  });
}
}

// dart format on
