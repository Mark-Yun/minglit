import 'package:app_user/src/features/event/admission/event_admission_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  final baseEvent = Event(
    id: 'event_1',
    partyId: 'party_1',
    startTime: DateTime.now(),
    endTime: DateTime.now().add(const Duration(hours: 2)),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    contactOptions: {},
    tickets: [
      Ticket(
        id: 'ticket_m',
        eventId: 'event_1',
        name: 'Male Ticket',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        targetEntryGroupIds: ['group_m'],
        requiredVerificationIds: [],
        price: 30000,
      ),
      Ticket(
        id: 'ticket_f',
        eventId: 'event_1',
        name: 'Female Ticket',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        targetEntryGroupIds: ['group_f'],
        requiredVerificationIds: [],
        price: 20000,
      ),
    ],
    entryGroups: [
      const EntryGroup(
        id: 'group_m',
        eventId: 'event_1',
        gender: 'male',
        birthYearMin: 1990,
        birthYearMax: 2005,
      ),
      const EntryGroup(
        id: 'group_f',
        eventId: 'event_1',
        gender: 'female',
        birthYearMin: 1990,
        birthYearMax: 2005,
      ),
    ],
  );

  final verifiedMaleProfile = UserProfile(
    id: 'user_1',
    name: 'Test User',
    username: 'test',
    isVerified: true,
    gender: 'male',
    birthDate: DateTime(1995),
  );

  final verifiedFemaleProfile = UserProfile(
    id: 'user_2',
    name: 'Test User F',
    username: 'testf',
    isVerified: true,
    gender: 'female',
    birthDate: DateTime(1995),
  );

  group('TicketRecommendationUtil', () {
    test('recommends cheapest eligible ticket for male user', () {
      final result = TicketRecommendationUtil.recommend(
        event: baseEvent,
        userProfile: verifiedMaleProfile,
        approvedVerificationIds: [],
        balanceStatus: {'ticket_m': true, 'ticket_f': true},
      );

      expect(result.recommendedTicket, isNotNull);
      expect(result.recommendedTicket!.id, 'ticket_m');
      expect(result.eligibleTickets, hasLength(1));
    });

    test('recommends cheaper female ticket for female user', () {
      final result = TicketRecommendationUtil.recommend(
        event: baseEvent,
        userProfile: verifiedFemaleProfile,
        approvedVerificationIds: [],
        balanceStatus: {'ticket_m': true, 'ticket_f': true},
      );

      expect(result.recommendedTicket, isNotNull);
      expect(result.recommendedTicket!.id, 'ticket_f');
      expect(result.recommendedTicket!.price, 20000);
    });

    test('returns null when no tickets exist', () {
      final noTicketEvent = baseEvent.copyWith(tickets: []);
      final result = TicketRecommendationUtil.recommend(
        event: noTicketEvent,
        userProfile: verifiedMaleProfile,
        approvedVerificationIds: [],
        balanceStatus: {},
      );

      expect(result.recommendedTicket, isNull);
      expect(result.eligibleTickets, isEmpty);
    });

    test('marks ticket ineligible when balance status is false', () {
      final result = TicketRecommendationUtil.recommend(
        event: baseEvent,
        userProfile: verifiedMaleProfile,
        approvedVerificationIds: [],
        balanceStatus: {'ticket_m': false, 'ticket_f': true},
      );

      expect(result.recommendedTicket, isNull);
      expect(result.ineligibleReasons['ticket_m'], '성비 조절 중');
    });

    test('marks ticket ineligible when gender mismatches', () {
      final result = TicketRecommendationUtil.recommend(
        event: baseEvent,
        userProfile: verifiedMaleProfile,
        approvedVerificationIds: [],
        balanceStatus: {'ticket_m': true, 'ticket_f': true},
      );

      // Male user can't access female ticket
      expect(result.ineligibleReasons['ticket_f'], contains('성별'));
    });

    test('marks ineligible when user profile is null', () {
      final result = TicketRecommendationUtil.recommend(
        event: baseEvent,
        userProfile: null,
        approvedVerificationIds: [],
        balanceStatus: {'ticket_m': true, 'ticket_f': true},
      );

      expect(result.recommendedTicket, isNull);
      expect(result.ineligibleReasons, isNotEmpty);
    });

    test('marks ineligible when user is not verified', () {
      const unverifiedProfile = UserProfile(
        id: 'user_1',
        name: 'Test User',
        username: 'test',
        gender: 'male',
      );
      final result = TicketRecommendationUtil.recommend(
        event: baseEvent,
        userProfile: unverifiedProfile,
        approvedVerificationIds: [],
        balanceStatus: {'ticket_m': true, 'ticket_f': true},
      );

      expect(result.recommendedTicket, isNull);
      expect(result.ineligibleReasons.values.first, contains('본인 인증'));
    });

    test('marks ineligible when birth year is out of range', () {
      final tooOld = UserProfile(
        id: 'user_1',
        name: 'Old User',
        username: 'old',
        isVerified: true,
        gender: 'male',
        birthDate: DateTime(1980), // too old (min 1990)
      );

      final result = TicketRecommendationUtil.recommend(
        event: baseEvent,
        userProfile: tooOld,
        approvedVerificationIds: [],
        balanceStatus: {'ticket_m': true, 'ticket_f': true},
      );

      expect(result.recommendedTicket, isNull);
      expect(result.ineligibleReasons['ticket_m'], contains('1990'));
    });

    test('handles required verification IDs', () {
      final eventWithVerif = baseEvent.copyWith(
        tickets: [
          Ticket(
            id: 'ticket_v',
            eventId: 'event_1',
            name: 'Verified Ticket',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            targetEntryGroupIds: [],
            requiredVerificationIds: ['verif_career'],
            price: 10000,
          ),
        ],
        entryGroups: [],
      );

      // Without verification
      final withoutVerif = TicketRecommendationUtil.recommend(
        event: eventWithVerif,
        userProfile: verifiedMaleProfile,
        approvedVerificationIds: [],
        balanceStatus: {'ticket_v': true},
      );
      expect(withoutVerif.recommendedTicket, isNull);
      expect(withoutVerif.ineligibleReasons['ticket_v'], contains('인증'));

      // With verification
      final withVerif = TicketRecommendationUtil.recommend(
        event: eventWithVerif,
        userProfile: verifiedMaleProfile,
        approvedVerificationIds: ['verif_career'],
        balanceStatus: {'ticket_v': true},
      );
      expect(withVerif.recommendedTicket, isNotNull);
      expect(withVerif.recommendedTicket!.id, 'ticket_v');
    });

    test('sorts eligible tickets by price ascending', () {
      final multiTicketEvent = baseEvent.copyWith(
        tickets: [
          Ticket(
            id: 'ticket_expensive',
            eventId: 'event_1',
            name: 'Expensive',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            targetEntryGroupIds: [],
            requiredVerificationIds: [],
            price: 50000,
          ),
          Ticket(
            id: 'ticket_cheap',
            eventId: 'event_1',
            name: 'Cheap',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            targetEntryGroupIds: [],
            requiredVerificationIds: [],
            price: 10000,
          ),
        ],
        entryGroups: [],
      );

      final result = TicketRecommendationUtil.recommend(
        event: multiTicketEvent,
        userProfile: verifiedMaleProfile,
        approvedVerificationIds: [],
        balanceStatus: {'ticket_expensive': true, 'ticket_cheap': true},
      );

      expect(result.eligibleTickets, hasLength(2));
      expect(result.eligibleTickets.first.price, 10000);
      expect(result.recommendedTicket!.id, 'ticket_cheap');
    });
  });
}
