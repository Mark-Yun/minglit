import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/party_entry_group.dart';

void main() {
  final now = DateTime(2026, 1, 15, 12);

  group('EntryGroupTemplate', () {
    Map<String, dynamic> templateJson() => {
          'id': 'egt_1',
          'party_id': 'party_1',
          'label': 'VIP Group',
          'gender': 'male',
          'birth_year_min': 1990,
          'birth_year_max': 2000,
          'required_verification_ids': ['v1', 'v2'],
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        };

    test('creates from JSON with all fields', () {
      final t = EntryGroupTemplate.fromJson(templateJson());

      expect(t.id, 'egt_1');
      expect(t.partyId, 'party_1');
      expect(t.label, 'VIP Group');
      expect(t.gender, 'male');
      expect(t.birthYearMin, 1990);
      expect(t.birthYearMax, 2000);
      expect(t.requiredVerificationIds, ['v1', 'v2']);
    });

    test('creates from JSON with minimal fields', () {
      final t = EntryGroupTemplate.fromJson({
        'id': 'egt_2',
        'party_id': 'p1',
      });

      expect(t.label, isNull);
      expect(t.gender, isNull);
      expect(t.birthYearMin, isNull);
      expect(t.birthYearMax, isNull);
      expect(t.requiredVerificationIds, isEmpty);
    });

    test('serializes to JSON and back', () {
      final original = EntryGroupTemplate.fromJson(templateJson());
      final json = original.toJson();
      final restored = EntryGroupTemplate.fromJson(json);

      expect(restored, equals(original));
    });

    test('toDbJson removes id and timestamps', () {
      final t = EntryGroupTemplate.fromJson(templateJson());
      final dbJson = t.toDbJson();

      expect(dbJson.containsKey('id'), isFalse);
      expect(dbJson.containsKey('created_at'), isFalse);
      expect(dbJson.containsKey('updated_at'), isFalse);
      expect(dbJson.containsKey('party_id'), isTrue);
    });

    test('equality works', () {
      final t1 = EntryGroupTemplate.fromJson(templateJson());
      final t2 = EntryGroupTemplate.fromJson(templateJson());
      expect(t1, equals(t2));
    });

    test('copyWith creates modified copy', () {
      final t = EntryGroupTemplate.fromJson(templateJson());
      final modified = t.copyWith(label: 'General');
      expect(modified.label, 'General');
      expect(modified.id, 'egt_1');
    });
  });

  group('EntryGroup', () {
    Map<String, dynamic> groupJson() => {
          'id': 'eg_1',
          'event_id': 'event_1',
          'label': 'Group A',
          'gender': 'female',
          'birth_year_min': 1995,
          'birth_year_max': 2005,
          'required_verification_ids': ['v3'],
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        };

    test('creates from JSON with all fields', () {
      final g = EntryGroup.fromJson(groupJson());

      expect(g.id, 'eg_1');
      expect(g.eventId, 'event_1');
      expect(g.label, 'Group A');
      expect(g.gender, 'female');
      expect(g.birthYearMin, 1995);
      expect(g.birthYearMax, 2005);
      expect(g.requiredVerificationIds, ['v3']);
    });

    test('creates from JSON with minimal fields', () {
      final g = EntryGroup.fromJson({
        'id': 'eg_2',
        'event_id': 'e1',
      });

      expect(g.label, isNull);
      expect(g.gender, isNull);
      expect(g.requiredVerificationIds, isEmpty);
    });

    test('serializes to JSON and back', () {
      final original = EntryGroup.fromJson(groupJson());
      final json = original.toJson();
      final restored = EntryGroup.fromJson(json);
      expect(restored, equals(original));
    });

    test('toDbJson removes id and timestamps', () {
      final g = EntryGroup.fromJson(groupJson());
      final dbJson = g.toDbJson();

      expect(dbJson.containsKey('id'), isFalse);
      expect(dbJson.containsKey('created_at'), isFalse);
      expect(dbJson.containsKey('updated_at'), isFalse);
      expect(dbJson.containsKey('event_id'), isTrue);
    });

    test('toDbJson with custom eventId', () {
      final g = EntryGroup.fromJson(groupJson());
      final dbJson = g.toDbJson(eventId: 'new_event');

      expect(dbJson['event_id'], 'new_event');
    });

    test('createFromTemplate copies fields', () {
      final template = EntryGroupTemplate.fromJson({
        'id': 'egt_1',
        'party_id': 'party_1',
        'label': 'VIP',
        'gender': 'male',
        'birth_year_min': 1990,
        'birth_year_max': 2000,
        'required_verification_ids': ['v1'],
      });

      final group = EntryGroup.createFromTemplate(
        template,
        eventId: 'evt_1',
      );

      expect(group.id, '');
      expect(group.eventId, 'evt_1');
      expect(group.label, 'VIP');
      expect(group.gender, 'male');
      expect(group.birthYearMin, 1990);
      expect(group.birthYearMax, 2000);
      expect(group.requiredVerificationIds, ['v1']);
      expect(group.createdAt, isNotNull);
    });

    test('toTemplate converts to EntryGroupTemplate', () {
      final group = EntryGroup.fromJson(groupJson());
      final template = group.toTemplate();

      expect(template.id, 'eg_1');
      expect(template.partyId, '');
      expect(template.label, 'Group A');
      expect(template.gender, 'female');
      expect(template.birthYearMin, 1995);
      expect(template.birthYearMax, 2005);
      expect(template.requiredVerificationIds, ['v3']);
    });
  });
}
