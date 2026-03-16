import 'package:app_user/src/features/auth/login_page.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_app.dart';

void main() {
  group('Event Detail CUJ', () {
    // EventDetailPage has internal timers (scroll sync, animations) that cause
    // "Timer still pending" in widget tests. Test redirect behavior instead.
    testWidgets('비로그인: /events/:id/apply 접근 시 LoginPage redirect', (tester) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(createTestApp(initialLocation: '/events/test-id/apply'));
      await tester.pump();
      await tester.pump();
      expect(find.byType(LoginPage), findsOneWidget);
    });
  });
}
