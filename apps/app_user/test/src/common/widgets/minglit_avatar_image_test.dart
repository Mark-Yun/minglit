import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  // Fix #1936: regression guard for MinglitAvatarImage — null/empty URL must
  // show CircleAvatar fallback; a network URL must produce ClipOval delegate.

  testWidgets('null url shows CircleAvatar with fallback icon', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const MinglitAvatarImage(
          radius: 24,
          url: null,
          fallbackIcon: Icons.person,
        ),
      ),
    );

    expect(find.byType(CircleAvatar), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.byType(ClipOval), findsNothing);
  });

  testWidgets('empty url shows CircleAvatar with fallback icon', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const MinglitAvatarImage(radius: 24, url: '', fallbackIcon: Icons.store),
      ),
    );

    expect(find.byType(CircleAvatar), findsOneWidget);
    expect(find.byIcon(Icons.store), findsOneWidget);
    expect(find.byType(ClipOval), findsNothing);
  });

  testWidgets('non-null url produces ClipOval delegate to MinglitImage',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const MinglitAvatarImage(
          radius: 24,
          url: 'https://example.com/avatar.png',
        ),
      ),
    );

    // ClipOval wrapping MinglitImage must be in the tree regardless of whether
    // the network request completes (it won't in tests).
    expect(find.byType(ClipOval), findsOneWidget);
    expect(find.byType(CircleAvatar), findsNothing);
  });

  testWidgets('image load failure renders without throwing', (tester) async {
    // In flutter_test all NetworkImage requests fail — this confirms the
    // MinglitImage errorBuilder path does not propagate an exception.
    await tester.pumpWidget(
      _wrap(
        const MinglitAvatarImage(
          radius: 24,
          url: 'https://example.com/avatar.png',
        ),
      ),
    );
    // Let image loading settle (error fires after initial frame).
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    // After failure MinglitImage renders its error placeholder inside ClipOval.
    expect(find.byType(ClipOval), findsOneWidget);
  });

  testWidgets('fallbackIconSize overrides default icon size', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const MinglitAvatarImage(
          radius: 12,
          url: null,
          fallbackIcon: Icons.store,
          fallbackIconSize: MinglitIconSize.xsmall,
        ),
      ),
    );

    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.size, MinglitIconSize.xsmall);
  });
}
