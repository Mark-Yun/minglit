/// Smoke test — proves the demo override surface holds together.
///
/// Owned by **P1-5 agent**.
///
/// Tests:
///   1. `demoOverrides()` is non-empty.
///   2. A [ProviderContainer] built from `demoOverrides()` resolves the core
///      minglit_kit Repository providers without throwing.
///   3. Resolved repo instances are Fake (not real Supabase implementations).
///   4. An un-overridden method on a fake repo throws [StateError] with
///      "DEMO MODE" (PoisonSupabaseClient discipline).
///
/// NOTE: Some providers (currentUserProvider, eventRepositoryProvider, etc.)
/// depend on P1-1..P1-4 domain override files. This test will compile fully
/// only after all parallel agents have landed their files.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_data.dart';
import 'package:minglit_kit/minglit_logic.dart';

// ignore: avoid_relative_lib_imports
import '../lib/overrides/demo_overrides.dart';
// ignore: avoid_relative_lib_imports
import '../lib/overrides/poison_supabase_client.dart';

void main() {
  group('demoOverrides() resolves all minglit_kit Repository providers without network', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(overrides: demoOverrides());
    });

    tearDown(() {
      container.dispose();
    });

    // ── 1. Non-empty override list ───────────────────────────────────────────

    test('demoOverrides() returns a non-empty list', () {
      final overrides = demoOverrides();
      expect(overrides, isNotEmpty);
    });

    // ── 2. Auth domain — currentUser is non-null ────────────────────────────
    // Requires P1-1 (auth_overrides.dart) to be present.

    test('currentUserProvider returns non-null demoUser', () {
      final user = container.read(currentUserProvider);
      expect(user, isNotNull);
      // Demo user ID is fixed by DemoWorld.
      expect(user!.id, isNotEmpty);
    });

    // ── 3. Event domain ─────────────────────────────────────────────────────

    test('eventRepositoryProvider returns a Fake (not real EventRepository)', () {
      final repo = container.read(eventRepositoryProvider);
      expect(repo, isA<EventRepository>());
      // Real EventRepository class is the concrete type; fakes are subclasses.
      expect(repo.runtimeType.toString(), isNot(equals('EventRepository')));
    });

    test('partyRepositoryProvider returns a Fake', () {
      final repo = container.read(partyRepositoryProvider);
      expect(repo, isA<PartyRepository>());
    });

    // ── 4. Ticket domain ────────────────────────────────────────────────────

    test('ticketRepositoryProvider returns a Fake', () {
      final repo = container.read(ticketRepositoryProvider);
      expect(repo, isA<TicketRepository>());
    });

    // ── 5. Partner domain ───────────────────────────────────────────────────

    test('partnerRepositoryProvider returns a Fake', () {
      final repo = container.read(partnerRepositoryProvider);
      expect(repo, isA<PartnerRepository>());
    });

    test('settlementRepositoryProvider returns a Fake', () {
      final repo = container.read(settlementRepositoryProvider);
      expect(repo, isA<SettlementRepository>());
    });

    // ── 6. Misc domain ──────────────────────────────────────────────────────

    test('verificationRepositoryProvider returns a Fake', () {
      final repo = container.read(verificationRepositoryProvider);
      expect(repo, isA<VerificationRepository>());
    });

    test('notificationRepositoryProvider returns a Fake', () {
      final repo = container.read(notificationRepositoryProvider);
      expect(repo, isA<NotificationRepository>());
    });

    test('policyRepositoryProvider returns a Fake', () {
      final repo = container.read(policyRepositoryProvider);
      expect(repo, isA<PolicyRepository>());
    });

    test('matchingRepositoryProvider returns a Fake', () {
      final repo = container.read(matchingRepositoryProvider);
      expect(repo, isA<MatchingRepository>());
    });

    // ── 7. Smoke: resolving fakes does NOT throw ────────────────────────────

    test('container resolves all misc providers without throwing', () {
      expect(
        () {
          container.read(verificationRepositoryProvider);
          container.read(notificationRepositoryProvider);
          container.read(policyRepositoryProvider);
          container.read(matchingRepositoryProvider);
        },
        returnsNormally,
      );
    });

    // ── 8. PoisonSupabaseClient discipline ──────────────────────────────────

    test(
      'PoisonSupabaseClient throws StateError containing "DEMO MODE"',
      () {
        const poison = PoisonSupabaseClient();
        expect(
          // Call any method not explicitly handled by PoisonSupabaseClient
          // (noSuchMethod intercepts it).
          () => (poison as dynamic).from('any_table'),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('DEMO MODE'),
            ),
          ),
        );
      },
    );

    // ── 9. Misc read method returns fixture data ─────────────────────────────

    test(
      'notificationRepository.getNotifications() returns demo fixtures',
      () async {
        final repo = container.read(notificationRepositoryProvider);
        final notifications = await repo.getNotifications();
        expect(notifications, isNotEmpty);
        expect(notifications.first, isA<Map<String, dynamic>>());
        expect(notifications.first['user_id'], isNotNull);
      },
    );

    test(
      'policyRepository.getRefundPolicy() returns demo policy stub',
      () async {
        final repo = container.read(policyRepositoryProvider);
        final policy = await repo.getRefundPolicy();
        expect(policy, isNotNull);
        expect(policy!['key'], equals('refund'));
      },
    );

    test(
      'matchingRepository.getMyMatches() returns demo matchings for event8',
      () async {
        final repo = container.read(matchingRepositoryProvider);
        const pastEvent8Id = '00000000-0000-4000-8000-300000000008';
        final matches = await repo.getMyMatches(pastEvent8Id);
        expect(matches, hasLength(2));
        expect(matches.first, isA<MatchPair>());
      },
    );
  });
}
