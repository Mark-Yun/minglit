import 'package:app_partner/src/features/home/partner_dashboard_controller.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../utils/mocks.dart';
import '../../../utils/test_utils.dart';

final _testEvent = Event(
  id: 'event-1',
  partyId: 'party-1',
  startTime: DateTime(2026, 6),
  endTime: DateTime(2026, 6, 1, 23),
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

final _testParty = Party(
  id: 'party-1',
  partnerId: 'partner-1',
  title: 'Test Party',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

const _testPartner = Partner(
  id: 'partner-1',
  name: 'Test Partner',
  contactEmail: 'test@partner.com',
);

void main() {
  late MockEventRepository mockEventRepo;
  late MockPartyRepository mockPartyRepo;

  setUp(() {
    mockEventRepo = MockEventRepository();
    mockPartyRepo = MockPartyRepository();

    when(
      () => mockEventRepo.getPendingApplicationCount(any()),
    ).thenAnswer((_) async => 3);
    when(
      () => mockEventRepo.getUpcomingEvents(any()),
    ).thenAnswer((_) async => [_testEvent]);
    when(
      () => mockEventRepo.getClosingSoonEvents(any()),
    ).thenAnswer((_) async => []);
    when(
      () => mockEventRepo.getHasAnyEvents(any()),
    ).thenAnswer((_) async => true);
    when(
      () => mockPartyRepo.getPartiesByPartnerId(any()),
    ).thenAnswer((_) async => [_testParty]);
  });

  /// Creates container, subscribes to the dashboard provider, and pumps
  /// the event loop so [loadDashboardData] completes.
  Future<ProviderContainer> buildAndPump({
    Partner? partner = _testPartner,
  }) async {
    final container = createContainer(
      overrides: [
        currentPartnerInfoProvider.overrideWith((_) async => partner),
        eventRepositoryProvider.overrideWithValue(mockEventRepo),
        partyRepositoryProvider.overrideWithValue(mockPartyRepo),
      ],
    );

    // A listener is required for Riverpod to push state updates.
    final sub = container.listen(
      partnerDashboardControllerProvider,
      (_, _) {},
    );
    addTearDown(sub.close);

    // Resolve the partner future so loadDashboardData can proceed.
    if (partner != null) {
      await container.read(currentPartnerInfoProvider.future);
    }
    // Let async repo calls complete.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return container;
  }

  group('PartnerDashboardController', () {
    test('initial state has loading status before data loads', () async {
      final container = createContainer(
        overrides: [
          currentPartnerInfoProvider.overrideWith((_) async => _testPartner),
          eventRepositoryProvider.overrideWithValue(mockEventRepo),
          partyRepositoryProvider.overrideWithValue(mockPartyRepo),
        ],
      );

      // Read synchronously — loadDashboardData hasn't completed yet.
      final state = container.read(partnerDashboardControllerProvider);
      expect(state.status, isA<AsyncLoading<void>>());

      // Subscribe and pump to let the background microtask complete cleanly
      // before the container is disposed by addTearDown.
      final sub = container.listen(
        partnerDashboardControllerProvider,
        (_, _) {},
      );
      addTearDown(sub.close);
      await container.read(currentPartnerInfoProvider.future);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });

    test('loadDashboardData populates state with repo data', () async {
      final container = await buildAndPump();

      final state = container.read(partnerDashboardControllerProvider);
      expect(state.status, isA<AsyncData<void>>());
      expect(state.pendingReviewCount, 3);
      expect(state.upcomingEvents, contains(_testEvent));
      expect(state.activeParties, contains(_testParty));
      expect(state.hasAnyEvents, isTrue);
    });

    // Regression test for #1215: partner with past events (no upcoming events)
    // must not see the onboarding guide.
    test(
      'hasAnyEvents is true even when upcomingEvents is empty',
      () async {
        // Simulate partner whose events are all in the past (>7 days ago).
        when(
          () => mockEventRepo.getUpcomingEvents(any()),
        ).thenAnswer((_) async => []);
        when(
          () => mockEventRepo.getHasAnyEvents(any()),
        ).thenAnswer((_) async => true);

        final container = await buildAndPump();
        final state = container.read(partnerDashboardControllerProvider);

        expect(state.upcomingEvents, isEmpty);
        expect(
          state.hasAnyEvents,
          isTrue,
          reason:
              'Partner with past events should not see onboarding (#1215)',
        );
      },
    );

    test(
      'hasAnyEvents is false for brand-new partner with no events',
      () async {
        when(
          () => mockEventRepo.getUpcomingEvents(any()),
        ).thenAnswer((_) async => []);
        when(
          () => mockEventRepo.getHasAnyEvents(any()),
        ).thenAnswer((_) async => false);

        final container = await buildAndPump();
        final state = container.read(partnerDashboardControllerProvider);

        expect(state.upcomingEvents, isEmpty);
        expect(state.hasAnyEvents, isFalse);
      },
    );

    test('loadDashboardData sets empty state when partner is null', () async {
      final container = createContainer(
        overrides: [
          currentPartnerInfoProvider.overrideWith((_) async => null),
          eventRepositoryProvider.overrideWithValue(mockEventRepo),
          partyRepositoryProvider.overrideWithValue(mockPartyRepo),
        ],
      );
      final sub = container.listen(
        partnerDashboardControllerProvider,
        (_, _) {},
      );
      addTearDown(sub.close);
      // Partner is null — the microtask still runs and checks the null branch.
      await container.read(currentPartnerInfoProvider.future);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(partnerDashboardControllerProvider);
      expect(state.status, isA<AsyncData<void>>());
      expect(state.pendingReviewCount, 0);
      expect(state.upcomingEvents, isEmpty);
      expect(state.activeParties, isEmpty);
      expect(state.hasAnyEvents, isFalse);
    });

    test('loadDashboardData sets error state on exception', () async {
      when(
        () => mockEventRepo.getPendingApplicationCount(any()),
      ).thenThrow(Exception('network error'));

      final container = await buildAndPump();

      final state = container.read(partnerDashboardControllerProvider);
      expect(state.status, isA<AsyncError<void>>());
    });

    test('manual loadDashboardData refreshes pendingReviewCount', () async {
      final container = await buildAndPump();

      when(
        () => mockEventRepo.getPendingApplicationCount(any()),
      ).thenAnswer((_) async => 7);

      await container
          .read(partnerDashboardControllerProvider.notifier)
          .loadDashboardData();

      expect(
        container.read(partnerDashboardControllerProvider).pendingReviewCount,
        7,
      );
    });
  });
}
