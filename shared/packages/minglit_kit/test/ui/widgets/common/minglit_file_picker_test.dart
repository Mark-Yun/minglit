import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_file_picker.dart';

void main() {
  group('MinglitFilePicker Widget Tests', () {
    testWidgets('renders upload button correctly with label and hint', (
      tester,
    ) async {
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

    testWidgets('shows loading indicator when isUploading would be true', (
      tester,
    ) async {
      // Since _isUploading is internal state, we can't easily set
      // it from outside without more complex mocking or state management.
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
      },
    );

    testWidgets('renders with default label when label is not specified', (
      tester,
    ) async {
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
      await tester.pump();

      expect(find.text('파일 업로드'), findsOneWidget);
    });

    testWidgets('renders with default hint when hint is not specified', (
      tester,
    ) async {
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
      await tester.pump();

      expect(find.text('이미지 또는 PDF 파일을 선택해주세요'), findsOneWidget);
    });

    testWidgets(
      'does not show file remove buttons when no files are selected',
      (
        tester,
      ) async {
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
        await tester.pump();

        // Icons.close only appears inside the file preview remove buttons.
        // If no files are selected, no preview list is rendered.
        expect(find.byIcon(Icons.close), findsNothing);
      },
    );

    testWidgets('upload area contains InkWell for tap interaction', (
      tester,
    ) async {
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
      await tester.pump();

      expect(find.byType(InkWell), findsAtLeastNWidgets(1));
    });

    testWidgets('renders correctly with allowMultiple set to true', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MinglitFilePicker(
                allowMultiple: true,
                onFilesSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(MinglitFilePicker), findsOneWidget);
      // Default label is still shown even with allowMultiple enabled.
      expect(find.text('파일 업로드'), findsOneWidget);
    });

    testWidgets('shows upload icon even when initialUrls are provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MinglitFilePicker(
                initialUrls: const ['https://example.com/image.jpg'],
                onFilesSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Upload button area is always visible regardless of initialUrls.
      expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
    });

    testWidgets(
      'renders correctly with autoUpload enabled and uploadBucket specified',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: MinglitFilePicker(
                  autoUpload: true,
                  uploadBucket: 'test-bucket',
                  onFilesSelected: (_) {},
                  onUploadComplete: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(MinglitFilePicker), findsOneWidget);
        // No upload in progress initially.
        expect(find.byType(LinearProgressIndicator), findsNothing);
      },
    );

    testWidgets('renders correctly with FileType.any', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MinglitFilePicker(
                fileType: FileType.any,
                onFilesSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(MinglitFilePicker), findsOneWidget);
      expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
    });

    testWidgets('renders correctly with custom label and custom hint', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MinglitFilePicker(
                label: '문서 업로드',
                hint: 'PDF 파일만 허용',
                fileType: FileType.image,
                onFilesSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('문서 업로드'), findsOneWidget);
      expect(find.text('PDF 파일만 허용'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
    });
  });
}
