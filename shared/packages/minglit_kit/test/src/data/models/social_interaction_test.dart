import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/social_interaction.dart';

void main() {
  final now = DateTime(2026, 1, 15, 12);

  group('SocialInteraction', () {
    Map<String, dynamic> interactionJson() => {
      'userId': 'user_1',
      'targetId': 'party_1',
      'targetType': 'party',
      'interactionType': 'like',
      'createdAt': now.toIso8601String(),
    };

    test('creates from JSON', () {
      final interaction = SocialInteraction.fromJson(interactionJson());

      expect(interaction.userId, 'user_1');
      expect(interaction.targetId, 'party_1');
      expect(interaction.targetType, SocialTargetType.party);
      expect(interaction.interactionType, SocialInteractionType.like);
    });

    test('parses all target types', () {
      for (final type in ['party', 'partner', 'review', 'comment']) {
        final i = SocialInteraction.fromJson({
          ...interactionJson(),
          'targetType': type,
        });
        expect(i.targetType, isNotNull);
      }
    });

    test('parses all interaction types', () {
      for (final type in [
        'like',
        'subscribe',
        'bookmark',
        'block',
        'report',
        'dislike',
      ]) {
        final i = SocialInteraction.fromJson({
          ...interactionJson(),
          'interactionType': type,
        });
        expect(i.interactionType, isNotNull);
      }
    });

    test('serializes to JSON and back', () {
      final original = SocialInteraction.fromJson(interactionJson());
      final json = original.toJson();
      final restored = SocialInteraction.fromJson(json);
      expect(restored, equals(original));
    });

    test('equality works', () {
      final i1 = SocialInteraction.fromJson(interactionJson());
      final i2 = SocialInteraction.fromJson(interactionJson());
      expect(i1, equals(i2));
    });

    test('creates without optional createdAt', () {
      final i = SocialInteraction.fromJson({
        'userId': 'u1',
        'targetId': 't1',
        'targetType': 'partner',
        'interactionType': 'subscribe',
      });
      expect(i.createdAt, isNull);
    });
  });

  group('SocialTargetType', () {
    test('has all expected values', () {
      expect(SocialTargetType.values, hasLength(4));
      expect(SocialTargetType.values, contains(SocialTargetType.party));
      expect(SocialTargetType.values, contains(SocialTargetType.partner));
      expect(SocialTargetType.values, contains(SocialTargetType.review));
      expect(SocialTargetType.values, contains(SocialTargetType.comment));
    });
  });

  group('SocialInteractionType', () {
    test('has all expected values', () {
      expect(SocialInteractionType.values, hasLength(6));
      expect(
        SocialInteractionType.values,
        contains(SocialInteractionType.like),
      );
      expect(
        SocialInteractionType.values,
        contains(SocialInteractionType.subscribe),
      );
      expect(
        SocialInteractionType.values,
        contains(SocialInteractionType.bookmark),
      );
      expect(
        SocialInteractionType.values,
        contains(SocialInteractionType.block),
      );
      expect(
        SocialInteractionType.values,
        contains(SocialInteractionType.report),
      );
      expect(
        SocialInteractionType.values,
        contains(SocialInteractionType.dislike),
      );
    });
  });
}
