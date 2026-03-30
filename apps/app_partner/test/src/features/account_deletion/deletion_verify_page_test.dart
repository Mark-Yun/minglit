import 'package:app_partner/src/features/account_deletion/account_deletion_coordinator.dart';
import 'package:app_partner/src/features/account_deletion/partner_account_deletion_guard.dart';
import 'package:app_partner/src/features/account_deletion/ui/deletion_verify_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/mocks.dart';

class _MockAccountDeletionCoordinator extends Mock
    implements AccountDeletionCoordinator {}

class _MockAccountRepository extends Mock implements AccountRepository {}

class _FakeUser extends Fake implements User {}

void main() {
  late _MockAccountDeletionCoordinator coordinator;
  late _MockAccountRepository accountRepository;
  late User user;

  setUpAll(() {
    registerFallbackValue(_FakeUser());
  });

  setUp(() {
    coordinator = _MockAccountDeletionCoordinator();
    accountRepository = _MockAccountRepository();
    user = User(
      id: 'user-1',
      appMetadata: const {
        'provider': 'email',
        'providers': ['email'],
      },
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: DateTime(2026).toIso8601String(),
      email: 'partner@test.com',
      identities: const [],
    );

    when(
      () => accountRepository.getDeletionStatus(),
    ).thenAnswer((_) async => null);
  });

  Widget buildSubject({
    required PartnerAccountDeletionGuard guard,
  }) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => user),
        accountRepositoryProvider.overrideWithValue(accountRepository),
        partnerAccountDeletionGuardProvider.overrideWith(
          (ref) async => guard,
        ),
        accountDeletionCoordinatorProvider.overrideWithValue(coordinator),
      ],
      child: const MaterialApp(
        home: DeletionVerifyPage(),
      ),
    );
  }

  testWidgets(
    'shows blocking actions and disables submit when blockers exist',
    (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          guard: const PartnerAccountDeletionGuard(
            activeEventCount: 1,
            unsettledSettlementCount: 2,
            pendingRefundCount: 3,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('활성 이벤트 1건'), findsOneWidget);
      expect(find.text('미정산 건 2건'), findsOneWidget);
      expect(find.text('환불 대기 건 3건'), findsOneWidget);

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);

      await tester.tap(find.text('정산 페이지로 이동'));
      verify(() => coordinator.goToSettlement()).called(1);
    },
  );

  testWidgets('enables submit when no blockers exist', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        guard: const PartnerAccountDeletionGuard(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('탈퇴 요청을 진행할 수 있어요'), findsOneWidget);

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
  });
}
