import 'package:app_user/src/features/consent/logic/consent_coordinator.dart';
import 'package:app_user/src/features/consent/ui/signup_consent_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

class MockConsentRepository extends Mock implements ConsentRepository {}

class MockUser extends Mock implements User {}

void main() {
  late MockConsentRepository mockRepository;
  late MockUser mockUser;
  late _FakeConsentCoordinator coordinator;

  setUp(() {
    mockRepository = MockConsentRepository();
    mockUser = MockUser();
    coordinator = _FakeConsentCoordinator();

    when(() => mockUser.id).thenReturn('user_1');
    when(
      () => mockRepository.getConsents('user_1'),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.saveConsents('user_1', any()),
    ).thenAnswer((_) async {});
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    String? from,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          consentRepositoryProvider.overrideWithValue(mockRepository),
          currentUserProvider.overrideWithValue(mockUser),
          consentCoordinatorProvider.overrideWithValue(coordinator),
        ],
        child: MaterialApp(
          theme: MinglitTheme.materialTheme,
          home: SignupConsentPage(from: from),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('초기 상태에서 5개 항목이 보이고 CTA는 비활성화된다', (tester) async {
    await pumpPage(tester);

    expect(find.text('환영합니다!'), findsOneWidget);
    expect(find.text('서비스 이용약관'), findsOneWidget);
    expect(find.text('개인정보 수집·이용 동의'), findsOneWidget);
    expect(find.text('만 14세 이상 확인'), findsOneWidget);
    expect(find.text('제3자 제공 동의'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('마케팅 정보 수신 동의'), 200);
    expect(find.text('마케팅 정보 수신 동의'), findsOneWidget);

    final cta = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '다 같이 시작하기'),
    );
    expect(cta.onPressed, isNull);
  });

  testWidgets('전체 동의를 켜면 모든 항목이 선택되고 CTA가 활성화된다', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('전체 동의'));
    await tester.pumpAndSettle();

    final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox));
    expect(checkboxes.every((checkbox) => checkbox.value ?? false), isTrue);

    final cta = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '다 같이 시작하기'),
    );
    expect(cta.onPressed, isNotNull);
  });

  testWidgets('필수 3개만 선택해도 CTA가 활성화된다', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('서비스 이용약관'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('개인정보 수집·이용 동의'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('만 14세 이상 확인'));
    await tester.pumpAndSettle();

    final cta = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '다 같이 시작하기'),
    );
    expect(cta.onPressed, isNotNull);
  });

  testWidgets('보기 버튼을 누르면 약관 상세 바텀시트가 열린다', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.widgetWithText(TextButton, '보기').first);
    await tester.pumpAndSettle();

    expect(find.text('이용자 보호'), findsOneWidget);
    expect(find.text('서비스 이용을 위해 필요한 기본 권리와 의무를 안내합니다.'), findsOneWidget);
  });

  testWidgets('저장 성공 시 선택한 동의를 저장하고 원래 경로로 이동한다', (tester) async {
    await pumpPage(tester, from: '/tickets/my');

    await tester.tap(find.text('서비스 이용약관'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('개인정보 수집·이용 동의'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('만 14세 이상 확인'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, '다 같이 시작하기'));
    await tester.pumpAndSettle();

    final captured =
        verify(
              () => mockRepository.saveConsents('user_1', captureAny()),
            ).captured.single
            as List<ConsentInput>;

    expect(
      captured.map((input) => input.consentKey),
      containsAll(ConsentType.requiredTypes),
    );
    expect(captured, hasLength(3));
    expect(coordinator.lastFrom, '/tickets/my');
  });
}

class _FakeConsentCoordinator extends ConsentCoordinator {
  _FakeConsentCoordinator()
    : super(
        GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const SizedBox.shrink(),
            ),
          ],
        ),
      );

  String? lastFrom;

  @override
  void completeSignup({String? from}) {
    lastFrom = from;
  }
}
