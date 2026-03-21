import 'package:app_partner/src/features/party/party_providers.dart';
import 'package:app_partner/src/features/verification/manage/verification_manage_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../utils/mocks.dart';
import '../../../utils/test_utils.dart';

const _testPartner = Partner(
  id: 'partner-1',
  name: 'Test Partner',
  contactEmail: 'test@partner.com',
);

const _activeVerification = Verification(
  id: 'v1',
  partnerId: 'partner-1',
  category: VerificationCategory.etc,
  internalName: 'active',
  displayName: 'Active V',
  description: '',
  iconKey: 'star',
  formSchema: [],
);

const _archivedVerification = Verification(
  id: 'v2',
  partnerId: 'partner-1',
  category: VerificationCategory.etc,
  internalName: 'archived',
  displayName: 'Archived V',
  description: '',
  iconKey: 'star',
  formSchema: [],
  isActive: false,
);

void main() {
  late MockVerificationRepository mockVerificationRepo;

  setUp(() {
    mockVerificationRepo = MockVerificationRepository();

    when(
      () => mockVerificationRepo.getPartnerVerifications(
        any(),
        isActive: true,
      ),
    ).thenAnswer((_) async => [_activeVerification]);

    when(
      () => mockVerificationRepo.getPartnerVerifications(
        any(),
        isActive: false,
      ),
    ).thenAnswer((_) async => [_archivedVerification]);

    // Default call without named param (isActive defaults to true)
    when(
      () => mockVerificationRepo.getPartnerVerifications(any()),
    ).thenAnswer((_) async => [_activeVerification]);

    when(() => mockVerificationRepo.deleteVerification(any()))
        .thenAnswer((_) async {});
    when(() => mockVerificationRepo.restoreVerification(any()))
        .thenAnswer((_) async {});
  });

  ProviderContainer buildContainer() {
    return createContainer(
      overrides: [
        currentPartnerInfoProvider.overrideWith((_) async => _testPartner),
        verificationRepositoryProvider.overrideWithValue(mockVerificationRepo),
      ],
    );
  }

  group('VerificationManageController', () {
    test('builds with active and archived verifications', () async {
      final container = buildContainer();

      final result = await container
          .read(verificationManageControllerProvider.future);

      expect(result.active, contains(_activeVerification));
      expect(result.archived, contains(_archivedVerification));
    });

    test('build returns empty state when partner is null', () async {
      final container = createContainer(
        overrides: [
          currentPartnerInfoProvider.overrideWith((_) async => null),
          verificationRepositoryProvider
              .overrideWithValue(mockVerificationRepo),
        ],
      );

      final result = await container
          .read(verificationManageControllerProvider.future);

      expect(result.active, isEmpty);
      expect(result.archived, isEmpty);
    });

    test('archiveVerification calls deleteVerification on repo', () async {
      final container = buildContainer();

      // Wait for build to complete
      await container.read(verificationManageControllerProvider.future);

      await container
          .read(verificationManageControllerProvider.notifier)
          .archiveVerification('v1');

      verify(() => mockVerificationRepo.deleteVerification('v1')).called(1);
    });

    test('restoreVerification calls restoreVerification on repo', () async {
      final container = buildContainer();

      await container.read(verificationManageControllerProvider.future);

      await container
          .read(verificationManageControllerProvider.notifier)
          .restoreVerification('v2');

      verify(() => mockVerificationRepo.restoreVerification('v2')).called(1);
    });
  });
}
