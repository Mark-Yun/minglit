import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/event.dart';
import 'package:minglit_kit/src/data/models/party.dart';
import 'package:minglit_kit/src/data/models/party_entry_group.dart';

void main() {
  final now = DateTime(2026, 1, 15, 12);
  final later = DateTime(2026, 1, 15, 18);

  group('Event', () {
    Map<String, dynamic> eventJson() => {
      'id': 'event_1',
      'party_id': 'party_1',
      'start_time': now.toIso8601String(),
      'end_time': later.toIso8601String(),
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'title': 'Friday Night',
      'description': {'ops': <Map<String, dynamic>>[]},
      'image_urls': ['https://img.com/a.jpg'],
      'contact_options': {'phone': '010-1234'},
      'min_confirmed_count': 3,
      'max_participants': 25,
      'current_participants': 10,
      'status': 'scheduled',
      'metadata': <String, dynamic>{},
    };

    test('creates from JSON with all fields', () {
      final event = Event.fromJson(eventJson());

      expect(event.id, 'event_1');
      expect(event.partyId, 'party_1');
      expect(event.title, 'Friday Night');
      expect(event.imageUrls, ['https://img.com/a.jpg']);
      expect(event.contactOptions['phone'], '010-1234');
      expect(event.minConfirmedCount, 3);
      expect(event.maxParticipants, 25);
      expect(event.currentParticipants, 10);
      expect(event.status, 'scheduled');
    });

    test('creates from JSON with defaults', () {
      final event = Event.fromJson({
        'id': 'e1',
        'party_id': 'p1',
        'start_time': now.toIso8601String(),
        'end_time': later.toIso8601String(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });

      expect(event.title, isNull);
      expect(event.imageUrls, isNull);
      expect(event.contactOptions, isEmpty);
      expect(event.minConfirmedCount, 0);
      expect(event.maxParticipants, 20);
      expect(event.currentParticipants, 0);
      expect(event.status, 'scheduled');
      expect(event.metadata, isEmpty);
    });

    test('serializes to JSON and back', () {
      final original = Event.fromJson(eventJson());
      final json = original.toJson();
      final restored = Event.fromJson(json);

      expect(restored, equals(original));
    });

    test('toDbJson removes id and timestamps', () {
      final event = Event.fromJson(eventJson());
      final dbJson = event.toDbJson();

      expect(dbJson.containsKey('id'), isFalse);
      expect(dbJson.containsKey('created_at'), isFalse);
      expect(dbJson.containsKey('updated_at'), isFalse);
      expect(dbJson.containsKey('party_id'), isTrue);
      expect(dbJson.containsKey('title'), isTrue);
    });

    test('effectiveImageUrls returns event images when present', () {
      final event = Event.fromJson(eventJson());
      expect(event.effectiveImageUrls, ['https://img.com/a.jpg']);
    });

    test('effectiveImageUrls falls back to party images', () {
      final party = Party.fromJson({
        'id': 'p1',
        'partner_id': 'pt1',
        'title': 'Test',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'image_urls': ['https://party.com/1.jpg'],
      });

      final event = Event.fromJson({
        'id': 'e1',
        'party_id': 'p1',
        'start_time': now.toIso8601String(),
        'end_time': later.toIso8601String(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      }).copyWith(party: party);

      expect(event.effectiveImageUrls, ['https://party.com/1.jpg']);
    });

    test('effectiveImageUrls returns empty when no images anywhere', () {
      final event = Event.fromJson({
        'id': 'e1',
        'party_id': 'p1',
        'start_time': now.toIso8601String(),
        'end_time': later.toIso8601String(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });

      expect(event.effectiveImageUrls, isEmpty);
    });

    test('imageUrl returns first image or null', () {
      final withImage = Event.fromJson(eventJson());
      expect(withImage.imageUrl, 'https://img.com/a.jpg');

      final noImage = Event.fromJson({
        'id': 'e1',
        'party_id': 'p1',
        'start_time': now.toIso8601String(),
        'end_time': later.toIso8601String(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
      expect(noImage.imageUrl, isNull);
    });

    test('createFromParty creates event from party template', () {
      final party = Party.fromJson({
        'id': 'party_1',
        'partner_id': 'pt_1',
        'title': 'Template Party',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'location_id': 'loc_1',
        'description': {
          'ops': [
            {'insert': 'Hello'},
          ],
        },
        'contact_options': {'phone': '010'},
        'min_confirmed_count': 5,
        'max_participants': 50,
      });

      final event = Event.createFromParty(
        party,
        startTime: now,
        endTime: later,
      );

      expect(event.id, '');
      expect(event.partyId, 'party_1');
      expect(event.startTime, now);
      expect(event.endTime, later);
      expect(event.locationId, 'loc_1');
      expect(event.title, 'Template Party');
      expect(event.contactOptions['phone'], '010');
      expect(event.minConfirmedCount, 5);
      expect(event.maxParticipants, 50);
      expect(event.metadata, isEmpty);
    });

    test('createFromParty copies metadata from party', () {
      final party = Party.fromJson({
        'id': 'party_1',
        'partner_id': 'pt_1',
        'title': 'Template Party',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'metadata': {'show_participant_list': false},
      });

      final event = Event.createFromParty(
        party,
        startTime: now,
        endTime: later,
      );

      expect(event.metadata['show_participant_list'], false);
    });

    test('createFromParty metadata is a deep copy', () {
      final party = Party.fromJson({
        'id': 'party_1',
        'partner_id': 'pt_1',
        'title': 'Template Party',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'metadata': {'key': 'original'},
      });

      final event = Event.createFromParty(
        party,
        startTime: now,
        endTime: later,
      );

      final mutableEventMetadata = Map<String, dynamic>.from(event.metadata);
      mutableEventMetadata['key'] = 'modified';
      expect(party.metadata['key'], 'original');
    });

    test('equality works', () {
      final e1 = Event.fromJson(eventJson());
      final e2 = Event.fromJson(eventJson());
      expect(e1, equals(e2));
    });

test('creates from JSON with visibility = null', () {
  final event = Event.fromJson({
    'id': 'e1',
    'party_id': 'p1',
    'start_time': now.toIso8601String(),
    'end_time': later.toIso8601String(),
    'created_at': now.toIso8601String(),
    'updated_at': later.toIso8601String(),
  });
  expect(event.visibility, isNull);
});

test('creates from JSON with visibility = private', () {
  final event = Event.fromJson({
    ...eventJson(),
    'visibility': 'private',
  });
  expect(event.visibility, 'private');
});

test('createFromParty does not set visibility (inherits null)', () {
  final party = Party.fromJson({
    'id': 'party_1',
    'partner_id': 'pt_1',
    'title': 'Template',
    'created_at': now.toIso8601String(),
    'updated_at': now.toIso8601String(),
    'visibility': 'private',
  });
  final event = Event.createFromParty(
    party,
    startTime: now,
    endTime: later,
  );
  expect(event.visibility, isNull);
});

test('effectiveVisibility returns own visibility when set', () {
  final event = Event.fromJson({
    ...eventJson(),
    'visibility': 'private',
  });
  expect(event.effectiveVisibility, 'private');
});

test('effectiveVisibility inherits from party when null', () {
  final party = Party.fromJson({
    'id': 'p1',
    'partner_id': 'pt1',
    'title': 'Test',
    'created_at': now.toIso8601String(),
    'updated_at': now.toIso8601String(),
    'visibility': 'private',
  });
  final event = Event.fromJson({
    'id': 'e1',
    'party_id': 'p1',
    'start_time': now.toIso8601String(),
    'end_time': later.toIso8601String(),
    'created_at': now.toIso8601String(),
    'updated_at': later.toIso8601String(),
  }).copyWith(party: party);
  expect(event.effectiveVisibility, 'private');
});

test('effectiveVisibility defaults to public when no party', () {
  final event = Event.fromJson({
    'id': 'e1',
    'party_id': 'p1',
    'start_time': now.toIso8601String(),
    'end_time': later.toIso8601String(),
    'created_at': now.toIso8601String(),
    'updated_at': later.toIso8601String(),
  });
  expect(event.effectiveVisibility, 'public');
});

test('isEffectivelyPrivate returns true when private', () {
  final event = Event.fromJson({
    ...eventJson(),
    'visibility': 'private',
  });
  expect(event.isEffectivelyPrivate, isTrue);
});

test('isEffectivelyPrivate returns false when public', () {
  final event = Event.fromJson(eventJson());
  expect(event.isEffectivelyPrivate, isFalse);
});
  });

  group('Event conditionSummaries', () {
    final now = DateTime(2026, 1, 15, 12);
    final later = DateTime(2026, 1, 15, 18);

    Event eventWithGroups(List<EntryGroup> groups) {
      return Event.fromJson({
        'id': 'e1',
        'party_id': 'p1',
        'start_time': now.toIso8601String(),
        'end_time': later.toIso8601String(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      }).copyWith(entryGroups: groups);
    }

    test('returns 조건 없음 when no groups', () {
      final event = eventWithGroups([]);
      expect(event.conditionSummaries, ['조건 없음']);
    });

    test('returns 조건 없음 with null groups', () {
      final event = Event.fromJson({
        'id': 'e1',
        'party_id': 'p1',
        'start_time': now.toIso8601String(),
        'end_time': later.toIso8601String(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
      expect(event.conditionSummaries, ['조건 없음']);
    });

    test('male gender only', () {
      final event = eventWithGroups([
        EntryGroup.fromJson({
          'id': 'g1',
          'event_id': 'e1',
          'gender': 'male',
        }),
      ]);
      expect(event.conditionSummaries, ['남성']);
    });

    test('female gender only', () {
      final event = eventWithGroups([
        EntryGroup.fromJson({
          'id': 'g1',
          'event_id': 'e1',
          'gender': 'female',
        }),
      ]);
      expect(event.conditionSummaries, ['여성']);
    });

    test('birth year range only', () {
      final event = eventWithGroups([
        EntryGroup.fromJson({
          'id': 'g1',
          'event_id': 'e1',
          'birth_year_min': 1990,
          'birth_year_max': 2000,
        }),
      ]);
      expect(event.conditionSummaries, ['1990~2000년생']);
    });

    test('birth year min only', () {
      final event = eventWithGroups([
        EntryGroup.fromJson({
          'id': 'g1',
          'event_id': 'e1',
          'birth_year_min': 1990,
        }),
      ]);
      expect(event.conditionSummaries, ['1990년생 이후']);
    });

    test('birth year max only', () {
      final event = eventWithGroups([
        EntryGroup.fromJson({
          'id': 'g1',
          'event_id': 'e1',
          'birth_year_max': 2000,
        }),
      ]);
      expect(event.conditionSummaries, ['2000년생 이전']);
    });

    test('gender + birth year range', () {
      final event = eventWithGroups([
        EntryGroup.fromJson({
          'id': 'g1',
          'event_id': 'e1',
          'gender': 'male',
          'birth_year_min': 1990,
          'birth_year_max': 2000,
        }),
      ]);
      expect(event.conditionSummaries, ['남성 (1990~2000년생)']);
    });

    test('with label on condition', () {
      final event = eventWithGroups([
        EntryGroup.fromJson({
          'id': 'g1',
          'event_id': 'e1',
          'label': 'Student',
          'gender': 'male',
        }),
      ]);
      expect(event.conditionSummaries, ['Student (남성)']);
    });

    test('label with no condition shows label only', () {
      final event = eventWithGroups([
        EntryGroup.fromJson({
          'id': 'g1',
          'event_id': 'e1',
          'label': 'General',
        }),
      ]);
      expect(event.conditionSummaries, ['General']);
    });

    test('with verification badges', () {
      final event = eventWithGroups([
        EntryGroup.fromJson({
          'id': 'g1',
          'event_id': 'e1',
          'gender': 'female',
          'required_verification_ids': ['v1', 'v2'],
        }),
      ]);
      expect(event.conditionSummaries.first, contains('+🛡️2'));
    });
  });
}
