import 'package:app_user/src/features/auth/login_page.dart';
import 'package:app_user/src/features/event/admission/event_application_wizard_page.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_app.dart';

void main() {
  group('Event Application CUJ', () {
    testWidgets('비로그인 시 /apply redirect → LoginPage', (tester) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(
        createTestApp(initialLocation: '/events/test-id/apply'),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byType(EventApplicationWizardPage), findsNothing);
      expect(find.byType(LoginPage), findsOneWidget);
    });
  });
}
