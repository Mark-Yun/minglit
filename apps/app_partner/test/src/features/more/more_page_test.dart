import 'package:app_partner/src/features/more/more_coordinator.dart';
import 'package:app_partner/src/features/more/more_page.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:app_partner/src/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../utils/mocks.dart';

// Additional mocks needed for MorePage
class MockMoreCoordinator extends Mock implements MoreCoordinator {}

class MockAuthController extends _MockAuthControllerBase {}

abstract class _MockAuthControllerBase extends Mock implements AuthController {}

void main() {
  late MockGoRouter mockRouter;
  late MockMoreCoordinator mockCoordinator;

  const testPartner = Partner(
    id: 'test-partner-id',
    name: 'Test Partner',
    contactEmail: 'test@partner.com',
  );

  setUp(() {
    mockRouter = MockGoRouter();
    mockCoordinator = MockMoreCoordinator();

    // PackageInfo mock
    PackageInfo.setMockInitialValues(
      appName: 'Test App',
      packageName: 'com.test.app',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    SharedPreferences.setMockInitialValues({});

    // GoRouter stub — go() is called on logout
    when(() => mockRouter.go(any())).thenReturn(null);
  });

  Widget buildSubject({
    AsyncValue<Partner?> partnerValue = const AsyncValue.data(testPartner),
  }) {
    return ProviderScope(
      overrides: [
        currentPartnerInfoProvider.overrideWith(
          (ref) async => partnerValue.when(
            data: (p) => p,
            loading: () => throw Exception('loading'),
            error: (e, _) => throw Exception(e),
          ),
        ),
        moreCoordinatorProvider.overrideWithValue(mockCoordinator),
        authControllerProvider.overrideWith(MockAuthController.new),
        minglitUrlConfigProvider.overrideWithValue(
          const MinglitUrlConfig(MinglitDomains.production()),
        ),
        goRouterProvider.overrideWithValue(mockRouter),
      ],
      child: const MaterialApp(home: MorePage()),
    );
  }

  group('MorePage', () {
    testWidgets('shows partner name and email when partner data is loaded', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Test Partner'), findsOneWidget);
      expect(find.text('test@partner.com'), findsOneWidget);
    });

    testWidgets('shows placeholder when partner is null', (tester) async {
      await tester.pumpWidget(
        buildSubject(partnerValue: const AsyncValue.data(null)),
      );
      await tester.pumpAndSettle();

      expect(find.text('파트너 정보를 불러올 수 없습니다'), findsOneWidget);
    });

    testWidgets('renders at least 4 Dividers for section separation', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(
        find.byType(Divider, skipOffstage: false).evaluate().length,
        greaterThanOrEqualTo(4),
      );
    });

    testWidgets('shows all required menu items', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('인증 심사 관리'), findsOneWidget);
      expect(find.text('파티 관리'), findsOneWidget);
      expect(find.text('멤버 관리'), findsOneWidget);
      expect(find.text('알림 설정'), findsOneWidget);
      // Fix #1213: 로그아웃/회원탈퇴/파트너프로필이 계정 관리 서브페이지로 이동 —
      // MorePage에서는 '계정 관리' 항목만 표시됨
      expect(find.text('계정 관리'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('개인정보처리방침'), 100);
      expect(find.text('개인정보처리방침'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('이용약관'), 100);
      expect(find.text('이용약관'), findsOneWidget);
    });

    testWidgets('tapping 계정 관리 forwards to coordinator', (tester) async {
      // Fix #1213: '계정 관리'는 더 이상 준비 중 토스트가 아니라 계정 관리 서브페이지로 이동
      when(() => mockCoordinator.pushAccountManagement()).thenReturn(null);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('계정 관리'));
      await tester.pumpAndSettle();

      verify(() => mockCoordinator.pushAccountManagement()).called(1);
    });

    testWidgets('tapping 파티 관리 forwards to coordinator', (tester) async {
      // Fix #1269: 더보기에서 파티 관리 메뉴가 누락된 회귀를 막는다.
      when(() => mockCoordinator.pushPartyList()).thenReturn(null);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('파티 관리'));
      await tester.pumpAndSettle();

      verify(() => mockCoordinator.pushPartyList()).called(1);
    });

    testWidgets('계정 관리 is visible on MorePage', (tester) async {
      // Fix #1213: 로그아웃은 계정 관리 서브페이지로 이동 — MorePage에서는 '계정 관리' 항목만 표시
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('계정 관리'), findsOneWidget);
    });

    testWidgets('tapping account deletion forwards to coordinator', (
      tester,
    ) async {
      // Fix #1213: '회원 탈퇴'는 계정 관리 서브페이지로 이동 —
      // MorePage에서 '계정 관리' 탭 시 coordinator.pushAccountManagement() 호출
      when(() => mockCoordinator.pushAccountManagement()).thenReturn(null);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('계정 관리'));
      await tester.pumpAndSettle();

      verify(() => mockCoordinator.pushAccountManagement()).called(1);
    });

    // Fix #1859: regression — '계좌 관리' 라벨이 '정산 계좌 관리'로 돌아오는 것을 방지
    testWidgets(
      'shows 계좌 관리 (not 정산 계좌 관리) when has SETTLEMENT_EDIT permission',
      (tester) async {
        when(
          () => mockCoordinator.pushBankAccountManagement(),
        ).thenReturn(null);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentPartnerInfoProvider.overrideWith(
                (ref) async => testPartner,
              ),
              currentMemberPermissionsProvider.overrideWith(
                (ref) async => ['SETTLEMENT_EDIT'],
              ),
              moreCoordinatorProvider.overrideWithValue(mockCoordinator),
              authControllerProvider.overrideWith(MockAuthController.new),
              minglitUrlConfigProvider.overrideWithValue(
                const MinglitUrlConfig(MinglitDomains.production()),
              ),
              goRouterProvider.overrideWithValue(mockRouter),
            ],
            child: const MaterialApp(home: MorePage()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('계좌 관리'), findsOneWidget);
        expect(find.text('정산 계좌 관리'), findsNothing);

        await tester.tap(find.text('계좌 관리'));
        await tester.pumpAndSettle();

        verify(() => mockCoordinator.pushBankAccountManagement()).called(1);
      },
    );

    testWidgets('placeholder header does not overflow on mobile width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        buildSubject(partnerValue: const AsyncValue.data(null)),
      );
      await tester.pumpAndSettle();

      expect(find.text('파트너 정보를 불러올 수 없습니다'), findsOneWidget);
      expect(find.byType(OverflowBar), findsNothing);
      expect(tester.takeException(), isNull);
    });

    // Fix #2069: regression guard — _ProfileTile must use MinglitAvatarImage
    testWidgets(
      'shows Icons.store fallback when profileImageUrl is null',
      (tester) async {
        // testPartner has no profileImageUrl, so MinglitAvatarImage renders CircleAvatar fallback
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        expect(find.byType(MinglitAvatarImage), findsOneWidget);
        expect(find.byIcon(Icons.store), findsOneWidget);
        // No ClipOval: url is null so MinglitAvatarImage renders CircleAvatar directly
        expect(find.byType(ClipOval), findsNothing);
      },
    );

    testWidgets(
      'renders MinglitAvatarImage (not CircleAvatar+NetworkImage) when profileImageUrl is set',
      (tester) async {
        const partnerWithAvatar = Partner(
          id: 'test-partner-id',
          name: 'Test Partner',
          contactEmail: 'test@partner.com',
          profileImageUrl: 'https://example.com/avatar.png',
        );

        await tester.pumpWidget(
          buildSubject(
            partnerValue: const AsyncValue.data(partnerWithAvatar),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MinglitAvatarImage), findsOneWidget);
        // With a URL, MinglitAvatarImage wraps MinglitImage in ClipOval
        expect(find.byType(ClipOval), findsOneWidget);
        // No bare CircleAvatar visible (it's inside the error fallback, not on screen)
        expect(
          find.ancestor(
            of: find.byType(ClipOval),
            matching: find.byType(MinglitAvatarImage),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '_ProfileTile displayName and email are still rendered correctly',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        expect(find.text('Test Partner'), findsOneWidget);
        expect(find.text('test@partner.com'), findsOneWidget);
      },
    );
  });
}
