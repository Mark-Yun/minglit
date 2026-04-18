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
    });
  });
}
