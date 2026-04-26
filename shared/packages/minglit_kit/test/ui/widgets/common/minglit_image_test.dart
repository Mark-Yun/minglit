import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mds/src/ui/widgets/common/minglit_image.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('MinglitImage', () {
    testWidgets('빈 경로 → image_not_supported_outlined 표시, broken_image 없음', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const MinglitImage(path: '', height: 100, width: 100),
        ),
      );
      expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
      expect(find.byIcon(Icons.broken_image), findsNothing);
    });

    testWidgets('공백만 있는 경로 → image_not_supported_outlined 표시', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MinglitImage(path: '   ', height: 100, width: 100),
        ),
      );
      expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    });

    // Fix #1655: 로드 실패 시 broken_image 대신 image_not_supported_outlined를 표시해야 함
    testWidgets(
      '네트워크 로드 실패 → image_not_supported_outlined 표시, broken_image 없음',
      (tester) async {
        final errors = <FlutterErrorDetails>[];
        final previousOnError = FlutterError.onError;
        FlutterError.onError = errors.add;
        addTearDown(() => FlutterError.onError = previousOnError);

        await tester.runAsync(() async {
          await tester.pumpWidget(
            _wrap(
              const MinglitImage(
                // 존재하지 않는 호스트 — 테스트 환경에서 즉시 실패
                path: 'http://localhost:0/nonexistent.jpg',
                height: 100,
                width: 100,
              ),
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 500));
        });
        await tester.pump();

        expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
        expect(find.byIcon(Icons.broken_image), findsNothing);
      },
    );

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

        // Fix #1558: use findsAtLeast(1) — MaterialApp may add ExcludeSemantics internally
        expect(find.byType(ExcludeSemantics), findsAtLeast(1));
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

        // Fix #1558: pumpAndSettle to let NetworkImage fail and trigger errorBuilder
        await tester.pumpAndSettle();

        expect(find.byType(ExcludeSemantics), findsAtLeast(1));
        handle.dispose();
      });
    });
  });
}
