import 'package:freezed_annotation/freezed_annotation.dart';

part 'social_interaction.freezed.dart';
part 'social_interaction.g.dart';

/// Target entity types for social interactions.
enum SocialTargetType {
  /// Party content such as events.
  party,

  /// Partner or venue profile.
  partner,

  /// Review content.
  review,

  /// Comment content.
  comment,
}

/// Types of social interaction actions.
enum SocialInteractionType {
  /// Indicates a like action.
  like,

  /// Indicates a subscribe action.
  subscribe,

  /// Indicates a bookmark action.
  bookmark,

  /// Indicates a block action.
  block,

  /// Indicates a report action.
  report,
}

/// Represents a user interaction with a social target.
@freezed
abstract class SocialInteraction with _$SocialInteraction {
  /// Creates a [SocialInteraction] record.
  const factory SocialInteraction({
    required String userId,
    required String targetId,
    required SocialTargetType targetType,
    required SocialInteractionType interactionType,
    DateTime? createdAt,
  }) = _SocialInteraction;

  /// Creates a [SocialInteraction] from a JSON map.
  factory SocialInteraction.fromJson(Map<String, dynamic> json) =>
      _$SocialInteractionFromJson(json);
}
