// Fix #1938: bank account number validation regression tests

import 'package:app_partner/src/features/settlement/bank_account_page.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
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

Future<void> _fillAndSubmit(
  WidgetTester tester, {
  String bank = '국민은행',
  String holder = '홍길동',
  String accountNumber = '',
}) async {
  await tester.enterText(find.widgetWithText(TextFormField, '은행명'), bank);
  await tester.enterText(find.widgetWithText(TextFormField, '예금주'), holder);
  await tester.enterText(
    find.widgetWithText(TextFormField, '계좌번호'),
    accountNumber,
  );
  await tester.tap(find.text('저장'));
  await tester.pump();
}

void main() {
  group('AccountEditForm — account number validation (Fix #1938)', () {
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
      // but validator catches any that bypass (e.g. programmatic entry in tests)
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
    });

    testWidgets('16-digit valid account number passes validation', (
      tester,
    ) async {
      final mockSettlementRepo = MockSettlementRepository();
      when(
        () => mockSettlementRepo.upsertBankAccount(
          partnerId: any(named: 'partnerId'),
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
  });
}

void _noop() {}
