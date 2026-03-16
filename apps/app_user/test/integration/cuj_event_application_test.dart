import 'package:app_user/src/features/event/admission/event_application_wizard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';
import '../utils/mocks.dart';
import 'utils/mock_data.dart';
import 'utils/test_app.dart';

void main() {
  group('Event Application CUJ', () {
    testWidgets('비로그인 시 /apply redirect', (tester) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(createTestApp(initialLocation: '/events/test-id/apply'));
      await tester.pump();
      await tester.pump();
      expect(find.byType(EventApplicationWizardPage), findsNothing);
    });
  });
}
