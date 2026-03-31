import 'package:app_user/src/features/account_deletion/logic/account_deletion_coordinator.dart';
import 'package:app_user/src/features/settings/privacy_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

class MockConsentRepository extends Mock implements ConsentRepository {}

class MockAccountRepository extends Mock implements AccountRepository {}

class MockUser extends Mock implements User {}

class MockAccountDeletionCoordinator extends Mock
    implements AccountDeletionCoordinator {}

void main() {
  late MockConsentRepository mockRepository;
  late MockAccountRepository mockAccountRepo;
  late MockUser mockUser;

  final testConsents = [
    UserConsent(
      id: '1',
      userId: 'user_1',
      consentKey: ConsentType.termsOfService,
      consented: true,
      consentedAt: DateTime(2026),
      createdAt: DateTime(2026),
    ),
    UserConsent(
      id: '2',
      userId: 'user_1',
      consentKey: ConsentType.privacyCollection,
      consented: true,
      consentedAt: DateTime(2026),
      createdAt: DateTime(2026),
    ),
    UserConsent(
      id: '3',
      userId: 'user_1',
      consentKey: ConsentType.thirdPartyProvision,
      consented: false,
      consentedAt: DateTime(2026),
      createdAt: DateTime(2026),
    ),
    UserConsent(
      id: '4',
      userId: 'user_1',
      consentKey: ConsentType.marketingConsent,
      consented: true,
      consentedAt: DateTime(2026),
      createdAt: DateTime(2026),
    ),
    UserConsent(
      id: '5',
      userId: 'user_1',
      consentKey: ConsentType.identityVerification,
      consented: true,
      consentedAt: DateTime(2026),
      createdAt: DateTime(2026),
    ),
  ];

  setUp(() {
    mockRepository = MockConsentRepository();
    mockAccountRepo = MockAccountRepository();
    mockUser = MockUser();

    when(() => mockUser.id).thenReturn('user_1');
    when(
      () => mockRepository.getConsents('user_1'),
    ).thenAnswer((_) async => testConsents);
    when(
      () => mockRepository.saveConsents('user_1', any()),
    ).thenAnswer((_) async {});
    when(
      () => mockAccountRepo.getDeletionStatus(),
    ).thenAnswer((_) async => null);
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          consentRepositoryProvider.overrideWithValue(mockRepository),
          currentUserProvider.overrideWithValue(mockUser),
          accountRepositoryProvider.overrideWithValue(mockAccountRepo),
          accountDeletionCoordinatorProvider.overrideWithValue(
            MockAccountDeletionCoordinator(),
          ),
        ],
        child: MaterialApp(
          theme: MinglitTheme.materialTheme,
          home: const PrivacyPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('로딩 인디케이터가 표시된 후 동의 현황이 보인다', (tester) async {
    await pumpPage(tester);

    expect(find.text('동의 현황'), findsOneWidget);
    // "서비스 이용약관" appears in both 동의 현황 and 약관 보기 sections
    expect(find.text('서비스 이용약관'), findsAtLeast(1));
    expect(find.text('개인정보 수집·이용'), findsOneWidget);
    expect(find.text('제3자 제공 동의'), findsOneWidget);
    expect(find.text('마케팅 정보 수신'), findsOneWidget);
    expect(find.text('본인인증 정보'), findsOneWidget);
  });

  testWidgets('필수 동의 항목은 읽기 전용 "동의됨"으로 표시된다', (tester) async {
    await pumpPage(tester);

    // 서비스 이용약관 and 개인정보 수집·이용 are read-only
    expect(find.text('동의됨'), findsAtLeast(2));
  });

  testWidgets('본인인증이 동의된 경우 "동의됨"으로 표시된다', (tester) async {
    await pumpPage(tester);

    // identityVerification is consented in testConsents
    expect(find.text('본인인증 정보'), findsOneWidget);
    expect(find.text('동의됨'), findsAtLeast(3));
  });

  testWidgets('선택 동의 항목이 SwitchListTile로 표시된다', (tester) async {
    await pumpPage(tester);

    // 마케팅 정보 수신 switch should be ON (consented: true)
    final marketingSwitch = tester.widgetList<SwitchListTile>(
      find.byType(SwitchListTile),
    );
    expect(marketingSwitch.length, 2); // thirdParty + marketing

    // 마케팅 is ON
    final marketingTile = find.widgetWithText(SwitchListTile, '마케팅 정보 수신');
    expect(marketingTile, findsOneWidget);
    final marketingWidget = tester.widget<SwitchListTile>(marketingTile);
    expect(marketingWidget.value, isTrue);

    // 제3자 is OFF
    final thirdPartyTile = find.widgetWithText(
      SwitchListTile,
      '제3자 제공 동의',
    );
    expect(thirdPartyTile, findsOneWidget);
    final thirdPartyWidget = tester.widget<SwitchListTile>(thirdPartyTile);
    expect(thirdPartyWidget.value, isFalse);
  });

  testWidgets('마케팅 토글 시 ConsentController.toggleConsent를 호출한다',
      (tester) async {
    await pumpPage(tester);

    // Toggle marketing OFF (currently ON)
    await tester.tap(find.widgetWithText(SwitchListTile, '마케팅 정보 수신'));
    await tester.pumpAndSettle();

    verify(
      () => mockRepository.saveConsents('user_1', any()),
    ).called(greaterThanOrEqualTo(1));
  });

  testWidgets('약관 보기 섹션이 표시된다', (tester) async {
    await pumpPage(tester);

    expect(find.text('약관 보기'), findsOneWidget);
    // 서비스 이용약관 appears in both 동의 현황 and 약관 보기 sections
    expect(find.text('개인정보처리방침'), findsOneWidget);
  });

  testWidgets('약관 보기에서 서비스 이용약관 탭 시 바텀시트가 열린다', (tester) async {
    await pumpPage(tester);

    // Scroll to 약관 보기 section
    await tester.scrollUntilVisible(find.text('개인정보처리방침'), 200);
    // Tap 서비스 이용약관 in the 약관 보기 section (with chevron)
    await tester.tap(find.widgetWithText(ListTile, '서비스 이용약관').last);
    await tester.pumpAndSettle();

    expect(
      find.text('서비스 이용을 위해 필요한 기본 권리와 의무를 안내합니다.'),
      findsOneWidget,
    );
  });

  testWidgets('개인정보처리방침 탭 시 바텀시트가 열린다', (tester) async {
    await pumpPage(tester);

    await tester.scrollUntilVisible(find.text('개인정보처리방침'), 200);
    await tester.tap(find.text('개인정보처리방침'));
    await tester.pumpAndSettle();

    expect(
      find.text('밍릿의 개인정보 처리 방침을 안내합니다.'),
      findsOneWidget,
    );
  });

  testWidgets('계정 섹션에 회원 탈퇴가 표시된다', (tester) async {
    await pumpPage(tester);

    await tester.scrollUntilVisible(find.text('회원 탈퇴'), 200);
    expect(find.text('회원 탈퇴'), findsOneWidget);
    expect(find.text('회원 탈퇴 시작하기'), findsOneWidget);
  });

  testWidgets('동의 정보 로드 실패 시 에러 메시지가 표시된다', (tester) async {
    when(
      () => mockRepository.getConsents('user_1'),
    ).thenAnswer((_) async => throw Exception('network error'));

    await pumpPage(tester);

    expect(find.text('동의 정보를 불러올 수 없습니다.'), findsOneWidget);
  });
}
