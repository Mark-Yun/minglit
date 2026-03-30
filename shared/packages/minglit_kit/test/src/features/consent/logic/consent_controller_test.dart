import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/user_consent.dart';
import 'package:minglit_kit/src/data/repositories/auth_repository.dart';
import 'package:minglit_kit/src/data/repositories/consent_repository.dart';
import 'package:minglit_kit/src/features/consent/logic/consent_controller.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../helpers/test_utils.dart';

class MockConsentRepository extends Mock implements ConsentRepository {}

class MockUser extends Mock implements User {}

void main() {
  late MockConsentRepository mockRepo;
  late MockUser mockUser;

  final now = DateTime(2026, 3, 30);

  final testConsents = [
    UserConsent(
      id: 'c1',
      userId: 'user_1',
      consentKey: ConsentType.termsOfService,
      consented: true,
      policyVersion: 1,
      consentedAt: now,
      createdAt: now,
    ),
    UserConsent(
      id: 'c2',
      userId: 'user_1',
      consentKey: ConsentType.privacyCollection,
      consented: true,
      policyVersion: 1,
      consentedAt: now,
      createdAt: now,
    ),
    UserConsent(
      id: 'c3',
      userId: 'user_1',
      consentKey: ConsentType.ageConfirmation,
      consented: true,
      consentedAt: now,
      createdAt: now,
    ),
  ];

  setUp(() {
    mockRepo = MockConsentRepository();
    mockUser = MockUser();
    when(() => mockUser.id).thenReturn('user_1');
  });

  ProviderContainer createTestContainer({User? user}) {
    return createContainer(
      overrides: [
        consentRepositoryProvider.overrideWithValue(mockRepo),
        currentUserProvider.overrideWithValue(user),
      ],
    );
  }

  group('ConsentController', () {
    test('returns empty list when user is not logged in', () async {
      final container = createTestContainer();

      final result = await container.read(consentControllerProvider.future);

      expect(result, isEmpty);
    });

    test('loads consents from repository', () async {
      when(
        () => mockRepo.getConsents('user_1'),
      ).thenAnswer((_) async => testConsents);

      final container = createTestContainer(user: mockUser);

      final result = await container.read(consentControllerProvider.future);

      expect(result, hasLength(3));
      expect(result.first.consentKey, ConsentType.termsOfService);
    });

    test('saveSignupConsents calls repository and reloads', () async {
      when(
        () => mockRepo.getConsents('user_1'),
      ).thenAnswer((_) async => testConsents);
      when(
        () => mockRepo.saveConsents('user_1', any()),
      ).thenAnswer((_) async {});

      final container = createTestContainer(user: mockUser);

      // Wait for initial build
      await container.read(consentControllerProvider.future);

      // Save signup consents
      await container
          .read(consentControllerProvider.notifier)
          .saveSignupConsents(ConsentType.requiredTypes, policyVersion: 1);

      verify(() => mockRepo.saveConsents('user_1', any())).called(1);

      // Verify reload was called (getConsents called during build + reload)
      verify(() => mockRepo.getConsents('user_1')).called(2);
    });

    test(
      'saveSignupConsents invalidates hasRequiredConsents cache after success',
      () async {
        when(
          () => mockRepo.getConsents('user_1'),
        ).thenAnswer((_) async => testConsents);
        when(
          () => mockRepo.saveConsents('user_1', any()),
        ).thenAnswer((_) async {});

        var hasRequiredConsents = false;
        when(
          () => mockRepo.hasRequiredConsents(),
        ).thenAnswer((_) async => hasRequiredConsents);

        final container = createTestContainer(user: mockUser);

        final beforeSave = await container.read(
          hasRequiredConsentsProvider.future,
        );

        expect(beforeSave, false);

        hasRequiredConsents = true;

        await container
            .read(consentControllerProvider.notifier)
            .saveSignupConsents(ConsentType.requiredTypes, policyVersion: 1);

        final afterSave = await container.read(
          hasRequiredConsentsProvider.future,
        );

        expect(afterSave, true);
        verify(() => mockRepo.hasRequiredConsents()).called(2);
      },
    );

    test(
      'saveSignupConsents invalidates guard cache even when reload fails',
      () async {
        // First build succeeds
        when(
          () => mockRepo.getConsents('user_1'),
        ).thenAnswer((_) async => testConsents);

        var hasRequiredConsents = false;
        when(
          () => mockRepo.hasRequiredConsents(),
        ).thenAnswer((_) async => hasRequiredConsents);

        final container = createTestContainer(user: mockUser);
        await container.read(consentControllerProvider.future);

        // Pre-cache hasRequiredConsents as false
        final before = await container.read(
          hasRequiredConsentsProvider.future,
        );
        expect(before, false);

        // saveConsents succeeds, but getConsents (reload) fails
        when(
          () => mockRepo.saveConsents('user_1', any()),
        ).thenAnswer((_) async {});
        when(
          () => mockRepo.getConsents('user_1'),
        ).thenThrow(Exception('network error'));

        hasRequiredConsents = true;

        await container
            .read(consentControllerProvider.notifier)
            .saveSignupConsents(ConsentType.requiredTypes, policyVersion: 1);

        // Controller state should be error (reload failed)
        expect(
          container.read(consentControllerProvider),
          isA<AsyncError<List<UserConsent>>>(),
        );

        // But hasRequiredConsentsProvider was invalidated before the
        // reload, so it should re-fetch and return true.
        final after = await container.read(
          hasRequiredConsentsProvider.future,
        );
        expect(after, true);
      },
    );

    test('toggleConsent calls repository and reloads', () async {
      when(
        () => mockRepo.getConsents('user_1'),
      ).thenAnswer((_) async => testConsents);
      when(
        () => mockRepo.saveConsents('user_1', any()),
      ).thenAnswer((_) async {});

      final container = createTestContainer(user: mockUser);

      await container.read(consentControllerProvider.future);

      await container
          .read(consentControllerProvider.notifier)
          .toggleConsent(ConsentType.marketingConsent, consented: true);

      final captured = verify(
        () => mockRepo.saveConsents('user_1', captureAny()),
      ).captured;

      final inputs = captured.first as List<ConsentInput>;
      expect(inputs, hasLength(1));
      expect(inputs.first.consentKey, ConsentType.marketingConsent);
      expect(inputs.first.consented, true);
    });

    test('toggleConsent reverts on error', () async {
      when(
        () => mockRepo.getConsents('user_1'),
      ).thenAnswer((_) async => testConsents);
      when(
        () => mockRepo.saveConsents('user_1', any()),
      ).thenThrow(Exception('Save failed'));

      final container = createTestContainer(user: mockUser);

      await container.read(consentControllerProvider.future);

      await container
          .read(consentControllerProvider.notifier)
          .toggleConsent(ConsentType.marketingConsent, consented: true);

      final state = container.read(consentControllerProvider);
      expect(state, isA<AsyncError<List<UserConsent>>>());
    });

    test('does nothing when user is null', () async {
      final container = createTestContainer();

      await container.read(consentControllerProvider.future);

      await container
          .read(consentControllerProvider.notifier)
          .saveSignupConsents(ConsentType.requiredTypes);

      verifyNever(() => mockRepo.saveConsents(any(), any()));
    });
  });

  group('hasRequiredConsents', () {
    test('returns true when all required consents exist', () async {
      when(() => mockRepo.hasRequiredConsents()).thenAnswer((_) async => true);

      final container = createTestContainer(user: mockUser);

      final result = await container.read(hasRequiredConsentsProvider.future);

      expect(result, true);
    });

    test('returns false when missing consents', () async {
      when(() => mockRepo.hasRequiredConsents()).thenAnswer((_) async => false);

      final container = createTestContainer(user: mockUser);

      final result = await container.read(hasRequiredConsentsProvider.future);

      expect(result, false);
    });

    test('returns false when user is not logged in', () async {
      final container = createTestContainer();

      final result = await container.read(hasRequiredConsentsProvider.future);

      expect(result, false);
    });
  });
}
