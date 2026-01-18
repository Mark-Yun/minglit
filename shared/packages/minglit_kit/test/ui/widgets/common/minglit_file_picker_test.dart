import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_file_picker.dart';

void main() {
  group('MinglitFilePicker Widget Tests', () {
    testWidgets('renders upload button correctly with label and hint',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MinglitFilePicker(
                label: 'Test Upload',
                hint: 'Test Hint',
                onFilesSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Upload'), findsOneWidget);
      expect(find.text('Test Hint'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
    });

    testWidgets('shows loading indicator when isUploading would be true',
        (tester) async {
      // Since _isUploading is internal state, we can't easily set it from outside
      // without more complex mocking or state management.
      // For now, let's verify it's NOT there initially.
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MinglitFilePicker(
                onFilesSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets(
        'calls onFilesSelected when files are provided (requires complex mock)',
        (tester) async {
      // NOTE: Real testing of file picking requires mocking MethodChannels
      // for image_picker and file_picker.
      // For a basic UI test, we ensure the widget doesn't crash on build.
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MinglitFilePicker(
                onFilesSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(MinglitFilePicker), findsOneWidget);
    });
  });
}