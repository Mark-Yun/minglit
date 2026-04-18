import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_image.dart';

void main() {
  group('MinglitImage', () {
    testWidgets('empty path renders placeholder icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MinglitImage(path: '', height: 80, width: 80),
          ),
        ),
      );

      expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    });

    group('Semantics', () {
      testWidgets('semanticLabel is forwarded to underlying Image', (
        tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MinglitImage(
                path: 'https://example.com/a.jpg',
                semanticLabel: '프로필 사진',
              ),
            ),
          ),
        );

        final image = tester.widget<Image>(find.byType(Image));
        expect(image.semanticLabel, '프로필 사진');
        expect(image.excludeFromSemantics, isFalse);
      });

      testWidgets('excludeFromSemantics=true hides the image node', (
        tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MinglitImage(
                path: 'https://example.com/a.jpg',
                excludeFromSemantics: true,
              ),
            ),
          ),
        );

        final image = tester.widget<Image>(find.byType(Image));
        expect(image.excludeFromSemantics, isTrue);
      });

      testWidgets('empty path placeholder respects semanticLabel', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MinglitImage(
                path: '',
                semanticLabel: '이미지 없음',
              ),
            ),
          ),
        );

        // find.byWidgetPredicate checks the Semantics widget around placeholder
        expect(
          find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.label == '이미지 없음',
          ),
          findsOneWidget,
        );
        handle.dispose();
      });

      testWidgets('empty path placeholder respects excludeFromSemantics', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MinglitImage(
                path: '',
                excludeFromSemantics: true,
              ),
            ),
          ),
        );

        expect(find.byType(ExcludeSemantics), findsOneWidget);
        handle.dispose();
      });

      testWidgets('error fallback respects semanticLabel', (tester) async {
        final handle = tester.ensureSemantics();
        // Force error by using a non-existent network image path
        // In widget tests, NetworkImage fails by default unless mocked.
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MinglitImage(
                path: 'http://invalid-url.com/image.jpg',
                semanticLabel: '로드 실패',
              ),
            ),
          ),
        );

        // Let the image fail and trigger errorBuilder
        await tester.pump();

        expect(
          find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.label == '로드 실패',
          ),
          findsOneWidget,
        );
        handle.dispose();
      });

      testWidgets('error fallback respects excludeFromSemantics', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MinglitImage(
                path: 'http://invalid-url.com/image.jpg',
                excludeFromSemantics: true,
              ),
            ),
          ),
        );

        await tester.pump();

        expect(find.byType(ExcludeSemantics), findsOneWidget);
        handle.dispose();
      });
    });
  });
}
