import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_image_carousel.dart';

void main() {
  group('MinglitImageCarousel Widget Tests', () {
    testWidgets('renders placeholder when imageUrls is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MinglitImageCarousel(
              imageUrls: [],
            ),
          ),
        ),
      );

      // Verify placeholder icon and label are rendered
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
      expect(find.text('이미지 준비 중'), findsOneWidget);
      // Verify carousel is NOT rendered
      expect(find.byType(PageView), findsNothing);
    });

    testWidgets('renders carousel when imageUrls is not empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MinglitImageCarousel(
              imageUrls: ['https://example.com/image1.jpg'],
            ),
          ),
        ),
      );

      // Verify carousel is rendered
      expect(find.byType(PageView), findsOneWidget);
      // Verify placeholder is NOT rendered
      expect(find.byIcon(Icons.image_outlined), findsNothing);
    });

    testWidgets(
      'renders placeholder with fixed height when imageUrls is empty',
      (tester) async {
        const testHeight = 200.0;
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MinglitImageCarousel(
                imageUrls: [],
                height: testHeight,
              ),
            ),
          ),
        );

        // Verify placeholder icon and label are rendered with SizedBox
        expect(find.byIcon(Icons.image_outlined), findsOneWidget);
        expect(find.text('이미지 준비 중'), findsOneWidget);
        expect(find.byType(SizedBox), findsWidgets);
      },
    );

    testWidgets(
      'renders placeholder with aspect ratio when imageUrls is empty '
      'and height is null',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MinglitImageCarousel(
                imageUrls: [],
              ),
            ),
          ),
        );

        // Verify placeholder icon and label are rendered with AspectRatio
        expect(find.byIcon(Icons.image_outlined), findsOneWidget);
        expect(find.text('이미지 준비 중'), findsOneWidget);
        expect(find.byType(AspectRatio), findsWidgets);
      },
    );

    testWidgets('renders indicator when multiple images are provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MinglitImageCarousel(
              imageUrls: [
                'https://example.com/image1.jpg',
                'https://example.com/image2.jpg',
              ],
            ),
          ),
        ),
      );

      // Verify indicator is rendered for multiple images
      expect(find.text('1 / 2'), findsOneWidget);
    });

    testWidgets('does not render indicator when only one image is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MinglitImageCarousel(
              imageUrls: ['https://example.com/image1.jpg'],
            ),
          ),
        ),
      );

      // Verify indicator is NOT rendered for single image
      expect(find.byType(Text), findsNothing);
    });
  });
}
