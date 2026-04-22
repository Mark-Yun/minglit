import 'package:app_partner/src/logic/onboarding_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../utils/mocks.dart';
import '../../../utils/test_utils.dart';

User _makeUser() {
  return User(
    id: 'user-1',
    appMetadata: const {
      'provider': 'email',
      'providers': ['email'],
    },
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: DateTime(2026).toIso8601String(),
    identities: const [],
  );
}

void main() {
  group('OnboardingState', () {
    test('has exactly 6 enum values', () {
      expect(OnboardingState.values.length, 6);
    });

    test('hasPartner is a valid enum value', () {
      expect(OnboardingState.hasPartner, isA<OnboardingState>());
    });

    test('needsApplication is a valid enum value', () {
      expect(OnboardingState.needsApplication, isA<OnboardingState>());
    });

    test('all 6 expected values exist', () {
      expect(
        OnboardingState.values,
        containsAll([
          OnboardingState.loading,
          OnboardingState.needsApplication,
          OnboardingState.draftInProgress,
          OnboardingState.pendingReview,
          OnboardingState.needsCorrection,
          OnboardingState.hasPartner,
        ]),
      );
    });

    test('enum values have correct names', () {
      expect(OnboardingState.loading.name, 'loading');
      expect(OnboardingState.needsApplication.name, 'needsApplication');
      expect(OnboardingState.draftInProgress.name, 'draftInProgress');
      expect(OnboardingState.pendingReview.name, 'pendingReview');
      expect(OnboardingState.needsCorrection.name, 'needsCorrection');
      expect(OnboardingState.hasPartner.name, 'hasPartner');
    });
  });

  group('onboardingStateProvider (#1679)', () {
    late MockPartnerRepository mockPartnerRepo;
    final testUser = _makeUser();

    const approvedApplication = PartnerApplication(
      id: 'app-1',
      userId: 'user-1',
      status: 'approved',
    );

    const pendingApplication = PartnerApplication(
      id: 'app-1',
      userId: 'user-1',
      status: 'pending',
    );

    ProviderContainer buildContainer() {
      return createContainer(
        overrides: [
          currentUserProvider.overrideWith((_) => testUser),
          partnerRepositoryProvider.overrideWithValue(mockPartnerRepo),
        ],
      );
    }

    setUp(() {
      mockPartnerRepo = MockPartnerRepository();
    });

    // Regression #1679: application status='approved' with no partner record
    // previously returned hasPartner, sending the user to home with no partner
    // data. getMyManagedPartners already checks for approved applications via
    // fallback — reaching this branch means the partner record was never
    // created. Must stay on /apply/status (pendingReview), not home.
    test(
      'returns pendingReview when application is approved but no partner exists',
      () async {
        when(
          () => mockPartnerRepo.getMyManagedPartners(),
        ).thenAnswer((_) async => []);
        when(
          () => mockPartnerRepo.getMyApplication(),
        ).thenAnswer((_) async => approvedApplication);

        final container = buildContainer();
        final state = await container.read(onboardingStateProvider.future);

        expect(state, OnboardingState.pendingReview);
      },
    );

    test('returns hasPartner when managed partners exist', () async {
      const fakePartner = Partner(id: 'partner-1', name: '테스트 파트너');
      when(
        () => mockPartnerRepo.getMyManagedPartners(),
      ).thenAnswer((_) async => [fakePartner]);

      final container = buildContainer();
      final state = await container.read(onboardingStateProvider.future);

      expect(state, OnboardingState.hasPartner);
      verifyNever(() => mockPartnerRepo.getMyApplication());
    });

    test('returns pendingReview when application status is pending', () async {
      when(
        () => mockPartnerRepo.getMyManagedPartners(),
      ).thenAnswer((_) async => []);
      when(
        () => mockPartnerRepo.getMyApplication(),
      ).thenAnswer((_) async => pendingApplication);

      final container = buildContainer();
      final state = await container.read(onboardingStateProvider.future);

      expect(state, OnboardingState.pendingReview);
    });

    test('returns needsApplication when no application exists', () async {
      when(
        () => mockPartnerRepo.getMyManagedPartners(),
      ).thenAnswer((_) async => []);
      when(
        () => mockPartnerRepo.getMyApplication(),
      ).thenAnswer((_) async => null);

      final container = buildContainer();
      final state = await container.read(onboardingStateProvider.future);

      expect(state, OnboardingState.needsApplication);
    });
  });
}
