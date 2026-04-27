// Fix #1861: AccountManagementRoute 본인인증 배선 회귀 방지 테스트
//
// 검증 포인트:
// 1. /my/account 진입 시 '본인인증' 타일이 표시됨
//    — AccountManagementRoute가 onCertification을 AccountManagementPage에 연결해야만 타일이 표시됨.
//      onCertification이 제거되면 AccountManagementPage 위젯 테스트는 여전히 통과하지만,
//      이 테스트가 실패하여 회귀를 감지한다.
// 2. '본인인증' 타일 탭 시 IdentityVerificationScreen으로 이동함
//    — const CertificationRoute().push(context) 배선이 끊기면 실패한다.

import 'package:app_user/src/features/auth/login_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import 'utils/test_app.dart';
import 'utils/test_mocks.dart';

class _MockConsentRepository extends Mock implements ConsentRepository {}

void main() {
  late User testUser;
  late UserProfile testProfile;
  late _MockConsentRepository mockConsentRepo;

  setUp(() {
    testUser = createMockUserForTest();
    testProfile = UserProfile(
      id: 'test-user-id',
      name: 'Test User',
      username: 'test_user',
      gender: 'male',
      birthYear: 1995,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );
    mockConsentRepo = _MockConsentRepository();
    when(
      () => mockConsentRepo.hasRequiredConsents(),
    ).thenAnswer((_) async => true);
    when(
      () => mockConsentRepo.getConsents(any()),
    ).thenAnswer((_) async => <UserConsent>[]);
  });

  group('IT: AccountManagementRoute 본인인증 경로 배선 (#1861)', () {
    testWidgets(
      'TC-001: 비로그인 시 /my/account 접근 → 로그인으로 리다이렉트',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(initialLocation: '/my/account'),
        );
        await tester.pump();
        await tester.pump();

        expect(find.byType(LoginPage), findsOneWidget);
      },
    );

    testWidgets(
      'TC-002: 로그인 시 /my/account에서 본인인증 타일 노출'
      ' — AccountManagementRoute가 onCertification을 배선하지 않으면 실패',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            isLoggedIn: true,
            currentUser: testUser,
            initialLocation: '/my/account',
            additionalOverrides: [
              // Fix #1861: AccountManagementRoute.build()가 currentUserProfileProvider를
              // 읽어 isVerified를 AccountManagementPage에 전달한다.
              currentUserProfileProvider.overrideWith(
                (_) async => testProfile,
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // '본인인증' 타일은 onCertification이 non-null일 때만 표시된다.
        // AccountManagementRoute가 onCertification을 제거하면 이 assert가 실패한다.
        expect(find.text('본인인증'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-003: 본인인증 타일 탭 시 IdentityVerificationScreen으로 이동'
      ' — CertificationRoute 배선이 끊기면 실패',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            isLoggedIn: true,
            currentUser: testUser,
            initialLocation: '/my/account',
            additionalOverrides: [
              currentUserProfileProvider.overrideWith(
                (_) async => testProfile,
              ),
              // Fix #1861: IdentityVerificationScreen이 ConsentController를 통해
              // consentRepositoryProvider를 사용한다. Supabase 호출 방지용 mock.
              consentRepositoryProvider.overrideWithValue(mockConsentRepo),
            ],
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('본인인증'));
        // GoRouter push는 동기적으로 실행됨.
        // 첫 pump에서 IdentityVerificationScreen 렌더링, 두 번째 pump에서 postFrameCallback 소진.
        // pumpAndSettle을 쓰지 않는 이유: _startVerificationFlow()의 비동기 플로우가
        // 네이티브 IamportCertification을 호출하여 테스트 환경에서 hang이 발생하기 때문.
        await tester.pump();
        await tester.pump();

        // CertificationRoute 배선이 살아있으면 IdentityVerificationScreen이 보인다.
        expect(find.byType(IdentityVerificationScreen), findsOneWidget);
      },
    );
  });
}
