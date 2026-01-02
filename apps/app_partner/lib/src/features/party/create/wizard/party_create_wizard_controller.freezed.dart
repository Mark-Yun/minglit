// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'party_create_wizard_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PartyCreateWizardState {

 PartyCreateStep get currentStep;// Step 1: Basic Info
 String get title; Map<String, dynamic> get description; XFile? get imageFile;// Step 2: Location
 Location? get selectedLocation; String? get addressDetail; String? get directionsGuide;// Step 3: Capacity & Contact
 int get minConfirmedCount; int get maxParticipants; String get contactPhone; String get contactEmail; String? get contactKakao; Set<String> get enabledContactMethods;// Step 4: Entry Rules (Entry Groups)
 List<PartyEntryGroup> get entryGroups;// Step 5: Tickets
 List<Ticket> get tickets;// Global Status
 AsyncValue<void> get status;
/// Create a copy of PartyCreateWizardState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PartyCreateWizardStateCopyWith<PartyCreateWizardState> get copyWith => _$PartyCreateWizardStateCopyWithImpl<PartyCreateWizardState>(this as PartyCreateWizardState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PartyCreateWizardState&&(identical(other.currentStep, currentStep) || other.currentStep == currentStep)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.description, description)&&(identical(other.imageFile, imageFile) || other.imageFile == imageFile)&&(identical(other.selectedLocation, selectedLocation) || other.selectedLocation == selectedLocation)&&(identical(other.addressDetail, addressDetail) || other.addressDetail == addressDetail)&&(identical(other.directionsGuide, directionsGuide) || other.directionsGuide == directionsGuide)&&(identical(other.minConfirmedCount, minConfirmedCount) || other.minConfirmedCount == minConfirmedCount)&&(identical(other.maxParticipants, maxParticipants) || other.maxParticipants == maxParticipants)&&(identical(other.contactPhone, contactPhone) || other.contactPhone == contactPhone)&&(identical(other.contactEmail, contactEmail) || other.contactEmail == contactEmail)&&(identical(other.contactKakao, contactKakao) || other.contactKakao == contactKakao)&&const DeepCollectionEquality().equals(other.enabledContactMethods, enabledContactMethods)&&const DeepCollectionEquality().equals(other.entryGroups, entryGroups)&&const DeepCollectionEquality().equals(other.tickets, tickets)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,currentStep,title,const DeepCollectionEquality().hash(description),imageFile,selectedLocation,addressDetail,directionsGuide,minConfirmedCount,maxParticipants,contactPhone,contactEmail,contactKakao,const DeepCollectionEquality().hash(enabledContactMethods),const DeepCollectionEquality().hash(entryGroups),const DeepCollectionEquality().hash(tickets),status);

@override
String toString() {
  return 'PartyCreateWizardState(currentStep: $currentStep, title: $title, description: $description, imageFile: $imageFile, selectedLocation: $selectedLocation, addressDetail: $addressDetail, directionsGuide: $directionsGuide, minConfirmedCount: $minConfirmedCount, maxParticipants: $maxParticipants, contactPhone: $contactPhone, contactEmail: $contactEmail, contactKakao: $contactKakao, enabledContactMethods: $enabledContactMethods, entryGroups: $entryGroups, tickets: $tickets, status: $status)';
}


}

/// @nodoc
abstract mixin class $PartyCreateWizardStateCopyWith<$Res>  {
  factory $PartyCreateWizardStateCopyWith(PartyCreateWizardState value, $Res Function(PartyCreateWizardState) _then) = _$PartyCreateWizardStateCopyWithImpl;
@useResult
$Res call({
 PartyCreateStep currentStep, String title, Map<String, dynamic> description, XFile? imageFile, Location? selectedLocation, String? addressDetail, String? directionsGuide, int minConfirmedCount, int maxParticipants, String contactPhone, String contactEmail, String? contactKakao, Set<String> enabledContactMethods, List<PartyEntryGroup> entryGroups, List<Ticket> tickets, AsyncValue<void> status
});


$LocationCopyWith<$Res>? get selectedLocation;

}
/// @nodoc
class _$PartyCreateWizardStateCopyWithImpl<$Res>
    implements $PartyCreateWizardStateCopyWith<$Res> {
  _$PartyCreateWizardStateCopyWithImpl(this._self, this._then);

  final PartyCreateWizardState _self;
  final $Res Function(PartyCreateWizardState) _then;

/// Create a copy of PartyCreateWizardState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentStep = null,Object? title = null,Object? description = null,Object? imageFile = freezed,Object? selectedLocation = freezed,Object? addressDetail = freezed,Object? directionsGuide = freezed,Object? minConfirmedCount = null,Object? maxParticipants = null,Object? contactPhone = null,Object? contactEmail = null,Object? contactKakao = freezed,Object? enabledContactMethods = null,Object? entryGroups = null,Object? tickets = null,Object? status = null,}) {
  return _then(_self.copyWith(
currentStep: null == currentStep ? _self.currentStep : currentStep // ignore: cast_nullable_to_non_nullable
as PartyCreateStep,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,imageFile: freezed == imageFile ? _self.imageFile : imageFile // ignore: cast_nullable_to_non_nullable
as XFile?,selectedLocation: freezed == selectedLocation ? _self.selectedLocation : selectedLocation // ignore: cast_nullable_to_non_nullable
as Location?,addressDetail: freezed == addressDetail ? _self.addressDetail : addressDetail // ignore: cast_nullable_to_non_nullable
as String?,directionsGuide: freezed == directionsGuide ? _self.directionsGuide : directionsGuide // ignore: cast_nullable_to_non_nullable
as String?,minConfirmedCount: null == minConfirmedCount ? _self.minConfirmedCount : minConfirmedCount // ignore: cast_nullable_to_non_nullable
as int,maxParticipants: null == maxParticipants ? _self.maxParticipants : maxParticipants // ignore: cast_nullable_to_non_nullable
as int,contactPhone: null == contactPhone ? _self.contactPhone : contactPhone // ignore: cast_nullable_to_non_nullable
as String,contactEmail: null == contactEmail ? _self.contactEmail : contactEmail // ignore: cast_nullable_to_non_nullable
as String,contactKakao: freezed == contactKakao ? _self.contactKakao : contactKakao // ignore: cast_nullable_to_non_nullable
as String?,enabledContactMethods: null == enabledContactMethods ? _self.enabledContactMethods : enabledContactMethods // ignore: cast_nullable_to_non_nullable
as Set<String>,entryGroups: null == entryGroups ? _self.entryGroups : entryGroups // ignore: cast_nullable_to_non_nullable
as List<PartyEntryGroup>,tickets: null == tickets ? _self.tickets : tickets // ignore: cast_nullable_to_non_nullable
as List<Ticket>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AsyncValue<void>,
  ));
}
/// Create a copy of PartyCreateWizardState
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


/// Adds pattern-matching-related methods to [PartyCreateWizardState].
extension PartyCreateWizardStatePatterns on PartyCreateWizardState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PartyCreateWizardState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PartyCreateWizardState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PartyCreateWizardState value)  $default,){
final _that = this;
switch (_that) {
case _PartyCreateWizardState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PartyCreateWizardState value)?  $default,){
final _that = this;
switch (_that) {
case _PartyCreateWizardState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PartyCreateStep currentStep,  String title,  Map<String, dynamic> description,  XFile? imageFile,  Location? selectedLocation,  String? addressDetail,  String? directionsGuide,  int minConfirmedCount,  int maxParticipants,  String contactPhone,  String contactEmail,  String? contactKakao,  Set<String> enabledContactMethods,  List<PartyEntryGroup> entryGroups,  List<Ticket> tickets,  AsyncValue<void> status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PartyCreateWizardState() when $default != null:
return $default(_that.currentStep,_that.title,_that.description,_that.imageFile,_that.selectedLocation,_that.addressDetail,_that.directionsGuide,_that.minConfirmedCount,_that.maxParticipants,_that.contactPhone,_that.contactEmail,_that.contactKakao,_that.enabledContactMethods,_that.entryGroups,_that.tickets,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PartyCreateStep currentStep,  String title,  Map<String, dynamic> description,  XFile? imageFile,  Location? selectedLocation,  String? addressDetail,  String? directionsGuide,  int minConfirmedCount,  int maxParticipants,  String contactPhone,  String contactEmail,  String? contactKakao,  Set<String> enabledContactMethods,  List<PartyEntryGroup> entryGroups,  List<Ticket> tickets,  AsyncValue<void> status)  $default,) {final _that = this;
switch (_that) {
case _PartyCreateWizardState():
return $default(_that.currentStep,_that.title,_that.description,_that.imageFile,_that.selectedLocation,_that.addressDetail,_that.directionsGuide,_that.minConfirmedCount,_that.maxParticipants,_that.contactPhone,_that.contactEmail,_that.contactKakao,_that.enabledContactMethods,_that.entryGroups,_that.tickets,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PartyCreateStep currentStep,  String title,  Map<String, dynamic> description,  XFile? imageFile,  Location? selectedLocation,  String? addressDetail,  String? directionsGuide,  int minConfirmedCount,  int maxParticipants,  String contactPhone,  String contactEmail,  String? contactKakao,  Set<String> enabledContactMethods,  List<PartyEntryGroup> entryGroups,  List<Ticket> tickets,  AsyncValue<void> status)?  $default,) {final _that = this;
switch (_that) {
case _PartyCreateWizardState() when $default != null:
return $default(_that.currentStep,_that.title,_that.description,_that.imageFile,_that.selectedLocation,_that.addressDetail,_that.directionsGuide,_that.minConfirmedCount,_that.maxParticipants,_that.contactPhone,_that.contactEmail,_that.contactKakao,_that.enabledContactMethods,_that.entryGroups,_that.tickets,_that.status);case _:
  return null;

}
}

}

/// @nodoc


class _PartyCreateWizardState implements PartyCreateWizardState {
  const _PartyCreateWizardState({this.currentStep = PartyCreateStep.basicInfo, this.title = '', final  Map<String, dynamic> description = const {}, this.imageFile, this.selectedLocation, this.addressDetail, this.directionsGuide, this.minConfirmedCount = 5, this.maxParticipants = 20, this.contactPhone = '', this.contactEmail = '', this.contactKakao, final  Set<String> enabledContactMethods = const {'phone', 'email'}, final  List<PartyEntryGroup> entryGroups = const [], final  List<Ticket> tickets = const [], this.status = const AsyncValue.data(null)}): _description = description,_enabledContactMethods = enabledContactMethods,_entryGroups = entryGroups,_tickets = tickets;
  

@override@JsonKey() final  PartyCreateStep currentStep;
// Step 1: Basic Info
@override@JsonKey() final  String title;
 final  Map<String, dynamic> _description;
@override@JsonKey() Map<String, dynamic> get description {
  if (_description is EqualUnmodifiableMapView) return _description;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_description);
}

@override final  XFile? imageFile;
// Step 2: Location
@override final  Location? selectedLocation;
@override final  String? addressDetail;
@override final  String? directionsGuide;
// Step 3: Capacity & Contact
@override@JsonKey() final  int minConfirmedCount;
@override@JsonKey() final  int maxParticipants;
@override@JsonKey() final  String contactPhone;
@override@JsonKey() final  String contactEmail;
@override final  String? contactKakao;
 final  Set<String> _enabledContactMethods;
@override@JsonKey() Set<String> get enabledContactMethods {
  if (_enabledContactMethods is EqualUnmodifiableSetView) return _enabledContactMethods;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_enabledContactMethods);
}

// Step 4: Entry Rules (Entry Groups)
 final  List<PartyEntryGroup> _entryGroups;
// Step 4: Entry Rules (Entry Groups)
@override@JsonKey() List<PartyEntryGroup> get entryGroups {
  if (_entryGroups is EqualUnmodifiableListView) return _entryGroups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entryGroups);
}

// Step 5: Tickets
 final  List<Ticket> _tickets;
// Step 5: Tickets
@override@JsonKey() List<Ticket> get tickets {
  if (_tickets is EqualUnmodifiableListView) return _tickets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tickets);
}

// Global Status
@override@JsonKey() final  AsyncValue<void> status;

/// Create a copy of PartyCreateWizardState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PartyCreateWizardStateCopyWith<_PartyCreateWizardState> get copyWith => __$PartyCreateWizardStateCopyWithImpl<_PartyCreateWizardState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PartyCreateWizardState&&(identical(other.currentStep, currentStep) || other.currentStep == currentStep)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._description, _description)&&(identical(other.imageFile, imageFile) || other.imageFile == imageFile)&&(identical(other.selectedLocation, selectedLocation) || other.selectedLocation == selectedLocation)&&(identical(other.addressDetail, addressDetail) || other.addressDetail == addressDetail)&&(identical(other.directionsGuide, directionsGuide) || other.directionsGuide == directionsGuide)&&(identical(other.minConfirmedCount, minConfirmedCount) || other.minConfirmedCount == minConfirmedCount)&&(identical(other.maxParticipants, maxParticipants) || other.maxParticipants == maxParticipants)&&(identical(other.contactPhone, contactPhone) || other.contactPhone == contactPhone)&&(identical(other.contactEmail, contactEmail) || other.contactEmail == contactEmail)&&(identical(other.contactKakao, contactKakao) || other.contactKakao == contactKakao)&&const DeepCollectionEquality().equals(other._enabledContactMethods, _enabledContactMethods)&&const DeepCollectionEquality().equals(other._entryGroups, _entryGroups)&&const DeepCollectionEquality().equals(other._tickets, _tickets)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,currentStep,title,const DeepCollectionEquality().hash(_description),imageFile,selectedLocation,addressDetail,directionsGuide,minConfirmedCount,maxParticipants,contactPhone,contactEmail,contactKakao,const DeepCollectionEquality().hash(_enabledContactMethods),const DeepCollectionEquality().hash(_entryGroups),const DeepCollectionEquality().hash(_tickets),status);

@override
String toString() {
  return 'PartyCreateWizardState(currentStep: $currentStep, title: $title, description: $description, imageFile: $imageFile, selectedLocation: $selectedLocation, addressDetail: $addressDetail, directionsGuide: $directionsGuide, minConfirmedCount: $minConfirmedCount, maxParticipants: $maxParticipants, contactPhone: $contactPhone, contactEmail: $contactEmail, contactKakao: $contactKakao, enabledContactMethods: $enabledContactMethods, entryGroups: $entryGroups, tickets: $tickets, status: $status)';
}


}

/// @nodoc
abstract mixin class _$PartyCreateWizardStateCopyWith<$Res> implements $PartyCreateWizardStateCopyWith<$Res> {
  factory _$PartyCreateWizardStateCopyWith(_PartyCreateWizardState value, $Res Function(_PartyCreateWizardState) _then) = __$PartyCreateWizardStateCopyWithImpl;
@override @useResult
$Res call({
 PartyCreateStep currentStep, String title, Map<String, dynamic> description, XFile? imageFile, Location? selectedLocation, String? addressDetail, String? directionsGuide, int minConfirmedCount, int maxParticipants, String contactPhone, String contactEmail, String? contactKakao, Set<String> enabledContactMethods, List<PartyEntryGroup> entryGroups, List<Ticket> tickets, AsyncValue<void> status
});


@override $LocationCopyWith<$Res>? get selectedLocation;

}
/// @nodoc
class __$PartyCreateWizardStateCopyWithImpl<$Res>
    implements _$PartyCreateWizardStateCopyWith<$Res> {
  __$PartyCreateWizardStateCopyWithImpl(this._self, this._then);

  final _PartyCreateWizardState _self;
  final $Res Function(_PartyCreateWizardState) _then;

/// Create a copy of PartyCreateWizardState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentStep = null,Object? title = null,Object? description = null,Object? imageFile = freezed,Object? selectedLocation = freezed,Object? addressDetail = freezed,Object? directionsGuide = freezed,Object? minConfirmedCount = null,Object? maxParticipants = null,Object? contactPhone = null,Object? contactEmail = null,Object? contactKakao = freezed,Object? enabledContactMethods = null,Object? entryGroups = null,Object? tickets = null,Object? status = null,}) {
  return _then(_PartyCreateWizardState(
currentStep: null == currentStep ? _self.currentStep : currentStep // ignore: cast_nullable_to_non_nullable
as PartyCreateStep,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self._description : description // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,imageFile: freezed == imageFile ? _self.imageFile : imageFile // ignore: cast_nullable_to_non_nullable
as XFile?,selectedLocation: freezed == selectedLocation ? _self.selectedLocation : selectedLocation // ignore: cast_nullable_to_non_nullable
as Location?,addressDetail: freezed == addressDetail ? _self.addressDetail : addressDetail // ignore: cast_nullable_to_non_nullable
as String?,directionsGuide: freezed == directionsGuide ? _self.directionsGuide : directionsGuide // ignore: cast_nullable_to_non_nullable
as String?,minConfirmedCount: null == minConfirmedCount ? _self.minConfirmedCount : minConfirmedCount // ignore: cast_nullable_to_non_nullable
as int,maxParticipants: null == maxParticipants ? _self.maxParticipants : maxParticipants // ignore: cast_nullable_to_non_nullable
as int,contactPhone: null == contactPhone ? _self.contactPhone : contactPhone // ignore: cast_nullable_to_non_nullable
as String,contactEmail: null == contactEmail ? _self.contactEmail : contactEmail // ignore: cast_nullable_to_non_nullable
as String,contactKakao: freezed == contactKakao ? _self.contactKakao : contactKakao // ignore: cast_nullable_to_non_nullable
as String?,enabledContactMethods: null == enabledContactMethods ? _self._enabledContactMethods : enabledContactMethods // ignore: cast_nullable_to_non_nullable
as Set<String>,entryGroups: null == entryGroups ? _self._entryGroups : entryGroups // ignore: cast_nullable_to_non_nullable
as List<PartyEntryGroup>,tickets: null == tickets ? _self._tickets : tickets // ignore: cast_nullable_to_non_nullable
as List<Ticket>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AsyncValue<void>,
  ));
}

/// Create a copy of PartyCreateWizardState
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
