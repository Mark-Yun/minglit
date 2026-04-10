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
  });
}
