// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'matching.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MatchRule {
  String get id;
  @JsonKey(name: 'event_id')
  String get eventId;
  @JsonKey(name: 'source_group_id')
  String get sourceGroupId;
  @JsonKey(name: 'target_group_id')
  String get targetGroupId;
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Create a copy of MatchRule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MatchRuleCopyWith<MatchRule> get copyWith =>
      _$MatchRuleCopyWithImpl<MatchRule>(this as MatchRule, _$identity);

  /// Serializes this MatchRule to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MatchRule &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.eventId, eventId) || other.eventId == eventId) &&
            (identical(other.sourceGroupId, sourceGroupId) ||
                other.sourceGroupId == sourceGroupId) &&
            (identical(other.targetGroupId, targetGroupId) ||
                other.targetGroupId == targetGroupId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, eventId, sourceGroupId, targetGroupId, createdAt);

  @override
  String toString() {
    return 'MatchRule(id: $id, eventId: $eventId, sourceGroupId: $sourceGroupId, targetGroupId: $targetGroupId, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class $MatchRuleCopyWith<$Res> {
  factory $MatchRuleCopyWith(MatchRule value, $Res Function(MatchRule) _then) =
      _$MatchRuleCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'event_id') String eventId,
      @JsonKey(name: 'source_group_id') String sourceGroupId,
      @JsonKey(name: 'target_group_id') String targetGroupId,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class _$MatchRuleCopyWithImpl<$Res> implements $MatchRuleCopyWith<$Res> {
  _$MatchRuleCopyWithImpl(this._self, this._then);

  final MatchRule _self;
  final $Res Function(MatchRule) _then;

  /// Create a copy of MatchRule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? eventId = null,
    Object? sourceGroupId = null,
    Object? targetGroupId = null,
    Object? createdAt = null,
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
      sourceGroupId: null == sourceGroupId
          ? _self.sourceGroupId
          : sourceGroupId // ignore: cast_nullable_to_non_nullable
              as String,
      targetGroupId: null == targetGroupId
          ? _self.targetGroupId
          : targetGroupId // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// Adds pattern-matching-related methods to [MatchRule].
extension MatchRulePatterns on MatchRule {
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
    TResult Function(_MatchRule value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MatchRule() when $default != null:
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
    TResult Function(_MatchRule value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MatchRule():
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
    TResult? Function(_MatchRule value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MatchRule() when $default != null:
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
            @JsonKey(name: 'source_group_id') String sourceGroupId,
            @JsonKey(name: 'target_group_id') String targetGroupId,
            @JsonKey(name: 'created_at') DateTime createdAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MatchRule() when $default != null:
        return $default(_that.id, _that.eventId, _that.sourceGroupId,
            _that.targetGroupId, _that.createdAt);
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
            @JsonKey(name: 'source_group_id') String sourceGroupId,
            @JsonKey(name: 'target_group_id') String targetGroupId,
            @JsonKey(name: 'created_at') DateTime createdAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MatchRule():
        return $default(_that.id, _that.eventId, _that.sourceGroupId,
            _that.targetGroupId, _that.createdAt);
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
            @JsonKey(name: 'source_group_id') String sourceGroupId,
            @JsonKey(name: 'target_group_id') String targetGroupId,
            @JsonKey(name: 'created_at') DateTime createdAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MatchRule() when $default != null:
        return $default(_that.id, _that.eventId, _that.sourceGroupId,
            _that.targetGroupId, _that.createdAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _MatchRule implements MatchRule {
  const _MatchRule(
      {required this.id,
      @JsonKey(name: 'event_id') required this.eventId,
      @JsonKey(name: 'source_group_id') required this.sourceGroupId,
      @JsonKey(name: 'target_group_id') required this.targetGroupId,
      @JsonKey(name: 'created_at') required this.createdAt});
  factory _MatchRule.fromJson(Map<String, dynamic> json) =>
      _$MatchRuleFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'event_id')
  final String eventId;
  @override
  @JsonKey(name: 'source_group_id')
  final String sourceGroupId;
  @override
  @JsonKey(name: 'target_group_id')
  final String targetGroupId;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// Create a copy of MatchRule
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MatchRuleCopyWith<_MatchRule> get copyWith =>
      __$MatchRuleCopyWithImpl<_MatchRule>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$MatchRuleToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MatchRule &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.eventId, eventId) || other.eventId == eventId) &&
            (identical(other.sourceGroupId, sourceGroupId) ||
                other.sourceGroupId == sourceGroupId) &&
            (identical(other.targetGroupId, targetGroupId) ||
                other.targetGroupId == targetGroupId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, eventId, sourceGroupId, targetGroupId, createdAt);

  @override
  String toString() {
    return 'MatchRule(id: $id, eventId: $eventId, sourceGroupId: $sourceGroupId, targetGroupId: $targetGroupId, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class _$MatchRuleCopyWith<$Res>
    implements $MatchRuleCopyWith<$Res> {
  factory _$MatchRuleCopyWith(
          _MatchRule value, $Res Function(_MatchRule) _then) =
      __$MatchRuleCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'event_id') String eventId,
      @JsonKey(name: 'source_group_id') String sourceGroupId,
      @JsonKey(name: 'target_group_id') String targetGroupId,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class __$MatchRuleCopyWithImpl<$Res> implements _$MatchRuleCopyWith<$Res> {
  __$MatchRuleCopyWithImpl(this._self, this._then);

  final _MatchRule _self;
  final $Res Function(_MatchRule) _then;

  /// Create a copy of MatchRule
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? eventId = null,
    Object? sourceGroupId = null,
    Object? targetGroupId = null,
    Object? createdAt = null,
  }) {
    return _then(_MatchRule(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      eventId: null == eventId
          ? _self.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String,
      sourceGroupId: null == sourceGroupId
          ? _self.sourceGroupId
          : sourceGroupId // ignore: cast_nullable_to_non_nullable
              as String,
      targetGroupId: null == targetGroupId
          ? _self.targetGroupId
          : targetGroupId // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
mixin _$MatchVote {
  @JsonKey(name: 'event_id')
  String get eventId;
  @JsonKey(name: 'voter_id')
  String get voterId;
  @JsonKey(name: 'candidate_id')
  String get candidateId;
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Create a copy of MatchVote
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MatchVoteCopyWith<MatchVote> get copyWith =>
      _$MatchVoteCopyWithImpl<MatchVote>(this as MatchVote, _$identity);

  /// Serializes this MatchVote to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MatchVote &&
            (identical(other.eventId, eventId) || other.eventId == eventId) &&
            (identical(other.voterId, voterId) || other.voterId == voterId) &&
            (identical(other.candidateId, candidateId) ||
                other.candidateId == candidateId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, eventId, voterId, candidateId, createdAt);

  @override
  String toString() {
    return 'MatchVote(eventId: $eventId, voterId: $voterId, candidateId: $candidateId, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class $MatchVoteCopyWith<$Res> {
  factory $MatchVoteCopyWith(MatchVote value, $Res Function(MatchVote) _then) =
      _$MatchVoteCopyWithImpl;
  @useResult
  $Res call(
      {@JsonKey(name: 'event_id') String eventId,
      @JsonKey(name: 'voter_id') String voterId,
      @JsonKey(name: 'candidate_id') String candidateId,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class _$MatchVoteCopyWithImpl<$Res> implements $MatchVoteCopyWith<$Res> {
  _$MatchVoteCopyWithImpl(this._self, this._then);

  final MatchVote _self;
  final $Res Function(MatchVote) _then;

  /// Create a copy of MatchVote
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? eventId = null,
    Object? voterId = null,
    Object? candidateId = null,
    Object? createdAt = null,
  }) {
    return _then(_self.copyWith(
      eventId: null == eventId
          ? _self.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String,
      voterId: null == voterId
          ? _self.voterId
          : voterId // ignore: cast_nullable_to_non_nullable
              as String,
      candidateId: null == candidateId
          ? _self.candidateId
          : candidateId // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// Adds pattern-matching-related methods to [MatchVote].
extension MatchVotePatterns on MatchVote {
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
    TResult Function(_MatchVote value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MatchVote() when $default != null:
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
    TResult Function(_MatchVote value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MatchVote():
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
    TResult? Function(_MatchVote value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MatchVote() when $default != null:
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
            @JsonKey(name: 'event_id') String eventId,
            @JsonKey(name: 'voter_id') String voterId,
            @JsonKey(name: 'candidate_id') String candidateId,
            @JsonKey(name: 'created_at') DateTime createdAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MatchVote() when $default != null:
        return $default(
            _that.eventId, _that.voterId, _that.candidateId, _that.createdAt);
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
            @JsonKey(name: 'event_id') String eventId,
            @JsonKey(name: 'voter_id') String voterId,
            @JsonKey(name: 'candidate_id') String candidateId,
            @JsonKey(name: 'created_at') DateTime createdAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MatchVote():
        return $default(
            _that.eventId, _that.voterId, _that.candidateId, _that.createdAt);
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
            @JsonKey(name: 'event_id') String eventId,
            @JsonKey(name: 'voter_id') String voterId,
            @JsonKey(name: 'candidate_id') String candidateId,
            @JsonKey(name: 'created_at') DateTime createdAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MatchVote() when $default != null:
        return $default(
            _that.eventId, _that.voterId, _that.candidateId, _that.createdAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _MatchVote implements MatchVote {
  const _MatchVote(
      {@JsonKey(name: 'event_id') required this.eventId,
      @JsonKey(name: 'voter_id') required this.voterId,
      @JsonKey(name: 'candidate_id') required this.candidateId,
      @JsonKey(name: 'created_at') required this.createdAt});
  factory _MatchVote.fromJson(Map<String, dynamic> json) =>
      _$MatchVoteFromJson(json);

  @override
  @JsonKey(name: 'event_id')
  final String eventId;
  @override
  @JsonKey(name: 'voter_id')
  final String voterId;
  @override
  @JsonKey(name: 'candidate_id')
  final String candidateId;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// Create a copy of MatchVote
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MatchVoteCopyWith<_MatchVote> get copyWith =>
      __$MatchVoteCopyWithImpl<_MatchVote>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$MatchVoteToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MatchVote &&
            (identical(other.eventId, eventId) || other.eventId == eventId) &&
            (identical(other.voterId, voterId) || other.voterId == voterId) &&
            (identical(other.candidateId, candidateId) ||
                other.candidateId == candidateId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, eventId, voterId, candidateId, createdAt);

  @override
  String toString() {
    return 'MatchVote(eventId: $eventId, voterId: $voterId, candidateId: $candidateId, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class _$MatchVoteCopyWith<$Res>
    implements $MatchVoteCopyWith<$Res> {
  factory _$MatchVoteCopyWith(
          _MatchVote value, $Res Function(_MatchVote) _then) =
      __$MatchVoteCopyWithImpl;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'event_id') String eventId,
      @JsonKey(name: 'voter_id') String voterId,
      @JsonKey(name: 'candidate_id') String candidateId,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class __$MatchVoteCopyWithImpl<$Res> implements _$MatchVoteCopyWith<$Res> {
  __$MatchVoteCopyWithImpl(this._self, this._then);

  final _MatchVote _self;
  final $Res Function(_MatchVote) _then;

  /// Create a copy of MatchVote
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? eventId = null,
    Object? voterId = null,
    Object? candidateId = null,
    Object? createdAt = null,
  }) {
    return _then(_MatchVote(
      eventId: null == eventId
          ? _self.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String,
      voterId: null == voterId
          ? _self.voterId
          : voterId // ignore: cast_nullable_to_non_nullable
              as String,
      candidateId: null == candidateId
          ? _self.candidateId
          : candidateId // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
mixin _$MatchPair {
  @JsonKey(name: 'match_id')
  String get matchId;
  @JsonKey(name: 'event_id')
  String get eventId;
  @JsonKey(name: 'partner_id')
  String get partnerId;
  @JsonKey(name: 'matched_at')
  DateTime get matchedAt; // Optional: Partner profile details (if joined)
  @JsonKey(includeFromJson: false)
  String? get partnerName;
  @JsonKey(includeFromJson: false)
  String? get partnerProfileImage;
  @JsonKey(includeFromJson: false)
  String? get partnerContact;

  /// Create a copy of MatchPair
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MatchPairCopyWith<MatchPair> get copyWith =>
      _$MatchPairCopyWithImpl<MatchPair>(this as MatchPair, _$identity);

  /// Serializes this MatchPair to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MatchPair &&
            (identical(other.matchId, matchId) || other.matchId == matchId) &&
            (identical(other.eventId, eventId) || other.eventId == eventId) &&
            (identical(other.partnerId, partnerId) ||
                other.partnerId == partnerId) &&
            (identical(other.matchedAt, matchedAt) ||
                other.matchedAt == matchedAt) &&
            (identical(other.partnerName, partnerName) ||
                other.partnerName == partnerName) &&
            (identical(other.partnerProfileImage, partnerProfileImage) ||
                other.partnerProfileImage == partnerProfileImage) &&
            (identical(other.partnerContact, partnerContact) ||
                other.partnerContact == partnerContact));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, matchId, eventId, partnerId,
      matchedAt, partnerName, partnerProfileImage, partnerContact);

  @override
  String toString() {
    return 'MatchPair(matchId: $matchId, eventId: $eventId, partnerId: $partnerId, matchedAt: $matchedAt, partnerName: $partnerName, partnerProfileImage: $partnerProfileImage, partnerContact: $partnerContact)';
  }
}

/// @nodoc
abstract mixin class $MatchPairCopyWith<$Res> {
  factory $MatchPairCopyWith(MatchPair value, $Res Function(MatchPair) _then) =
      _$MatchPairCopyWithImpl;
  @useResult
  $Res call(
      {@JsonKey(name: 'match_id') String matchId,
      @JsonKey(name: 'event_id') String eventId,
      @JsonKey(name: 'partner_id') String partnerId,
      @JsonKey(name: 'matched_at') DateTime matchedAt,
      @JsonKey(includeFromJson: false) String? partnerName,
      @JsonKey(includeFromJson: false) String? partnerProfileImage,
      @JsonKey(includeFromJson: false) String? partnerContact});
}

/// @nodoc
class _$MatchPairCopyWithImpl<$Res> implements $MatchPairCopyWith<$Res> {
  _$MatchPairCopyWithImpl(this._self, this._then);

  final MatchPair _self;
  final $Res Function(MatchPair) _then;

  /// Create a copy of MatchPair
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? matchId = null,
    Object? eventId = null,
    Object? partnerId = null,
    Object? matchedAt = null,
    Object? partnerName = freezed,
    Object? partnerProfileImage = freezed,
    Object? partnerContact = freezed,
  }) {
    return _then(_self.copyWith(
      matchId: null == matchId
          ? _self.matchId
          : matchId // ignore: cast_nullable_to_non_nullable
              as String,
      eventId: null == eventId
          ? _self.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String,
      partnerId: null == partnerId
          ? _self.partnerId
          : partnerId // ignore: cast_nullable_to_non_nullable
              as String,
      matchedAt: null == matchedAt
          ? _self.matchedAt
          : matchedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      partnerName: freezed == partnerName
          ? _self.partnerName
          : partnerName // ignore: cast_nullable_to_non_nullable
              as String?,
      partnerProfileImage: freezed == partnerProfileImage
          ? _self.partnerProfileImage
          : partnerProfileImage // ignore: cast_nullable_to_non_nullable
              as String?,
      partnerContact: freezed == partnerContact
          ? _self.partnerContact
          : partnerContact // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [MatchPair].
extension MatchPairPatterns on MatchPair {
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
    TResult Function(_MatchPair value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MatchPair() when $default != null:
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
    TResult Function(_MatchPair value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MatchPair():
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
    TResult? Function(_MatchPair value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MatchPair() when $default != null:
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
            @JsonKey(name: 'match_id') String matchId,
            @JsonKey(name: 'event_id') String eventId,
            @JsonKey(name: 'partner_id') String partnerId,
            @JsonKey(name: 'matched_at') DateTime matchedAt,
            @JsonKey(includeFromJson: false) String? partnerName,
            @JsonKey(includeFromJson: false) String? partnerProfileImage,
            @JsonKey(includeFromJson: false) String? partnerContact)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MatchPair() when $default != null:
        return $default(
            _that.matchId,
            _that.eventId,
            _that.partnerId,
            _that.matchedAt,
            _that.partnerName,
            _that.partnerProfileImage,
            _that.partnerContact);
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
            @JsonKey(name: 'match_id') String matchId,
            @JsonKey(name: 'event_id') String eventId,
            @JsonKey(name: 'partner_id') String partnerId,
            @JsonKey(name: 'matched_at') DateTime matchedAt,
            @JsonKey(includeFromJson: false) String? partnerName,
            @JsonKey(includeFromJson: false) String? partnerProfileImage,
            @JsonKey(includeFromJson: false) String? partnerContact)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MatchPair():
        return $default(
            _that.matchId,
            _that.eventId,
            _that.partnerId,
            _that.matchedAt,
            _that.partnerName,
            _that.partnerProfileImage,
            _that.partnerContact);
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
            @JsonKey(name: 'match_id') String matchId,
            @JsonKey(name: 'event_id') String eventId,
            @JsonKey(name: 'partner_id') String partnerId,
            @JsonKey(name: 'matched_at') DateTime matchedAt,
            @JsonKey(includeFromJson: false) String? partnerName,
            @JsonKey(includeFromJson: false) String? partnerProfileImage,
            @JsonKey(includeFromJson: false) String? partnerContact)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MatchPair() when $default != null:
        return $default(
            _that.matchId,
            _that.eventId,
            _that.partnerId,
            _that.matchedAt,
            _that.partnerName,
            _that.partnerProfileImage,
            _that.partnerContact);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _MatchPair implements MatchPair {
  const _MatchPair(
      {@JsonKey(name: 'match_id') required this.matchId,
      @JsonKey(name: 'event_id') required this.eventId,
      @JsonKey(name: 'partner_id') required this.partnerId,
      @JsonKey(name: 'matched_at') required this.matchedAt,
      @JsonKey(includeFromJson: false) this.partnerName,
      @JsonKey(includeFromJson: false) this.partnerProfileImage,
      @JsonKey(includeFromJson: false) this.partnerContact});
  factory _MatchPair.fromJson(Map<String, dynamic> json) =>
      _$MatchPairFromJson(json);

  @override
  @JsonKey(name: 'match_id')
  final String matchId;
  @override
  @JsonKey(name: 'event_id')
  final String eventId;
  @override
  @JsonKey(name: 'partner_id')
  final String partnerId;
  @override
  @JsonKey(name: 'matched_at')
  final DateTime matchedAt;
// Optional: Partner profile details (if joined)
  @override
  @JsonKey(includeFromJson: false)
  final String? partnerName;
  @override
  @JsonKey(includeFromJson: false)
  final String? partnerProfileImage;
  @override
  @JsonKey(includeFromJson: false)
  final String? partnerContact;

  /// Create a copy of MatchPair
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MatchPairCopyWith<_MatchPair> get copyWith =>
      __$MatchPairCopyWithImpl<_MatchPair>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$MatchPairToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MatchPair &&
            (identical(other.matchId, matchId) || other.matchId == matchId) &&
            (identical(other.eventId, eventId) || other.eventId == eventId) &&
            (identical(other.partnerId, partnerId) ||
                other.partnerId == partnerId) &&
            (identical(other.matchedAt, matchedAt) ||
                other.matchedAt == matchedAt) &&
            (identical(other.partnerName, partnerName) ||
                other.partnerName == partnerName) &&
            (identical(other.partnerProfileImage, partnerProfileImage) ||
                other.partnerProfileImage == partnerProfileImage) &&
            (identical(other.partnerContact, partnerContact) ||
                other.partnerContact == partnerContact));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, matchId, eventId, partnerId,
      matchedAt, partnerName, partnerProfileImage, partnerContact);

  @override
  String toString() {
    return 'MatchPair(matchId: $matchId, eventId: $eventId, partnerId: $partnerId, matchedAt: $matchedAt, partnerName: $partnerName, partnerProfileImage: $partnerProfileImage, partnerContact: $partnerContact)';
  }
}

/// @nodoc
abstract mixin class _$MatchPairCopyWith<$Res>
    implements $MatchPairCopyWith<$Res> {
  factory _$MatchPairCopyWith(
          _MatchPair value, $Res Function(_MatchPair) _then) =
      __$MatchPairCopyWithImpl;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'match_id') String matchId,
      @JsonKey(name: 'event_id') String eventId,
      @JsonKey(name: 'partner_id') String partnerId,
      @JsonKey(name: 'matched_at') DateTime matchedAt,
      @JsonKey(includeFromJson: false) String? partnerName,
      @JsonKey(includeFromJson: false) String? partnerProfileImage,
      @JsonKey(includeFromJson: false) String? partnerContact});
}

/// @nodoc
class __$MatchPairCopyWithImpl<$Res> implements _$MatchPairCopyWith<$Res> {
  __$MatchPairCopyWithImpl(this._self, this._then);

  final _MatchPair _self;
  final $Res Function(_MatchPair) _then;

  /// Create a copy of MatchPair
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? matchId = null,
    Object? eventId = null,
    Object? partnerId = null,
    Object? matchedAt = null,
    Object? partnerName = freezed,
    Object? partnerProfileImage = freezed,
    Object? partnerContact = freezed,
  }) {
    return _then(_MatchPair(
      matchId: null == matchId
          ? _self.matchId
          : matchId // ignore: cast_nullable_to_non_nullable
              as String,
      eventId: null == eventId
          ? _self.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String,
      partnerId: null == partnerId
          ? _self.partnerId
          : partnerId // ignore: cast_nullable_to_non_nullable
              as String,
      matchedAt: null == matchedAt
          ? _self.matchedAt
          : matchedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      partnerName: freezed == partnerName
          ? _self.partnerName
          : partnerName // ignore: cast_nullable_to_non_nullable
              as String?,
      partnerProfileImage: freezed == partnerProfileImage
          ? _self.partnerProfileImage
          : partnerProfileImage // ignore: cast_nullable_to_non_nullable
              as String?,
      partnerContact: freezed == partnerContact
          ? _self.partnerContact
          : partnerContact // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
