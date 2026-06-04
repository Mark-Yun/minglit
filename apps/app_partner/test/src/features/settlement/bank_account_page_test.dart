// Fix #1938: bank account number validation regression tests
// Fix #1928: RetryPayoutButton success message duplicate regression guard

import 'package:app_partner/src/features/settlement/bank_account_page.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:app_partner/src/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../utils/mocks.dart';

Widget _buildForm({Map<String, dynamic>? accountData}) {
  return ProviderScope(
    overrides: [
      currentPartnerInfoProvider.overrideWith(
        (ref) async => const Partner(id: 'partner-1', name: 'Test Partner'),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: AccountEditForm(accountData: accountData, onSaved: () {}),
      ),
    ),
  );
}

Future<void> _selectBank(
  WidgetTester tester, {
  String bankName = 'KB국민은행',
}) async {
  await tester.tap(find.widgetWithText(TextFormField, '은행 선택'));
  await tester.pumpAndSettle();
  final bankFinder = find.text(bankName).last;
  await tester.ensureVisible(bankFinder);
  await tester.pumpAndSettle();
  await tester.tap(bankFinder);
  await tester.pumpAndSettle();
}

Future<void> _fillAndSubmit(
  WidgetTester tester, {
  String holder = '홍길동',
  String accountNumber = '',
}) async {
  await _selectBank(tester);
  await tester.enterText(find.widgetWithText(TextFormField, '예금주'), holder);
  await tester.enterText(
    find.widgetWithText(TextFormField, '계좌번호'),
    accountNumber,
  );
  await tester.tap(find.text('저장하고 확인 요청'));
  await tester.pump();
}

void main() {
  group('AccountEditForm — account number validation (Fix #1938)', () {
    testWidgets('empty account state uses registration title', (tester) async {
      await tester.pumpWidget(_buildForm());
      await tester.pump();

      expect(find.text('계좌 등록'), findsOneWidget);
      expect(find.text('계좌 수정'), findsNothing);
    });

    testWidgets('registered account state uses edit title', (tester) async {
      await tester.pumpWidget(
        _buildForm(
          accountData: const {
            'bank_code': 'kb',
            'bank_name': 'KB국민은행',
            'account_holder': '홍길동',
            'account_number': '1234567890',
            'bank_verification_status': 'manual_review_pending',
          },
        ),
      );
      await tester.pump();

      expect(find.text('계좌 수정'), findsOneWidget);
      expect(find.text('계좌 등록'), findsNothing);
    });

    testWidgets('empty account number shows required error', (tester) async {
      await tester.pumpWidget(_buildForm());
      await tester.pump();

      await _fillAndSubmit(tester);

      expect(find.text('계좌번호를 입력해 주세요.'), findsOneWidget);
    });

    testWidgets('9-digit account number shows format error', (tester) async {
      await tester.pumpWidget(_buildForm());
      await tester.pump();

      await _fillAndSubmit(tester, accountNumber: '123456789');

      expect(find.text('계좌번호는 10~16자리 숫자여야 합니다.'), findsOneWidget);
    });

    testWidgets('17-digit account number shows format error', (tester) async {
      await tester.pumpWidget(_buildForm());
      await tester.pump();

      await _fillAndSubmit(tester, accountNumber: '12345678901234567');

      expect(find.text('계좌번호는 10~16자리 숫자여야 합니다.'), findsOneWidget);
    });

    testWidgets('non-digit account number shows format error', (tester) async {
      await tester.pumpWidget(_buildForm());
      await tester.pump();

      // FilteringTextInputFormatter blocks non-digits at keystroke level,
      // Validator catches any non-digits that bypass the input formatter.
      await _fillAndSubmit(tester, accountNumber: 'asdf1234567');

      expect(find.text('계좌번호는 10~16자리 숫자여야 합니다.'), findsOneWidget);
    });

    testWidgets('10-digit valid account number passes validation', (
      tester,
    ) async {
      final mockSettlementRepo = MockSettlementRepository();
      when(
        () => mockSettlementRepo.upsertBankAccount(
          partnerId: any(named: 'partnerId'),
          bankCode: any(named: 'bankCode'),
          bankName: any(named: 'bankName'),
          accountHolder: any(named: 'accountHolder'),
          accountNumber: any(named: 'accountNumber'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentPartnerInfoProvider.overrideWith(
              (ref) async => const Partner(id: 'partner-1', name: 'Test'),
            ),
            settlementRepositoryProvider.overrideWithValue(mockSettlementRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AccountEditForm(onSaved: _noop),
            ),
          ),
        ),
      );
      await tester.pump();

      await _fillAndSubmit(tester, accountNumber: '1234567890');

      // No format error shown
      expect(find.text('계좌번호는 10~16자리 숫자여야 합니다.'), findsNothing);
      expect(find.text('계좌번호를 입력해 주세요.'), findsNothing);
      verify(
        () => mockSettlementRepo.upsertBankAccount(
          partnerId: 'partner-1',
          bankCode: 'kb',
          bankName: 'KB국민은행',
          accountHolder: '홍길동',
          accountNumber: '1234567890',
        ),
      ).called(1);
    });

    testWidgets('16-digit valid account number passes validation', (
      tester,
    ) async {
      final mockSettlementRepo = MockSettlementRepository();
      when(
        () => mockSettlementRepo.upsertBankAccount(
          partnerId: any(named: 'partnerId'),
          bankCode: any(named: 'bankCode'),
          bankName: any(named: 'bankName'),
          accountHolder: any(named: 'accountHolder'),
          accountNumber: any(named: 'accountNumber'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentPartnerInfoProvider.overrideWith(
              (ref) async => const Partner(id: 'partner-1', name: 'Test'),
            ),
            settlementRepositoryProvider.overrideWithValue(mockSettlementRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AccountEditForm(onSaved: _noop),
            ),
          ),
        ),
      );
      await tester.pump();

      await _fillAndSubmit(tester, accountNumber: '1234567890123456');

      expect(find.text('계좌번호는 10~16자리 숫자여야 합니다.'), findsNothing);
      expect(find.text('계좌번호를 입력해 주세요.'), findsNothing);
    });

    testWidgets('bank selection sheet stores selected bank code', (
      tester,
    ) async {
      final mockSettlementRepo = MockSettlementRepository();
      when(
        () => mockSettlementRepo.upsertBankAccount(
          partnerId: any(named: 'partnerId'),
          bankCode: any(named: 'bankCode'),
          bankName: any(named: 'bankName'),
          accountHolder: any(named: 'accountHolder'),
          accountNumber: any(named: 'accountNumber'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentPartnerInfoProvider.overrideWith(
              (ref) async => const Partner(id: 'partner-1', name: 'Test'),
            ),
            settlementRepositoryProvider.overrideWithValue(mockSettlementRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AccountEditForm(onSaved: _noop),
            ),
          ),
        ),
      );
      await tester.pump();

      await _selectBank(tester, bankName: '카카오뱅크');
      await tester.enterText(find.widgetWithText(TextFormField, '예금주'), '홍길동');
      await tester.enterText(
        find.widgetWithText(TextFormField, '계좌번호'),
        '1234567890',
      );
      await tester.tap(find.text('저장하고 확인 요청'));
      await tester.pump();

      verify(
        () => mockSettlementRepo.upsertBankAccount(
          partnerId: 'partner-1',
          bankCode: 'kakao',
          bankName: '카카오뱅크',
          accountHolder: '홍길동',
          accountNumber: '1234567890',
        ),
      ).called(1);
    });
  });

  group('AccountCard — verification status', () {
    testWidgets('failed status exposes manual review fallback', (tester) async {
      var requested = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccountCard(
              accountData: const {
                'bank_name': '카카오뱅크',
                'account_holder': '홍길동',
                'account_number': '3333011234567',
                'bank_verification_status': 'verification_failed',
              },
              isRequestingManualReview: false,
              onRequestManualReview: () => requested = true,
            ),
          ),
        ),
      );

      expect(find.text('확인 실패'), findsOneWidget);
      expect(find.text('수동 검증 요청'), findsOneWidget);

      await tester.tap(find.text('수동 검증 요청'));
      expect(requested, isTrue);
    });
  });

  // Fix #1928: RetryPayoutButton must not show its own success snackbar —
  // coordinator.retryPayout already calls showMinglitSuccess.
  group('RetryPayoutButton — Fix #1928: no duplicate success message', () {
    testWidgets(
      'success message appears exactly once (coordinator only, not widget)',
      (tester) async {
        final mockRepo = MockSettlementRepository();
        final mockRouter = MockGoRouter();
        when(() => mockRouter.go(any())).thenReturn(null);
        when(() => mockRouter.push(any())).thenAnswer((_) => Future.value());
        when(
          () => mockRepo.retryPayout(
            payoutId: any(named: 'payoutId'),
            partnerId: any(named: 'partnerId'),
          ),
        ).thenAnswer((_) async => {'status': 'ok'});

        var onSuccessCalled = false;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settlementRepositoryProvider.overrideWithValue(mockRepo),
              goRouterProvider.overrideWithValue(mockRouter),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: RetryPayoutButton(
                  payoutId: 'payout-1',
                  partnerId: 'partner-1',
                  onSuccess: () => onSuccessCalled = true,
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('재지급 요청'));
        await tester.pumpAndSettle();

        // Coordinator shows the success toast — must appear exactly once
        expect(
          find.text('재지급 요청이 완료되었습니다.'),
          findsOneWidget,
          reason: 'success message must appear once (from coordinator only)',
        );
        expect(onSuccessCalled, isTrue);
      },
    );
  });
}

void _noop() {}
