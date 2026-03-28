// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'event_create_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EventCreateState {
  String get partyId;
  DateTime get startTime;
  DateTime get endTime;
  int get maxParticipants;
  String get title;
  Map<String, dynamic> get description;
  String? get imageUrl;
  String? get locationId;
  Location? get selectedLocation;
  String? get addressDetail;
  String? get directionsGuide;
  Map<String, dynamic> get contactOptions;
  List<EntryGroup> get entryGroups;
  List<Ticket> get tickets;
  String? get visibility;
  AsyncValue<void> get status;

  /// Create a copy of EventCreateState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $EventCreateStateCopyWith<EventCreateState> get copyWith =>
      _$EventCreateStateCopyWithImpl<EventCreateState>(
          this as EventCreateState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is EventCreateState &&
            (identical(other.partyId, partyId) || other.partyId == partyId) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.maxParticipants, maxParticipants) ||
                other.maxParticipants == maxParticipants) &&
            (identical(other.title, title) || other.title == title) &&
            const DeepCollectionEquality()
                .equals(other.description, description) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.locationId, locationId) ||
                other.locationId == locationId) &&
            (identical(other.selectedLocation, selectedLocation) ||
                other.selectedLocation == selectedLocation) &&
            (identical(other.addressDetail, addressDetail) ||
                other.addressDetail == addressDetail) &&
            (identical(other.directionsGuide, directionsGuide) ||
                other.directionsGuide == directionsGuide) &&
            const DeepCollectionEquality()
                .equals(other.contactOptions, contactOptions) &&
            const DeepCollectionEquality()
                .equals(other.entryGroups, entryGroups) &&
            const DeepCollectionEquality().equals(other.tickets, tickets) &&
            (identical(other.visibility, visibility) ||
                other.visibility == visibility) &&
            (identical(other.status, status) || other.status == status));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      partyId,
      startTime,
      endTime,
      maxParticipants,
      title,
      const DeepCollectionEquality().hash(description),
      imageUrl,
      locationId,
      selectedLocation,
      addressDetail,
      directionsGuide,
      const DeepCollectionEquality().hash(contactOptions),
      const DeepCollectionEquality().hash(entryGroups),
      const DeepCollectionEquality().hash(tickets),
      visibility,
      status);

  @override
  String toString() {
    return 'EventCreateState(partyId: $partyId, startTime: $startTime, endTime: $endTime, maxParticipants: $maxParticipants, title: $title, description: $description, imageUrl: $imageUrl, locationId: $locationId, selectedLocation: $selectedLocation, addressDetail: $addressDetail, directionsGuide: $directionsGuide, contactOptions: $contactOptions, entryGroups: $entryGroups, tickets: $tickets, visibility: $visibility, status: $status)';
  }
}

/// @nodoc
abstract mixin class $EventCreateStateCopyWith<$Res> {
  factory $EventCreateStateCopyWith(
          EventCreateState value, $Res Function(EventCreateState) _then) =
      _$EventCreateStateCopyWithImpl;
  @useResult
  $Res call(
      {String partyId,
      DateTime startTime,
      DateTime endTime,
      int maxParticipants,
      String title,
      Map<String, dynamic> description,
      String? imageUrl,
      String? locationId,
      Location? selectedLocation,
      String? addressDetail,
      String? directionsGuide,
      Map<String, dynamic> contactOptions,
      List<EntryGroup> entryGroups,
      List<Ticket> tickets,
      String? visibility,
      AsyncValue<void> status});

  $LocationCopyWith<$Res>? get selectedLocation;
}

/// @nodoc
class _$EventCreateStateCopyWithImpl<$Res>
    implements $EventCreateStateCopyWith<$Res> {
  _$EventCreateStateCopyWithImpl(this._self, this._then);

  final EventCreateState _self;
  final $Res Function(EventCreateState) _then;

  /// Create a copy of EventCreateState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? partyId = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? maxParticipants = null,
    Object? title = null,
    Object? description = null,
    Object? imageUrl = freezed,
    Object? locationId = freezed,
    Object? selectedLocation = freezed,
    Object? addressDetail = freezed,
    Object? directionsGuide = freezed,
    Object? contactOptions = null,
    Object? entryGroups = null,
    Object? tickets = null,
    Object? visibility = freezed,
    Object? status = null,
  }) {
    return _then(_self.copyWith(
      partyId: null == partyId
          ? _self.partyId
          : partyId // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _self.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endTime: null == endTime
          ? _self.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      maxParticipants: null == maxParticipants
          ? _self.maxParticipants
          : maxParticipants // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      imageUrl: freezed == imageUrl
          ? _self.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      locationId: freezed == locationId
          ? _self.locationId
          : locationId // ignore: cast_nullable_to_non_nullable
              as String?,
      selectedLocation: freezed == selectedLocation
          ? _self.selectedLocation
          : selectedLocation // ignore: cast_nullable_to_non_nullable
              as Location?,
      addressDetail: freezed == addressDetail
          ? _self.addressDetail
          : addressDetail // ignore: cast_nullable_to_non_nullable
              as String?,
      directionsGuide: freezed == directionsGuide
          ? _self.directionsGuide
          : directionsGuide // ignore: cast_nullable_to_non_nullable
              as String?,
      contactOptions: null == contactOptions
          ? _self.contactOptions
          : contactOptions // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      entryGroups: null == entryGroups
          ? _self.entryGroups
          : entryGroups // ignore: cast_nullable_to_non_nullable
              as List<EntryGroup>,
      tickets: null == tickets
          ? _self.tickets
          : tickets // ignore: cast_nullable_to_non_nullable
              as List<Ticket>,
      visibility: freezed == visibility
          ? _self.visibility
          : visibility // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as AsyncValue<void>,
    ));
  }

  /// Create a copy of EventCreateState
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

/// Adds pattern-matching-related methods to [EventCreateState].
extension EventCreateStatePatterns on EventCreateState {
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

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_EventCreateState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _EventCreateState() when $default != null:
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_EventCreateState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EventCreateState():
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_EventCreateState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EventCreateState() when $default != null:
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String partyId,
            DateTime startTime,
            DateTime endTime,
            int maxParticipants,
            String title,
            Map<String, dynamic> description,
            String? imageUrl,
            String? locationId,
            Location? selectedLocation,
            String? addressDetail,
            String? directionsGuide,
            Map<String, dynamic> contactOptions,
            List<EntryGroup> entryGroups,
            List<Ticket> tickets,
            String? visibility,
            AsyncValue<void> status)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _EventCreateState() when $default != null:
        return $default(
            _that.partyId,
            _that.startTime,
            _that.endTime,
            _that.maxParticipants,
            _that.title,
            _that.description,
            _that.imageUrl,
            _that.locationId,
            _that.selectedLocation,
            _that.addressDetail,
            _that.directionsGuide,
            _that.contactOptions,
            _that.entryGroups,
            _that.tickets,
            _that.visibility,
            _that.status);
      case _:
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

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String partyId,
            DateTime startTime,
            DateTime endTime,
            int maxParticipants,
            String title,
            Map<String, dynamic> description,
            String? imageUrl,
            String? locationId,
            Location? selectedLocation,
            String? addressDetail,
            String? directionsGuide,
            Map<String, dynamic> contactOptions,
            List<EntryGroup> entryGroups,
            List<Ticket> tickets,
            String? visibility,
            AsyncValue<void> status)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EventCreateState():
        return $default(
            _that.partyId,
            _that.startTime,
            _that.endTime,
            _that.maxParticipants,
            _that.title,
            _that.description,
            _that.imageUrl,
            _that.locationId,
            _that.selectedLocation,
            _that.addressDetail,
            _that.directionsGuide,
            _that.contactOptions,
            _that.entryGroups,
            _that.tickets,
            _that.visibility,
            _that.status);
      case _:
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

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String partyId,
            DateTime startTime,
            DateTime endTime,
            int maxParticipants,
            String title,
            Map<String, dynamic> description,
            String? imageUrl,
            String? locationId,
            Location? selectedLocation,
            String? addressDetail,
            String? directionsGuide,
            Map<String, dynamic> contactOptions,
            List<EntryGroup> entryGroups,
            List<Ticket> tickets,
            String? visibility,
            AsyncValue<void> status)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EventCreateState() when $default != null:
        return $default(
            _that.partyId,
            _that.startTime,
            _that.endTime,
            _that.maxParticipants,
            _that.title,
            _that.description,
            _that.imageUrl,
            _that.locationId,
            _that.selectedLocation,
            _that.addressDetail,
            _that.directionsGuide,
            _that.contactOptions,
            _that.entryGroups,
            _that.tickets,
            _that.visibility,
            _that.status);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _EventCreateState implements EventCreateState {
  const _EventCreateState(
      {required this.partyId,
      required this.startTime,
      required this.endTime,
      this.maxParticipants = 20,
      this.title = '',
      final Map<String, dynamic> description = const {},
      this.imageUrl,
      this.locationId,
      this.selectedLocation,
      this.addressDetail,
      this.directionsGuide,
      final Map<String, dynamic> contactOptions = const {},
      final List<EntryGroup> entryGroups = const [],
      final List<Ticket> tickets = const [],
      this.visibility,
      this.status = const AsyncValue.data(null)})
      : _description = description,
        _contactOptions = contactOptions,
        _entryGroups = entryGroups,
        _tickets = tickets;

  @override
  final String partyId;
  @override
  final DateTime startTime;
  @override
  final DateTime endTime;
  @override
  @JsonKey()
  final int maxParticipants;
  @override
  @JsonKey()
  final String title;
  final Map<String, dynamic> _description;
  @override
  @JsonKey()
  Map<String, dynamic> get description {
    if (_description is EqualUnmodifiableMapView) return _description;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_description);
  }

  @override
  final String? imageUrl;
  @override
  final String? locationId;
  @override
  final Location? selectedLocation;
  @override
  final String? addressDetail;
  @override
  final String? directionsGuide;
  final Map<String, dynamic> _contactOptions;
  @override
  @JsonKey()
  Map<String, dynamic> get contactOptions {
    if (_contactOptions is EqualUnmodifiableMapView) return _contactOptions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_contactOptions);
  }

  final List<EntryGroup> _entryGroups;
  @override
  @JsonKey()
  List<EntryGroup> get entryGroups {
    if (_entryGroups is EqualUnmodifiableListView) return _entryGroups;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_entryGroups);
  }

  final List<Ticket> _tickets;
  @override
  @JsonKey()
  List<Ticket> get tickets {
    if (_tickets is EqualUnmodifiableListView) return _tickets;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tickets);
  }

  @override
  final String? visibility;
  @override
  @JsonKey()
  final AsyncValue<void> status;

  /// Create a copy of EventCreateState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$EventCreateStateCopyWith<_EventCreateState> get copyWith =>
      __$EventCreateStateCopyWithImpl<_EventCreateState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _EventCreateState &&
            (identical(other.partyId, partyId) || other.partyId == partyId) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.maxParticipants, maxParticipants) ||
                other.maxParticipants == maxParticipants) &&
            (identical(other.title, title) || other.title == title) &&
            const DeepCollectionEquality()
                .equals(other._description, _description) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.locationId, locationId) ||
                other.locationId == locationId) &&
            (identical(other.selectedLocation, selectedLocation) ||
                other.selectedLocation == selectedLocation) &&
            (identical(other.addressDetail, addressDetail) ||
                other.addressDetail == addressDetail) &&
            (identical(other.directionsGuide, directionsGuide) ||
                other.directionsGuide == directionsGuide) &&
            const DeepCollectionEquality()
                .equals(other._contactOptions, _contactOptions) &&
            const DeepCollectionEquality()
                .equals(other._entryGroups, _entryGroups) &&
            const DeepCollectionEquality().equals(other._tickets, _tickets) &&
            (identical(other.visibility, visibility) ||
                other.visibility == visibility) &&
            (identical(other.status, status) || other.status == status));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      partyId,
      startTime,
      endTime,
      maxParticipants,
      title,
      const DeepCollectionEquality().hash(_description),
      imageUrl,
      locationId,
      selectedLocation,
      addressDetail,
      directionsGuide,
      const DeepCollectionEquality().hash(_contactOptions),
      const DeepCollectionEquality().hash(_entryGroups),
      const DeepCollectionEquality().hash(_tickets),
      visibility,
      status);

  @override
  String toString() {
    return 'EventCreateState(partyId: $partyId, startTime: $startTime, endTime: $endTime, maxParticipants: $maxParticipants, title: $title, description: $description, imageUrl: $imageUrl, locationId: $locationId, selectedLocation: $selectedLocation, addressDetail: $addressDetail, directionsGuide: $directionsGuide, contactOptions: $contactOptions, entryGroups: $entryGroups, tickets: $tickets, visibility: $visibility, status: $status)';
  }
}

/// @nodoc
abstract mixin class _$EventCreateStateCopyWith<$Res>
    implements $EventCreateStateCopyWith<$Res> {
  factory _$EventCreateStateCopyWith(
          _EventCreateState value, $Res Function(_EventCreateState) _then) =
      __$EventCreateStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String partyId,
      DateTime startTime,
      DateTime endTime,
      int maxParticipants,
      String title,
      Map<String, dynamic> description,
      String? imageUrl,
      String? locationId,
      Location? selectedLocation,
      String? addressDetail,
      String? directionsGuide,
      Map<String, dynamic> contactOptions,
      List<EntryGroup> entryGroups,
      List<Ticket> tickets,
      String? visibility,
      AsyncValue<void> status});

  @override
  $LocationCopyWith<$Res>? get selectedLocation;
}

/// @nodoc
class __$EventCreateStateCopyWithImpl<$Res>
    implements _$EventCreateStateCopyWith<$Res> {
  __$EventCreateStateCopyWithImpl(this._self, this._then);

  final _EventCreateState _self;
  final $Res Function(_EventCreateState) _then;

  /// Create a copy of EventCreateState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? partyId = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? maxParticipants = null,
    Object? title = null,
    Object? description = null,
    Object? imageUrl = freezed,
    Object? locationId = freezed,
    Object? selectedLocation = freezed,
    Object? addressDetail = freezed,
    Object? directionsGuide = freezed,
    Object? contactOptions = null,
    Object? entryGroups = null,
    Object? tickets = null,
    Object? visibility = freezed,
    Object? status = null,
  }) {
    return _then(_EventCreateState(
      partyId: null == partyId
          ? _self.partyId
          : partyId // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _self.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endTime: null == endTime
          ? _self.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      maxParticipants: null == maxParticipants
          ? _self.maxParticipants
          : maxParticipants // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self._description
          : description // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      imageUrl: freezed == imageUrl
          ? _self.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      locationId: freezed == locationId
          ? _self.locationId
          : locationId // ignore: cast_nullable_to_non_nullable
              as String?,
      selectedLocation: freezed == selectedLocation
          ? _self.selectedLocation
          : selectedLocation // ignore: cast_nullable_to_non_nullable
              as Location?,
      addressDetail: freezed == addressDetail
          ? _self.addressDetail
          : addressDetail // ignore: cast_nullable_to_non_nullable
              as String?,
      directionsGuide: freezed == directionsGuide
          ? _self.directionsGuide
          : directionsGuide // ignore: cast_nullable_to_non_nullable
              as String?,
      contactOptions: null == contactOptions
          ? _self._contactOptions
          : contactOptions // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      entryGroups: null == entryGroups
          ? _self._entryGroups
          : entryGroups // ignore: cast_nullable_to_non_nullable
              as List<EntryGroup>,
      tickets: null == tickets
          ? _self._tickets
          : tickets // ignore: cast_nullable_to_non_nullable
              as List<Ticket>,
      visibility: freezed == visibility
          ? _self.visibility
          : visibility // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as AsyncValue<void>,
    ));
  }

  /// Create a copy of EventCreateState
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
