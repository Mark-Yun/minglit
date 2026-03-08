import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/matching.dart';

void main() {
  final now = DateTime(2026, 1, 15, 12);

  group('MatchRule', () {
    Map<String, dynamic> ruleJson() => {
      'id': 'rule_1',
      'event_id': 'event_1',
      'source_group_id': 'group_a',
      'target_group_id': 'group_b',
      'created_at': now.toIso8601String(),
    };

    test('creates from JSON', () {
      final rule = MatchRule.fromJson(ruleJson());

      expect(rule.id, 'rule_1');
      expect(rule.eventId, 'event_1');
      expect(rule.sourceGroupId, 'group_a');
      expect(rule.targetGroupId, 'group_b');
    });

    test('serializes to JSON and back', () {
      final original = MatchRule.fromJson(ruleJson());
      final json = original.toJson();
      final restored = MatchRule.fromJson(json);
      expect(restored, equals(original));
    });

    test('equality works', () {
      final r1 = MatchRule.fromJson(ruleJson());
      final r2 = MatchRule.fromJson(ruleJson());
      expect(r1, equals(r2));
    });

    test('copyWith creates modified copy', () {
      final rule = MatchRule.fromJson(ruleJson());
      final modified = rule.copyWith(sourceGroupId: 'group_c');
      expect(modified.sourceGroupId, 'group_c');
      expect(modified.id, 'rule_1');
    });

    test('JSON contains expected keys', () {
      final rule = MatchRule.fromJson(ruleJson());
      final json = rule.toJson();
      expect(json.containsKey('event_id'), isTrue);
      expect(json.containsKey('source_group_id'), isTrue);
      expect(json.containsKey('target_group_id'), isTrue);
    });
  });

  group('MatchVote', () {
    Map<String, dynamic> voteJson() => {
      'event_id': 'event_1',
      'voter_id': 'user_1',
      'candidate_id': 'user_2',
      'created_at': now.toIso8601String(),
    };

    test('creates from JSON', () {
      final vote = MatchVote.fromJson(voteJson());

      expect(vote.eventId, 'event_1');
      expect(vote.voterId, 'user_1');
      expect(vote.candidateId, 'user_2');
    });

    test('serializes to JSON and back', () {
      final original = MatchVote.fromJson(voteJson());
      final json = original.toJson();
      final restored = MatchVote.fromJson(json);
      expect(restored, equals(original));
    });

    test('equality works', () {
      final v1 = MatchVote.fromJson(voteJson());
      final v2 = MatchVote.fromJson(voteJson());
      expect(v1, equals(v2));
    });
  });

  group('MatchPair', () {
    Map<String, dynamic> pairJson() => {
      'match_id': 'match_1',
      'event_id': 'event_1',
      'partner_id': 'user_2',
      'matched_at': now.toIso8601String(),
    };

    test('creates from JSON', () {
      final pair = MatchPair.fromJson(pairJson());

      expect(pair.matchId, 'match_1');
      expect(pair.eventId, 'event_1');
      expect(pair.partnerId, 'user_2');
    });

    test('serializes to JSON and back', () {
      final original = MatchPair.fromJson(pairJson());
      final json = original.toJson();
      final restored = MatchPair.fromJson(json);
      expect(restored, equals(original));
    });

    test('equality works', () {
      final p1 = MatchPair.fromJson(pairJson());
      final p2 = MatchPair.fromJson(pairJson());
      expect(p1, equals(p2));
    });

    test('partner profile fields are excluded from JSON', () {
      final pair = MatchPair.fromJson(pairJson());
      expect(pair.partnerName, isNull);
      expect(pair.partnerProfileImage, isNull);
      expect(pair.partnerContact, isNull);
    });
  });
}
