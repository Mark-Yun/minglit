import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import '../../utils/test_helper.dart';

/// **Scenario S01-03: Verification File Upload**
///
/// **Goal:** Verify that file upload fails when the bucket is missing (reproduce bug).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('S01-03: Verification File Upload', () {
    late StorageRepository storageRepo;

    setUpAll(() async {
      final container = await TestHelper.initialize();
      storageRepo = container.read(storageRepositoryProvider);
    });

    testWidgets('Should fail to upload file to missing bucket verification-proofs', (tester) async {
      final fileData = Uint8List.fromList([1, 2, 3, 4]);
      final xFile = XFile.fromData(fileData, name: 'test.png', mimeType: 'image/png');

      try {
        await storageRepo.uploadFile(
          file: xFile,
          bucket: 'verification-proofs',
          pathPrefix: 'test-user-id',
        );
        fail('Upload should have failed with 404 Bucket not found');
      } catch (e) {
        Log.i('Caught expected error: $e');
        expect(e.toString(), contains('Bucket not found'));
      }
    });
  });
}
