// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'party_entry_group.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EntryGroupTemplate {
  String get id;
  @JsonKey(name: 'party_id')
  String get partyId;
  String? get label;
  String? get gender;
  @JsonKey(name: 'birth_year_min')
  int? get birthYearMin;
  @JsonKey(name: 'birth_year_max')
  int? get birthYearMax;
  @JsonKey(name: 'required_verification_ids')
  List<String> get requiredVerificationIds;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of EntryGroupTemplate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $EntryGroupTemplateCopyWith<EntryGroupTemplate> get copyWith =>
      _$EntryGroupTemplateCopyWithImpl<EntryGroupTemplate>(
          this as EntryGroupTemplate, _$identity);

  /// Serializes this EntryGroupTemplate to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is EntryGroupTemplate &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.partyId, partyId) || other.partyId == partyId) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.birthYearMin, birthYearMin) ||
                other.birthYearMin == birthYearMin) &&
            (identical(other.birthYearMax, birthYearMax) ||
                other.birthYearMax == birthYearMax) &&
            const DeepCollectionEquality().equals(
                other.requiredVerificationIds, requiredVerificationIds) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      partyId,
      label,
      gender,
      birthYearMin,
      birthYearMax,
      const DeepCollectionEquality().hash(requiredVerificationIds),
      createdAt,
      updatedAt);

  @override
  String toString() {
    return 'EntryGroupTemplate(id: $id, partyId: $partyId, label: $label, gender: $gender, birthYearMin: $birthYearMin, birthYearMax: $birthYearMax, requiredVerificationIds: $requiredVerificationIds, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $EntryGroupTemplateCopyWith<$Res> {
  factory $EntryGroupTemplateCopyWith(
          EntryGroupTemplate value, $Res Function(EntryGroupTemplate) _then) =
      _$EntryGroupTemplateCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'party_id') String partyId,
      String? label,
      String? gender,
      @JsonKey(name: 'birth_year_min') int? birthYearMin,
      @JsonKey(name: 'birth_year_max') int? birthYearMax,
      @JsonKey(name: 'required_verification_ids')
      List<String> requiredVerificationIds,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class _$EntryGroupTemplateCopyWithImpl<$Res>
    implements $EntryGroupTemplateCopyWith<$Res> {
  _$EntryGroupTemplateCopyWithImpl(this._self, this._then);

  final EntryGroupTemplate _self;
  final $Res Function(EntryGroupTemplate) _then;

  /// Create a copy of EntryGroupTemplate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? partyId = null,
    Object? label = freezed,
    Object? gender = freezed,
    Object? birthYearMin = freezed,
    Object? birthYearMax = freezed,
    Object? requiredVerificationIds = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      partyId: null == partyId
          ? _self.partyId
          : partyId // ignore: cast_nullable_to_non_nullable
              as String,
      label: freezed == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String?,
      gender: freezed == gender
          ? _self.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String?,
      birthYearMin: freezed == birthYearMin
          ? _self.birthYearMin
          : birthYearMin // ignore: cast_nullable_to_non_nullable
              as int?,
      birthYearMax: freezed == birthYearMax
          ? _self.birthYearMax
          : birthYearMax // ignore: cast_nullable_to_non_nullable
              as int?,
      requiredVerificationIds: null == requiredVerificationIds
          ? _self.requiredVerificationIds
          : requiredVerificationIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// Adds pattern-matching-related methods to [EntryGroupTemplate].
extension EntryGroupTemplatePatterns on EntryGroupTemplate {
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
    TResult Function(_EntryGroupTemplate value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _EntryGroupTemplate() when $default != null:
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
    TResult Function(_EntryGroupTemplate value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EntryGroupTemplate():
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
    TResult? Function(_EntryGroupTemplate value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EntryGroupTemplate() when $default != null:
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
            String id,
            @JsonKey(name: 'party_id') String partyId,
            String? label,
            String? gender,
            @JsonKey(name: 'birth_year_min') int? birthYearMin,
            @JsonKey(name: 'birth_year_max') int? birthYearMax,
            @JsonKey(name: 'required_verification_ids')
            List<String> requiredVerificationIds,
            @JsonKey(name: 'created_at') DateTime? createdAt,
            @JsonKey(name: 'updated_at') DateTime? updatedAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _EntryGroupTemplate() when $default != null:
        return $default(
            _that.id,
            _that.partyId,
            _that.label,
            _that.gender,
            _that.birthYearMin,
            _that.birthYearMax,
            _that.requiredVerificationIds,
            _that.createdAt,
            _that.updatedAt);
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
            String id,
            @JsonKey(name: 'party_id') String partyId,
            String? label,
            String? gender,
            @JsonKey(name: 'birth_year_min') int? birthYearMin,
            @JsonKey(name: 'birth_year_max') int? birthYearMax,
            @JsonKey(name: 'required_verification_ids')
            List<String> requiredVerificationIds,
            @JsonKey(name: 'created_at') DateTime? createdAt,
            @JsonKey(name: 'updated_at') DateTime? updatedAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EntryGroupTemplate():
        return $default(
            _that.id,
            _that.partyId,
            _that.label,
            _that.gender,
            _that.birthYearMin,
            _that.birthYearMax,
            _that.requiredVerificationIds,
            _that.createdAt,
            _that.updatedAt);
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
            String id,
            @JsonKey(name: 'party_id') String partyId,
            String? label,
            String? gender,
            @JsonKey(name: 'birth_year_min') int? birthYearMin,
            @JsonKey(name: 'birth_year_max') int? birthYearMax,
            @JsonKey(name: 'required_verification_ids')
            List<String> requiredVerificationIds,
            @JsonKey(name: 'created_at') DateTime? createdAt,
            @JsonKey(name: 'updated_at') DateTime? updatedAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EntryGroupTemplate() when $default != null:
        return $default(
            _that.id,
            _that.partyId,
            _that.label,
            _that.gender,
            _that.birthYearMin,
            _that.birthYearMax,
            _that.requiredVerificationIds,
            _that.createdAt,
            _that.updatedAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _EntryGroupTemplate implements EntryGroupTemplate {
  const _EntryGroupTemplate(
      {required this.id,
      @JsonKey(name: 'party_id') required this.partyId,
      this.label,
      this.gender,
      @JsonKey(name: 'birth_year_min') this.birthYearMin,
      @JsonKey(name: 'birth_year_max') this.birthYearMax,
      @JsonKey(name: 'required_verification_ids')
      final List<String> requiredVerificationIds = const [],
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'updated_at') this.updatedAt})
      : _requiredVerificationIds = requiredVerificationIds;
  factory _EntryGroupTemplate.fromJson(Map<String, dynamic> json) =>
      _$EntryGroupTemplateFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'party_id')
  final String partyId;
  @override
  final String? label;
  @override
  final String? gender;
  @override
  @JsonKey(name: 'birth_year_min')
  final int? birthYearMin;
  @override
  @JsonKey(name: 'birth_year_max')
  final int? birthYearMax;
  final List<String> _requiredVerificationIds;
  @override
  @JsonKey(name: 'required_verification_ids')
  List<String> get requiredVerificationIds {
    if (_requiredVerificationIds is EqualUnmodifiableListView)
      return _requiredVerificationIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_requiredVerificationIds);
  }

  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  /// Create a copy of EntryGroupTemplate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$EntryGroupTemplateCopyWith<_EntryGroupTemplate> get copyWith =>
      __$EntryGroupTemplateCopyWithImpl<_EntryGroupTemplate>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$EntryGroupTemplateToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _EntryGroupTemplate &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.partyId, partyId) || other.partyId == partyId) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.birthYearMin, birthYearMin) ||
                other.birthYearMin == birthYearMin) &&
            (identical(other.birthYearMax, birthYearMax) ||
                other.birthYearMax == birthYearMax) &&
            const DeepCollectionEquality().equals(
                other._requiredVerificationIds, _requiredVerificationIds) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      partyId,
      label,
      gender,
      birthYearMin,
      birthYearMax,
      const DeepCollectionEquality().hash(_requiredVerificationIds),
      createdAt,
      updatedAt);

  @override
  String toString() {
    return 'EntryGroupTemplate(id: $id, partyId: $partyId, label: $label, gender: $gender, birthYearMin: $birthYearMin, birthYearMax: $birthYearMax, requiredVerificationIds: $requiredVerificationIds, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$EntryGroupTemplateCopyWith<$Res>
    implements $EntryGroupTemplateCopyWith<$Res> {
  factory _$EntryGroupTemplateCopyWith(
          _EntryGroupTemplate value, $Res Function(_EntryGroupTemplate) _then) =
      __$EntryGroupTemplateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'party_id') String partyId,
      String? label,
      String? gender,
      @JsonKey(name: 'birth_year_min') int? birthYearMin,
      @JsonKey(name: 'birth_year_max') int? birthYearMax,
      @JsonKey(name: 'required_verification_ids')
      List<String> requiredVerificationIds,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class __$EntryGroupTemplateCopyWithImpl<$Res>
    implements _$EntryGroupTemplateCopyWith<$Res> {
  __$EntryGroupTemplateCopyWithImpl(this._self, this._then);

  final _EntryGroupTemplate _self;
  final $Res Function(_EntryGroupTemplate) _then;

  /// Create a copy of EntryGroupTemplate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? partyId = null,
    Object? label = freezed,
    Object? gender = freezed,
    Object? birthYearMin = freezed,
    Object? birthYearMax = freezed,
    Object? requiredVerificationIds = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_EntryGroupTemplate(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      partyId: null == partyId
          ? _self.partyId
          : partyId // ignore: cast_nullable_to_non_nullable
              as String,
      label: freezed == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String?,
      gender: freezed == gender
          ? _self.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String?,
      birthYearMin: freezed == birthYearMin
          ? _self.birthYearMin
          : birthYearMin // ignore: cast_nullable_to_non_nullable
              as int?,
      birthYearMax: freezed == birthYearMax
          ? _self.birthYearMax
          : birthYearMax // ignore: cast_nullable_to_non_nullable
              as int?,
      requiredVerificationIds: null == requiredVerificationIds
          ? _self._requiredVerificationIds
          : requiredVerificationIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
mixin _$EntryGroup {
  String get id;
  @JsonKey(name: 'event_id')
  String get eventId;
  String? get label;
  String? get gender;
  @JsonKey(name: 'birth_year_min')
  int? get birthYearMin;
  @JsonKey(name: 'birth_year_max')
  int? get birthYearMax;
  @JsonKey(name: 'required_verification_ids')
  List<String> get requiredVerificationIds;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of EntryGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $EntryGroupCopyWith<EntryGroup> get copyWith =>
      _$EntryGroupCopyWithImpl<EntryGroup>(this as EntryGroup, _$identity);

  /// Serializes this EntryGroup to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is EntryGroup &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.eventId, eventId) || other.eventId == eventId) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.birthYearMin, birthYearMin) ||
                other.birthYearMin == birthYearMin) &&
            (identical(other.birthYearMax, birthYearMax) ||
                other.birthYearMax == birthYearMax) &&
            const DeepCollectionEquality().equals(
                other.requiredVerificationIds, requiredVerificationIds) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      eventId,
      label,
      gender,
      birthYearMin,
      birthYearMax,
      const DeepCollectionEquality().hash(requiredVerificationIds),
      createdAt,
      updatedAt);

  @override
  String toString() {
    return 'EntryGroup(id: $id, eventId: $eventId, label: $label, gender: $gender, birthYearMin: $birthYearMin, birthYearMax: $birthYearMax, requiredVerificationIds: $requiredVerificationIds, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $EntryGroupCopyWith<$Res> {
  factory $EntryGroupCopyWith(
          EntryGroup value, $Res Function(EntryGroup) _then) =
      _$EntryGroupCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'event_id') String eventId,
      String? label,
      String? gender,
      @JsonKey(name: 'birth_year_min') int? birthYearMin,
      @JsonKey(name: 'birth_year_max') int? birthYearMax,
      @JsonKey(name: 'required_verification_ids')
      List<String> requiredVerificationIds,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class _$EntryGroupCopyWithImpl<$Res> implements $EntryGroupCopyWith<$Res> {
  _$EntryGroupCopyWithImpl(this._self, this._then);

  final EntryGroup _self;
  final $Res Function(EntryGroup) _then;

  /// Create a copy of EntryGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? eventId = null,
    Object? label = freezed,
    Object? gender = freezed,
    Object? birthYearMin = freezed,
    Object? birthYearMax = freezed,
    Object? requiredVerificationIds = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      eventId: null == eventId
          ? _self.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String,
      label: freezed == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String?,
      gender: freezed == gender
          ? _self.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String?,
      birthYearMin: freezed == birthYearMin
          ? _self.birthYearMin
          : birthYearMin // ignore: cast_nullable_to_non_nullable
              as int?,
      birthYearMax: freezed == birthYearMax
          ? _self.birthYearMax
          : birthYearMax // ignore: cast_nullable_to_non_nullable
              as int?,
      requiredVerificationIds: null == requiredVerificationIds
          ? _self.requiredVerificationIds
          : requiredVerificationIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// Adds pattern-matching-related methods to [EntryGroup].
extension EntryGroupPatterns on EntryGroup {
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
    TResult Function(_EntryGroup value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _EntryGroup() when $default != null:
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
    TResult Function(_EntryGroup value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EntryGroup():
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
    TResult? Function(_EntryGroup value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EntryGroup() when $default != null:
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
            String id,
            @JsonKey(name: 'event_id') String eventId,
            String? label,
            String? gender,
            @JsonKey(name: 'birth_year_min') int? birthYearMin,
            @JsonKey(name: 'birth_year_max') int? birthYearMax,
            @JsonKey(name: 'required_verification_ids')
            List<String> requiredVerificationIds,
            @JsonKey(name: 'created_at') DateTime? createdAt,
            @JsonKey(name: 'updated_at') DateTime? updatedAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _EntryGroup() when $default != null:
        return $default(
            _that.id,
            _that.eventId,
            _that.label,
            _that.gender,
            _that.birthYearMin,
            _that.birthYearMax,
            _that.requiredVerificationIds,
            _that.createdAt,
            _that.updatedAt);
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
            String id,
            @JsonKey(name: 'event_id') String eventId,
            String? label,
            String? gender,
            @JsonKey(name: 'birth_year_min') int? birthYearMin,
            @JsonKey(name: 'birth_year_max') int? birthYearMax,
            @JsonKey(name: 'required_verification_ids')
            List<String> requiredVerificationIds,
            @JsonKey(name: 'created_at') DateTime? createdAt,
            @JsonKey(name: 'updated_at') DateTime? updatedAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EntryGroup():
        return $default(
            _that.id,
            _that.eventId,
            _that.label,
            _that.gender,
            _that.birthYearMin,
            _that.birthYearMax,
            _that.requiredVerificationIds,
            _that.createdAt,
            _that.updatedAt);
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
            String id,
            @JsonKey(name: 'event_id') String eventId,
            String? label,
            String? gender,
            @JsonKey(name: 'birth_year_min') int? birthYearMin,
            @JsonKey(name: 'birth_year_max') int? birthYearMax,
            @JsonKey(name: 'required_verification_ids')
            List<String> requiredVerificationIds,
            @JsonKey(name: 'created_at') DateTime? createdAt,
            @JsonKey(name: 'updated_at') DateTime? updatedAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EntryGroup() when $default != null:
        return $default(
            _that.id,
            _that.eventId,
            _that.label,
            _that.gender,
            _that.birthYearMin,
            _that.birthYearMax,
            _that.requiredVerificationIds,
            _that.createdAt,
            _that.updatedAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _EntryGroup implements EntryGroup {
  const _EntryGroup(
      {required this.id,
      @JsonKey(name: 'event_id') required this.eventId,
      this.label,
      this.gender,
      @JsonKey(name: 'birth_year_min') this.birthYearMin,
      @JsonKey(name: 'birth_year_max') this.birthYearMax,
      @JsonKey(name: 'required_verification_ids')
      final List<String> requiredVerificationIds = const [],
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'updated_at') this.updatedAt})
      : _requiredVerificationIds = requiredVerificationIds;
  factory _EntryGroup.fromJson(Map<String, dynamic> json) =>
      _$EntryGroupFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'event_id')
  final String eventId;
  @override
  final String? label;
  @override
  final String? gender;
  @override
  @JsonKey(name: 'birth_year_min')
  final int? birthYearMin;
  @override
  @JsonKey(name: 'birth_year_max')
  final int? birthYearMax;
  final List<String> _requiredVerificationIds;
  @override
  @JsonKey(name: 'required_verification_ids')
  List<String> get requiredVerificationIds {
    if (_requiredVerificationIds is EqualUnmodifiableListView)
      return _requiredVerificationIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_requiredVerificationIds);
  }

  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  /// Create a copy of EntryGroup
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$EntryGroupCopyWith<_EntryGroup> get copyWith =>
      __$EntryGroupCopyWithImpl<_EntryGroup>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$EntryGroupToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _EntryGroup &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.eventId, eventId) || other.eventId == eventId) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.birthYearMin, birthYearMin) ||
                other.birthYearMin == birthYearMin) &&
            (identical(other.birthYearMax, birthYearMax) ||
                other.birthYearMax == birthYearMax) &&
            const DeepCollectionEquality().equals(
                other._requiredVerificationIds, _requiredVerificationIds) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      eventId,
      label,
      gender,
      birthYearMin,
      birthYearMax,
      const DeepCollectionEquality().hash(_requiredVerificationIds),
      createdAt,
      updatedAt);

  @override
  String toString() {
    return 'EntryGroup(id: $id, eventId: $eventId, label: $label, gender: $gender, birthYearMin: $birthYearMin, birthYearMax: $birthYearMax, requiredVerificationIds: $requiredVerificationIds, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$EntryGroupCopyWith<$Res>
    implements $EntryGroupCopyWith<$Res> {
  factory _$EntryGroupCopyWith(
          _EntryGroup value, $Res Function(_EntryGroup) _then) =
      __$EntryGroupCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'event_id') String eventId,
      String? label,
      String? gender,
      @JsonKey(name: 'birth_year_min') int? birthYearMin,
      @JsonKey(name: 'birth_year_max') int? birthYearMax,
      @JsonKey(name: 'required_verification_ids')
      List<String> requiredVerificationIds,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class __$EntryGroupCopyWithImpl<$Res> implements _$EntryGroupCopyWith<$Res> {
  __$EntryGroupCopyWithImpl(this._self, this._then);

  final _EntryGroup _self;
  final $Res Function(_EntryGroup) _then;

  /// Create a copy of EntryGroup
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? eventId = null,
    Object? label = freezed,
    Object? gender = freezed,
    Object? birthYearMin = freezed,
    Object? birthYearMax = freezed,
    Object? requiredVerificationIds = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_EntryGroup(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      eventId: null == eventId
          ? _self.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String,
      label: freezed == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String?,
      gender: freezed == gender
          ? _self.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String?,
      birthYearMin: freezed == birthYearMin
          ? _self.birthYearMin
          : birthYearMin // ignore: cast_nullable_to_non_nullable
              as int?,
      birthYearMax: freezed == birthYearMax
          ? _self.birthYearMax
          : birthYearMax // ignore: cast_nullable_to_non_nullable
              as int?,
      requiredVerificationIds: null == requiredVerificationIds
          ? _self._requiredVerificationIds
          : requiredVerificationIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
