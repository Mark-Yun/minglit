import 'package:app_user/src/features/explore/logic/eligibility_filter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  final now = DateTime.now();

  Event makeEvent({
    String id = 'e1',
    List<Ticket>? tickets,
    List<EntryGroup>? entryGroups,
  }) {
    return Event(
      id: id,
      partyId: 'p1',
      startTime: now.add(const Duration(days: 1)),
      endTime: now.add(const Duration(days: 1, hours: 2)),
      createdAt: now,
      updatedAt: now,
      tickets: tickets,
      entryGroups: entryGroups,
    );
  }

  Ticket makeTicket({
    String id = 't1',
    int price = 10000,
    List<String> targetEntryGroupIds = const [],
    List<String> requiredVerificationIds = const [],
  }) {
    return Ticket(
      id: id,
      name: 'Ticket $id',
      createdAt: now,
      updatedAt: now,
      price: price,
      targetEntryGroupIds: targetEntryGroupIds,
      requiredVerificationIds: requiredVerificationIds,
    );
  }

  group('BulkEligibilityData', () {
    test('parses from JSON with valid profile', () {
      final data = BulkEligibilityData.fromJson({
        'user_profile': {
          'gender': 'male',
          'birth_year': 1995,
          'is_verified': true,
        },
        'approved_verifications': [
          {
            'partner_id': 'p1',
            'verification_id': 'v1',
            'verified_at': '2025-01-01',
          },
          {
            'partner_id': 'p2',
            'verification_id': 'v2',
            'verified_at': '2025-02-01',
          },
        ],
      });

      expect(data.userProfile, isNotNull);
      expect(data.userProfile!.gender, 'male');
      expect(data.userProfile!.birthYear, 1995);
      expect(data.userProfile!.isVerified, true);
      expect(data.approvedVerificationIds, ['v1', 'v2']);
    });

    test('parses from JSON with null profile', () {
      final data = BulkEligibilityData.fromJson({
        'user_profile': null,
        'approved_verifications': <dynamic>[],
      });

      expect(data.userProfile, isNull);
      expect(data.approvedVerificationIds, isEmpty);
    });
  });

  group('EligibilityFilter', () {
    test('returns empty when user profile is null', () {
      final events = [
        makeEvent(tickets: [makeTicket()]),
      ];
      final data = BulkEligibilityData.fromJson({
        'user_profile': null,
        'approved_verifications': <dynamic>[],
      });

      final result = EligibilityFilter.filter(
        events: events,
        eligibilityData: data,
      );

      expect(result, isEmpty);
    });

    test('keeps events without tickets (open events)', () {
      final events = [makeEvent()];
      final data = BulkEligibilityData.fromJson({
        'user_profile': {
          'gender': 'male',
          'birth_year': 1995,
          'is_verified': true,
        },
        'approved_verifications': <dynamic>[],
      });

      final result = EligibilityFilter.filter(
        events: events,
        eligibilityData: data,
      );

      expect(result, hasLength(1));
    });

    test('keeps events with eligible tickets', () {
      final events = [
        makeEvent(tickets: [makeTicket()]),
      ];
      final data = BulkEligibilityData.fromJson({
        'user_profile': {
          'gender': 'male',
          'birth_year': 1995,
          'is_verified': true,
        },
        'approved_verifications': <dynamic>[],
      });

      final result = EligibilityFilter.filter(
        events: events,
        eligibilityData: data,
      );

      expect(result, hasLength(1));
    });

    test('filters out events where user is not verified', () {
      final events = [
        makeEvent(tickets: [makeTicket()]),
      ];
      final data = BulkEligibilityData.fromJson({
        'user_profile': {
          'gender': 'male',
          'birth_year': 1995,
          'is_verified': false,
        },
        'approved_verifications': <dynamic>[],
      });

      final result = EligibilityFilter.filter(
        events: events,
        eligibilityData: data,
      );

      expect(result, isEmpty);
    });

    test('filters out events with gender-restricted entry groups', () {
      final events = [
        makeEvent(
          tickets: [
            makeTicket(targetEntryGroupIds: ['g1']),
          ],
          entryGroups: [
            const EntryGroup(
              id: 'g1',
              eventId: 'e1',
              gender: 'female',
            ),
          ],
        ),
      ];
      final data = BulkEligibilityData.fromJson({
        'user_profile': {
          'gender': 'male',
          'birth_year': 1995,
          'is_verified': true,
        },
        'approved_verifications': <dynamic>[],
      });

      final result = EligibilityFilter.filter(
        events: events,
        eligibilityData: data,
      );

      expect(result, isEmpty);
    });

    test('filters multiple events correctly', () {
      final events = [
        // Eligible — no entry group restrictions
        makeEvent(
          id: 'eligible',
          tickets: [makeTicket()],
        ),
        // Not eligible — gender mismatch
        makeEvent(
          id: 'ineligible',
          tickets: [
            makeTicket(id: 't2', targetEntryGroupIds: ['g1']),
          ],
          entryGroups: [
            const EntryGroup(id: 'g1', eventId: 'ineligible', gender: 'female'),
          ],
        ),
        // Eligible — open event
        makeEvent(id: 'open'),
      ];
      final data = BulkEligibilityData.fromJson({
        'user_profile': {
          'gender': 'male',
          'birth_year': 1995,
          'is_verified': true,
        },
        'approved_verifications': <dynamic>[],
      });

      final result = EligibilityFilter.filter(
        events: events,
        eligibilityData: data,
      );

      expect(result, hasLength(2));
      expect(result.map((e) => e.id), containsAll(['eligible', 'open']));
    });

    test('respects balance status override', () {
      final events = [
        makeEvent(
          tickets: [makeTicket()],
        ),
      ];
      final data = BulkEligibilityData.fromJson({
        'user_profile': {
          'gender': 'male',
          'birth_year': 1995,
          'is_verified': true,
        },
        'approved_verifications': <dynamic>[],
      });

      final result = EligibilityFilter.filter(
        events: events,
        eligibilityData: data,
        balanceStatusByEvent: {
          'e1': {'t1': false},
        },
      );

      expect(result, isEmpty);
    });
  });
}
