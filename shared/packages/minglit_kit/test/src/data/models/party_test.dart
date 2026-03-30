import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/party.dart';

void main() {
  group('Location', () {
    final now = DateTime(2026, 1, 15, 12);

    Map<String, dynamic> locationJson() => {
      'id': 'loc_1',
      'partner_id': 'partner_1',
      'name': 'Test Venue',
      'address': '서울시 강남구',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'address_detail': '3층',
      'region_1': '서울특별시',
      'region_2': '강남구',
      'region_3': '역삼동',
      'directions_guide': '2번 출구에서 직진',
      'postal_code': '06241',
      'lat': 37.5,
      'lng': 127.0,
    };

    test('creates from JSON with all fields', () {
      final loc = Location.fromJson(locationJson());

      expect(loc.id, 'loc_1');
      expect(loc.partnerId, 'partner_1');
      expect(loc.name, 'Test Venue');
      expect(loc.address, '서울시 강남구');
      expect(loc.addressDetail, '3층');
      expect(loc.region1, '서울특별시');
      expect(loc.region2, '강남구');
      expect(loc.region3, '역삼동');
      expect(loc.directionsGuide, '2번 출구에서 직진');
      expect(loc.postalCode, '06241');
      expect(loc.latitude, 37.5);
      expect(loc.longitude, 127.0);
    });

    test('creates from JSON with minimal fields', () {
      final loc = Location.fromJson({
        'id': 'loc_1',
        'partner_id': 'p1',
        'name': 'Venue',
        'address': 'Addr',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });

      expect(loc.id, 'loc_1');
      expect(loc.addressDetail, isNull);
      expect(loc.region1, isNull);
      expect(loc.latitude, 0.0);
      expect(loc.longitude, 0.0);
    });

    test('serializes to JSON and back', () {
      final original = Location.fromJson(locationJson());
      final json = original.toJson();
      final restored = Location.fromJson(json);

      expect(restored, equals(original));
    });

    test('toDbJson removes id and timestamps', () {
      final loc = Location.fromJson(locationJson());
      final dbJson = loc.toDbJson();

      expect(dbJson.containsKey('id'), isFalse);
      expect(dbJson.containsKey('created_at'), isFalse);
      expect(dbJson.containsKey('updated_at'), isFalse);
      expect(dbJson.containsKey('partner_id'), isTrue);
      expect(dbJson.containsKey('name'), isTrue);
    });

    test('copyWith creates modified copy', () {
      final loc = Location.fromJson(locationJson());
      final modified = loc.copyWith(name: 'New Name');

      expect(modified.name, 'New Name');
      expect(modified.id, 'loc_1');
    });

    test('equality works with same values', () {
      final loc1 = Location.fromJson(locationJson());
      final loc2 = Location.fromJson(locationJson());

      expect(loc1, equals(loc2));
    });
  });

  group('Party', () {
    final now = DateTime(2026, 1, 15, 12);

    Map<String, dynamic> partyJson() => {
      'id': 'party_1',
      'partner_id': 'partner_1',
      'title': 'Friday Mingle',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'description': {'ops': <Map<String, dynamic>>[]},
      'image_urls': ['https://img.com/1.jpg', 'https://img.com/2.jpg'],
      'contact_options': {'kakao': 'minglit'},
      'required_verification_ids': ['v1', 'v2'],
      'min_confirmed_count': 5,
      'max_participants': 30,
      'status': 'active',
      'metadata': <String, dynamic>{},
    };

    test('creates from JSON with all fields', () {
      final party = Party.fromJson(partyJson());

      expect(party.id, 'party_1');
      expect(party.partnerId, 'partner_1');
      expect(party.title, 'Friday Mingle');
      expect(party.imageUrls, hasLength(2));
      expect(party.contactOptions['kakao'], 'minglit');
      expect(party.requiredVerificationIds, ['v1', 'v2']);
      expect(party.minConfirmedCount, 5);
      expect(party.maxParticipants, 30);
      expect(party.status, 'active');
    });

    test('creates from JSON with defaults', () {
      final party = Party.fromJson({
        'id': 'p1',
        'partner_id': 'pt1',
        'title': 'Test',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });

      expect(party.imageUrls, isEmpty);
      expect(party.contactOptions, isEmpty);
      expect(party.requiredVerificationIds, isEmpty);
      expect(party.minConfirmedCount, 0);
      expect(party.maxParticipants, 20);
      expect(party.status, 'active');
      expect(party.locationId, isNull);
      expect(party.description, isNull);
      expect(party.metadata, isEmpty);
    });

    test('serializes to JSON and back', () {
      final original = Party.fromJson(partyJson());
      final json = original.toJson();
      final restored = Party.fromJson(json);

      expect(restored, equals(original));
    });

    test('toDbJson removes id and timestamps', () {
      final party = Party.fromJson(partyJson());
      final dbJson = party.toDbJson();

      expect(dbJson.containsKey('id'), isFalse);
      expect(dbJson.containsKey('created_at'), isFalse);
      expect(dbJson.containsKey('updated_at'), isFalse);
      expect(dbJson.containsKey('partner_id'), isTrue);
      expect(dbJson.containsKey('metadata'), isTrue);
    });

    test('imageUrl returns first URL or null', () {
      final party = Party.fromJson(partyJson());
      expect(party.imageUrl, 'https://img.com/1.jpg');

      final emptyParty = Party.fromJson({
        'id': 'p1',
        'partner_id': 'pt1',
        'title': 'Test',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
      expect(emptyParty.imageUrl, isNull);
    });

    test('statusLabel returns localized labels', () {
      final active = Party.fromJson({
        ...partyJson(),
        'status': 'active',
      });
      expect(active.statusLabel, '운영중');

      final closed = Party.fromJson({
        ...partyJson(),
        'status': 'closed',
      });
      expect(closed.statusLabel, '종료됨');

      final draft = Party.fromJson({
        ...partyJson(),
        'status': 'draft',
      });
      expect(draft.statusLabel, '임시저장');

      final unknown = Party.fromJson({
        ...partyJson(),
        'status': 'archived',
      });
      expect(unknown.statusLabel, '알 수 없음');
    });

    test('isActive / isClosed / isDraft', () {
      final active = Party.fromJson({...partyJson(), 'status': 'active'});
      expect(active.isActive, isTrue);
      expect(active.isClosed, isFalse);
      expect(active.isDraft, isFalse);

      final closed = Party.fromJson({...partyJson(), 'status': 'closed'});
      expect(closed.isActive, isFalse);
      expect(closed.isClosed, isTrue);

      final draft = Party.fromJson({...partyJson(), 'status': 'draft'});
      expect(draft.isDraft, isTrue);
    });

    test('conditionSummaries with no groups', () {
      final party = Party.fromJson(partyJson());
      expect(party.conditionSummaries, ['조건 없음']);
    });

    test('creates from JSON with visibility = private', () {
      final party = Party.fromJson({...partyJson(), 'visibility': 'private'});
      expect(party.visibility, 'private');
    });

    test('creates from JSON without visibility defaults to public', () {
      final party = Party.fromJson({
        'id': 'p1',
        'partner_id': 'pt1',
        'title': 'Test',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
      expect(party.visibility, 'public');
    });

    test('isPrivate returns true for private visibility', () {
      final party = Party.fromJson({...partyJson(), 'visibility': 'private'});
      expect(party.isPrivate, isTrue);
      expect(party.isPublic, isFalse);
    });

    test('isPublic returns true for public visibility', () {
      final party = Party.fromJson(partyJson());
      expect(party.isPublic, isTrue);
      expect(party.isPrivate, isFalse);
    });

    test('toDbJson includes visibility', () {
      final party = Party.fromJson({...partyJson(), 'visibility': 'private'});
      final dbJson = party.toDbJson();
      expect(dbJson['visibility'], 'private');
    });
  });
}
