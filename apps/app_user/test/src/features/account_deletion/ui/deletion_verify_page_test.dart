import 'package:app_user/src/features/account_deletion/ui/deletion_verify_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('이메일 로그인 유저에게 비밀번호 입력 필드를 표시한다', (
    tester,
  ) async {
    final user = MockUser();
    when(() => user.appMetadata).thenReturn(const {'provider': 'email'});
    when(() => user.identities).thenReturn(const []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => user),
          accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
        ],
        child: MaterialApp(
          theme: MinglitTheme.materialTheme,
          home: const DeletionVerifyPage(reasonCode: 'privacy_concern'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('비밀번호'), findsOneWidget);
    expect(find.text('탈퇴 요청'), findsOneWidget);
  });
}

class MockUser extends Mock implements User {}

class _FakeAccountRepository extends AccountRepository {
  _FakeAccountRepository() : super(MockSupabaseClient());

  @override
  Future<DeletionStatus?> getDeletionStatus() async => null;

  @override
  Future<void> reauthenticate(String? password) async {}

  @override
  Future<DeletionStatus> deleteAccount(WithdrawalReason? reason) async =>
      DeletionStatus.fromDeletedAt(DateTime(2026, 3, 31));
}

class MockSupabaseClient extends Mock implements SupabaseClient {}
