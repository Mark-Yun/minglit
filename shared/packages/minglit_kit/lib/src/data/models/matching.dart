import 'package:freezed_annotation/freezed_annotation.dart';

part 'matching.freezed.dart';
part 'matching.g.dart';

/// **Match Rule Model**
/// Defines which groups can interact in an event.
@freezed
abstract class MatchRule with _$MatchRule {
  /// Creates a [MatchRule] defining group interaction rules.
  const factory MatchRule({
    required String id,
    @JsonKey(name: 'event_id') required String eventId,
    @JsonKey(name: 'source_group_id') required String sourceGroupId,
    @JsonKey(name: 'target_group_id') required String targetGroupId,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _MatchRule;

  /// Creates a [MatchRule] from a JSON map.
  factory MatchRule.fromJson(Map<String, dynamic> json) =>
      _$MatchRuleFromJson(json);
}

/// **Match Vote Model**
/// Represents a user's vote for another user.
@freezed
abstract class MatchVote with _$MatchVote {
  /// Creates a [MatchVote] representing a user's vote.
  const factory MatchVote({
    @JsonKey(name: 'event_id') required String eventId,
    @JsonKey(name: 'voter_id') required String voterId,
    @JsonKey(name: 'candidate_id') required String candidateId,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _MatchVote;

  /// Creates a [MatchVote] from a JSON map.
  factory MatchVote.fromJson(Map<String, dynamic> json) =>
      _$MatchVoteFromJson(json);
}

/// **Match Pair Model** (Client View)
/// Represents a successful match, viewed from the current user's perspective.
@freezed
abstract class MatchPair with _$MatchPair {
  /// Creates a [MatchPair] for a successful match view.
  const factory MatchPair({
    @JsonKey(name: 'match_id') required String matchId,
    @JsonKey(name: 'event_id') required String eventId,
    @JsonKey(name: 'partner_id') required String partnerId,
    @JsonKey(name: 'matched_at') required DateTime matchedAt,

    // Optional: Partner profile details (if joined)
    @JsonKey(includeFromJson: false) String? partnerName,
    @JsonKey(includeFromJson: false) String? partnerProfileImage,
    @JsonKey(includeFromJson: false) String? partnerContact,
  }) = _MatchPair;

  /// Creates a [MatchPair] from a JSON map.
  factory MatchPair.fromJson(Map<String, dynamic> json) =>
      _$MatchPairFromJson(json);
}
