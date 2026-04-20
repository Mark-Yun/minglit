import 'package:app_user/src/logic/eligibility_filter.dart';
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

    test(
      'filters out events when user birth year is below entry group minimum',
      () {
        // Fix #1634: age restriction — user born 1980 cannot enter group requiring birthYearMin 1990
        final events = [
          makeEvent(
            tickets: [
              makeTicket(targetEntryGroupIds: ['g1']),
            ],
            entryGroups: [
              const EntryGroup(
                id: 'g1',
                eventId: 'e1',
                gender: 'male',
                birthYearMin: 1990,
                birthYearMax: 2005,
              ),
            ],
          ),
        ];
        final data = BulkEligibilityData.fromJson({
          'user_profile': {
            'gender': 'male',
            'birth_year': 1980,
            'is_verified': true,
          },
          'approved_verifications': <dynamic>[],
        });

        final result = EligibilityFilter.filter(
          events: events,
          eligibilityData: data,
        );

        expect(result, isEmpty);
      },
    );

    test(
      'filters out events when user birth year exceeds entry group maximum',
      () {
        // Fix #1634: age restriction — user born 2010 cannot enter group with birthYearMax 2005
        final events = [
          makeEvent(
            tickets: [
              makeTicket(targetEntryGroupIds: ['g1']),
            ],
            entryGroups: [
              const EntryGroup(
                id: 'g1',
                eventId: 'e1',
                gender: 'male',
                birthYearMin: 1990,
                birthYearMax: 2005,
              ),
            ],
          ),
        ];
        final data = BulkEligibilityData.fromJson({
          'user_profile': {
            'gender': 'male',
            'birth_year': 2010,
            'is_verified': true,
          },
          'approved_verifications': <dynamic>[],
        });

        final result = EligibilityFilter.filter(
          events: events,
          eligibilityData: data,
        );

        expect(result, isEmpty);
      },
    );

    test('filters out events requiring verification when user lacks it', () {
      // Fix #1634: verification requirement — event requires career verification
      final events = [
        makeEvent(
          tickets: [
            makeTicket(requiredVerificationIds: ['verif_career']),
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

    test('keeps events requiring verification when user has it', () {
      // Fix #1634: verification — user with approved career verification is eligible
      final events = [
        makeEvent(
          tickets: [
            makeTicket(requiredVerificationIds: ['verif_career']),
          ],
        ),
      ];
      final data = BulkEligibilityData.fromJson({
        'user_profile': {
          'gender': 'male',
          'birth_year': 1995,
          'is_verified': true,
        },
        'approved_verifications': [
          {
            'partner_id': 'p1',
            'verification_id': 'verif_career',
            'verified_at': '2025-01-01',
          },
        ],
      });

      final result = EligibilityFilter.filter(
        events: events,
        eligibilityData: data,
      );

      expect(result, hasLength(1));
    });
  });

  // Fix #1634: Persona matrix — common dev seed personas against realistic event
  // types. Regression guard: eligibility filter must not silently exclude all events.
  group('persona matrix', () {
    final currentYear = DateTime.now().year;

    BulkEligibilityData makeProfile({
      required String gender,
      required int age,
      List<Map<String, dynamic>> verifications = const [],
    }) {
      return BulkEligibilityData.fromJson({
        'user_profile': {
          'gender': gender,
          'birth_year': currentYear - age,
          'is_verified': true,
        },
        'approved_verifications': verifications,
      });
    }

    // No tickets → always eligible regardless of profile.
    Event openEvent() => makeEvent(id: 'open');

    // Male-only, no age restriction.
    Event maleOnlyEvent() => makeEvent(
      id: 'male_only',
      tickets: [
        makeTicket(id: 'tm', targetEntryGroupIds: ['gm']),
      ],
      entryGroups: [
        const EntryGroup(id: 'gm', eventId: 'male_only', gender: 'male'),
      ],
    );

    // Male-only with age range 25–40. birthYearMin = currentYear-40, birthYearMax = currentYear-25.
    Event maleAgeRestrictedEvent() => makeEvent(
      id: 'age_restricted',
      tickets: [
        makeTicket(id: 'ta', targetEntryGroupIds: ['ga']),
      ],
      entryGroups: [
        EntryGroup(
          id: 'ga',
          eventId: 'age_restricted',
          gender: 'male',
          birthYearMin: currentYear - 40,
          birthYearMax: currentYear - 25,
        ),
      ],
    );

    // Requires career verification.
    Event verificationEvent() => makeEvent(
      id: 'verif',
      tickets: [
        makeTicket(id: 'tv', requiredVerificationIds: ['verif_career']),
      ],
    );

    test('18F — eligible only for open event', () {
      final profile = makeProfile(gender: 'female', age: 18);
      final events = [
        openEvent(),
        maleOnlyEvent(),
        maleAgeRestrictedEvent(),
        verificationEvent(),
      ];

      final result = EligibilityFilter.filter(
        events: events,
        eligibilityData: profile,
      );

      expect(result.map((e) => e.id).toList(), equals(['open']));
    });

    test(
      '25F — eligible for open event only (gender mismatch on male-only)',
      () {
        final profile = makeProfile(gender: 'female', age: 25);
        final events = [
          openEvent(),
          maleOnlyEvent(),
          maleAgeRestrictedEvent(),
          verificationEvent(),
        ];

        final result = EligibilityFilter.filter(
          events: events,
          eligibilityData: profile,
        );

        expect(result.map((e) => e.id).toList(), equals(['open']));
      },
    );

    test('35M — eligible for open, male-only, and age-restricted events', () {
      final profile = makeProfile(gender: 'male', age: 35);
      final events = [
        openEvent(),
        maleOnlyEvent(),
        maleAgeRestrictedEvent(),
        verificationEvent(),
      ];

      final result = EligibilityFilter.filter(
        events: events,
        eligibilityData: profile,
      );

      expect(
        result.map((e) => e.id),
        containsAll(['open', 'male_only', 'age_restricted']),
      );
      expect(result.any((e) => e.id == 'verif'), isFalse);
    });

    test(
      '42M — eligible for open and male-only events, not age-restricted (too old)',
      () {
        final profile = makeProfile(gender: 'male', age: 42);
        final events = [
          openEvent(),
          maleOnlyEvent(),
          maleAgeRestrictedEvent(),
          verificationEvent(),
        ];

        final result = EligibilityFilter.filter(
          events: events,
          eligibilityData: profile,
        );

        expect(result.map((e) => e.id), containsAll(['open', 'male_only']));
        expect(result.any((e) => e.id == 'age_restricted'), isFalse);
        expect(result.any((e) => e.id == 'verif'), isFalse);
      },
    );

    test(
      'all personas — eligible for open event (seed data regression guard)',
      () {
        // Fix #1634: this is the core regression — all verified users must see open events.
        final personas = [
          makeProfile(gender: 'female', age: 18),
          makeProfile(gender: 'female', age: 25),
          makeProfile(gender: 'male', age: 35),
          makeProfile(gender: 'male', age: 42),
        ];

        for (final profile in personas) {
          final result = EligibilityFilter.filter(
            events: [openEvent()],
            eligibilityData: profile,
          );
          expect(
            result,
            hasLength(1),
            reason: 'All personas should see open events',
          );
        }
      },
    );
  });
}
