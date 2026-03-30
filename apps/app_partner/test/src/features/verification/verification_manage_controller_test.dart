import 'package:app_partner/src/features/verification/manage/verification_manage_controller.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../utils/mocks.dart';
import '../../../utils/test_utils.dart';

/// Awaits until the VerificationManageController async build completes.
/// Yields to the event loop to let the mocked async provider chain resolve.
Future<void> waitForBuild(ProviderContainer container) async {
  // Double yield: first for currentPartnerInfoProvider.future,
  // second for the repo calls within Future.wait.
  await Future<void>(() {});
  await Future<void>(() {});
}

Verification _makeVerification(String id, {bool isActive = true}) {
  return Verification(
    id: id,
    partnerId: 'partner-1',
    category: VerificationCategory.etc,
    internalName: 'test_$id',
    displayName: 'Test $id',
    isActive: isActive,
  );
}

void main() {
  late MockVerificationRepository mockVerificationRepo;
  late Partner fakePartner;

  setUp(() {
    mockVerificationRepo = MockVerificationRepository();
    fakePartner = const Partner(id: 'partner-1', name: 'Test Partner');
  });

  ProviderContainer makeContainer({
    Partner? partner,
    bool nullPartner = false,
    List<Verification>? activeList,
    List<Verification>? archivedList,
    Exception? loadError,
  }) {
    final resolvedPartner = nullPartner ? null : (partner ?? fakePartner);

    if (loadError != null) {
      when(
        () => mockVerificationRepo.getPartnerVerifications(any()),
      ).thenAnswer((_) async => throw loadError);
      when(
        () => mockVerificationRepo.getPartnerVerifications(
          any(),
          isActive: any(named: 'isActive'),
        ),
      ).thenAnswer((_) async => throw loadError);
    } else {
      // Active list
      when(
        () => mockVerificationRepo.getPartnerVerifications(
          any(),
        ),
      ).thenAnswer((_) async => activeList ?? []);

      // Archived list
      when(
        () => mockVerificationRepo.getPartnerVerifications(
          any(),
          isActive: false,
        ),
      ).thenAnswer((_) async => archivedList ?? []);
    }

    return createContainer(
      overrides: [
        verificationRepositoryProvider.overrideWithValue(mockVerificationRepo),
        currentPartnerInfoProvider.overrideWith(
          (ref) async => resolvedPartner,
        ),
      ],
    );
  }

  group('VerificationManageController', () {
    test('build loads active and archived lists', () async {
      final active = [_makeVerification('v-1'), _makeVerification('v-2')];
      final archived = [_makeVerification('v-3', isActive: false)];

      final container = makeContainer(
        activeList: active,
        archivedList: archived,
      );
      final sub = container.listen(
        verificationManageControllerProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      await waitForBuild(container);

      final state = container.read(verificationManageControllerProvider).value!;
      expect(state.active.length, 2);
      expect(state.archived.length, 1);
      expect(state.active.first.id, 'v-1');
      expect(state.archived.first.id, 'v-3');
    });

    test('build with null partner returns empty state', () async {
      final container = makeContainer(nullPartner: true);
      final sub = container.listen(
        verificationManageControllerProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      await waitForBuild(container);

      final state = container.read(verificationManageControllerProvider).value!;
      expect(state.active, isEmpty);
      expect(state.archived, isEmpty);
      verifyNever(
        () => mockVerificationRepo.getPartnerVerifications(any()),
      );
    });

    test('build error produces AsyncError', () async {
      final container = makeContainer(loadError: Exception('network error'));
      final sub = container.listen(
        verificationManageControllerProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      await waitForBuild(container);

      final asyncValue = container.read(verificationManageControllerProvider);
      expect(asyncValue.hasError, isTrue);
    });

    test(
      'archiveVerification calls deleteVerification and refreshes',
      () async {
        final active = [_makeVerification('v-1')];
        final container = makeContainer(activeList: active);
        final sub = container.listen(
          verificationManageControllerProvider,
          (_, _) {},
        );
        addTearDown(sub.close);

        await waitForBuild(container);

        when(
          () => mockVerificationRepo.deleteVerification(any()),
        ).thenAnswer((_) async {});

        // After archive, active list will be empty
        when(
          () => mockVerificationRepo.getPartnerVerifications(
            any(),
          ),
        ).thenAnswer((_) async => []);
        when(
          () => mockVerificationRepo.getPartnerVerifications(
            any(),
            isActive: false,
          ),
        ).thenAnswer((_) async => [_makeVerification('v-1', isActive: false)]);

        await container
            .read(verificationManageControllerProvider.notifier)
            .archiveVerification('v-1');

        verify(() => mockVerificationRepo.deleteVerification('v-1')).called(1);

        final state = container
            .read(verificationManageControllerProvider)
            .value!;
        expect(state.active, isEmpty);
        expect(state.archived.length, 1);
      },
    );

    test('archiveVerification error sets AsyncError', () async {
      final active = [_makeVerification('v-1')];
      final container = makeContainer(activeList: active);
      final sub = container.listen(
        verificationManageControllerProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      await waitForBuild(container);

      when(
        () => mockVerificationRepo.deleteVerification(any()),
      ).thenThrow(Exception('delete failed'));

      await container
          .read(verificationManageControllerProvider.notifier)
          .archiveVerification('v-1');

      final asyncValue = container.read(verificationManageControllerProvider);
      expect(asyncValue.hasError, isTrue);
    });

    test(
      'restoreVerification calls restoreVerification and refreshes',
      () async {
        final archived = [_makeVerification('v-1', isActive: false)];
        final container = makeContainer(archivedList: archived);
        final sub = container.listen(
          verificationManageControllerProvider,
          (_, _) {},
        );
        addTearDown(sub.close);

        await waitForBuild(container);

        when(
          () => mockVerificationRepo.restoreVerification(any()),
        ).thenAnswer((_) async {});

        // After restore, archived will be empty, active gains the item
        when(
          () => mockVerificationRepo.getPartnerVerifications(
            any(),
          ),
        ).thenAnswer((_) async => [_makeVerification('v-1')]);
        when(
          () => mockVerificationRepo.getPartnerVerifications(
            any(),
            isActive: false,
          ),
        ).thenAnswer((_) async => []);

        await container
            .read(verificationManageControllerProvider.notifier)
            .restoreVerification('v-1');

        verify(() => mockVerificationRepo.restoreVerification('v-1')).called(1);

        final state = container
            .read(verificationManageControllerProvider)
            .value!;
        expect(state.active.length, 1);
        expect(state.archived, isEmpty);
      },
    );

    test('restoreVerification error sets AsyncError', () async {
      final archived = [_makeVerification('v-1', isActive: false)];
      final container = makeContainer(archivedList: archived);
      final sub = container.listen(
        verificationManageControllerProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      await waitForBuild(container);

      when(
        () => mockVerificationRepo.restoreVerification(any()),
      ).thenThrow(Exception('restore failed'));

      await container
          .read(verificationManageControllerProvider.notifier)
          .restoreVerification('v-1');

      final asyncValue = container.read(verificationManageControllerProvider);
      expect(asyncValue.hasError, isTrue);
    });
  });
}
