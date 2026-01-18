import 'package:freezed_annotation/freezed_annotation.dart';

part 'social_interaction.freezed.dart';
part 'social_interaction.g.dart';

enum SocialTargetType {
  party,
  partner,
  review,
  comment,
}

enum SocialInteractionType {
  like,
  subscribe,
  bookmark,
  block,
}

@freezed
abstract class SocialInteraction with _$SocialInteraction {
  const factory SocialInteraction({
    required String userId,
    required String targetId,
    required SocialTargetType targetType,
    required SocialInteractionType interactionType,
    DateTime? createdAt,
  }) = _SocialInteraction;

  factory SocialInteraction.fromJson(Map<String, dynamic> json) =>
      _$SocialInteractionFromJson(json);
}
