import 'package:app_user/src/features/consent/ui/signup_consent_page.dart';
import 'package:app_user/src/features/home/home_page.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_app.dart';
import 'utils/test_mocks.dart';

void main() {
  group('Consent Redirect Flow', () {
    testWidgets(
      '로그인 + 미동의: / 접근 시 SignupConsentPage로 리다이렉트',
      (tester) async {
        setKoreanLocale(tester);
        final user = createMockUserForTest();
        await tester.pumpWidget(
          createTestApp(
            isLoggedIn: true,
            currentUser: user,
            hasRequiredConsents: false,
            initialLocation: '/',
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.byType(SignupConsentPage), findsOneWidget);
        expect(find.byType(HomePage), findsNothing);
      },
    );

    testWidgets(
      '로그인 + 미동의: /signup/consent에 머물면 리다이렉트 루프 없음',
      (tester) async {
        setKoreanLocale(tester);
        final user = createMockUserForTest();
        await tester.pumpWidget(
          createTestApp(
            isLoggedIn: true,
            currentUser: user,
            hasRequiredConsents: false,
            initialLocation: '/signup/consent',
          ),
        );
        await tester.pump();
        await tester.pump();

        // Should stay on SignupConsentPage — no redirect loop
        expect(find.byType(SignupConsentPage), findsOneWidget);
      },
    );

    testWidgets(
      '로그인 + 동의 완료: /signup/consent 접근 시 홈으로 리다이렉트',
      (tester) async {
        setKoreanLocale(tester);
        final user = createMockUserForTest();
        await tester.pumpWidget(
          createTestApp(
            isLoggedIn: true,
            currentUser: user,
            hasRequiredConsents: true,
            initialLocation: '/signup/consent',
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.byType(HomePage), findsOneWidget);
        expect(find.byType(SignupConsentPage), findsNothing);
      },
    );

    testWidgets(
      '로그인 + 동의 완료: / 접근 시 리다이렉트 없음',
      (tester) async {
        setKoreanLocale(tester);
        final user = createMockUserForTest();
        await tester.pumpWidget(
          createTestApp(
            isLoggedIn: true,
            currentUser: user,
            hasRequiredConsents: true,
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.byType(HomePage), findsOneWidget);
        expect(find.byType(SignupConsentPage), findsNothing);
      },
    );

    testWidgets(
      '비로그인: consent 체크 스킵 — / 접근 시 HomePage',
      (tester) async {
        setKoreanLocale(tester);
        await tester.pumpWidget(
          createTestApp(
            isLoggedIn: false,
            hasRequiredConsents: false,
          ),
        );
        await tester.pump();
        await tester.pump();

        // Not logged in → consent check is skipped entirely
        expect(find.byType(HomePage), findsOneWidget);
        expect(find.byType(SignupConsentPage), findsNothing);
      },
    );
  });
}
