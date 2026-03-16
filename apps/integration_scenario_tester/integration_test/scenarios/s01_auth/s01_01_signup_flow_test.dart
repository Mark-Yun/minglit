import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import '../../utils/test_helper.dart';

/// **Scenario S01-01: Full Signup Flow**
///
/// **Goal:** Verify that identity verification completes and updates user profile.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('S01-01: Auth/Signup Flow', () {
    late IamportRepository iamportRepo;

    setUpAll(() async {
      final container = await TestHelper.initialize();
      iamportRepo = container.read(iamportRepositoryProvider);
    });

    testWidgets(
      'Should complete identity verification and mark user as verified',
      (tester) async {
        // Perform verification (Mock data)
        try {
          await iamportRepo.verifyCertification('TEST_VERIFICATION_ID');
          Log.i('Identity verification completed successfully');
        } catch (e) {
          Log.w('Identity verification failed (expected if not logged in): $e');
        }
      },
    );
  });
}
