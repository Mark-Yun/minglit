// DeletionVerifyPageBuilder — deletion_verify_page 전용 fluent API.
//
// DeletionVerifyPage 는 currentUserProvider 와 accountDeletionControllerProvider
// 를 watch 한다. currentUserProvider 가 null 이면 SizedBox.shrink() 를 반환하므로
// 렌더 catalog 에서는 반드시 mock User 를 주입한다.
//
// _commonRootOverrides() 의 currentUserProvider(null) 은 state override 에서
// 덮어쓴다 (Riverpod: 뒤에 오는 override 가 우선).

import 'package:app_user/src/features/account_deletion/ui/deletion_verify_page.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../_engine/builder.dart';

class _MockUser extends Mock implements User {}

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _FakeAccountRepository extends AccountRepository {
  _FakeAccountRepository() : super(_MockSupabaseClient());

  @override
  Future<DeletionStatus?> getDeletionStatus() async => null;

  @override
  Future<void> reauthenticate(String? password) async {}

  @override
  Future<DeletionStatus> deleteAccount(WithdrawalReason? reason) async =>
      DeletionStatus.fromDeletedAt(DateTime(2026, 3, 31));
}

User _makeEmailUser() {
  final user = _MockUser();
  when(() => user.appMetadata).thenReturn(const {'provider': 'email'});
  when(() => user.identities).thenReturn(const []);
  return user;
}

User _makeSocialUser() {
  final user = _MockUser();
  when(() => user.appMetadata).thenReturn(const {'provider': 'google'});
  when(() => user.identities).thenReturn(const []);
  return user;
}

class DeletionVerifyPageBuilder extends MdsScreenBuilder<DeletionVerifyPage> {
  DeletionVerifyPageBuilder()
    : super(
        page: const DeletionVerifyPage(reasonCode: 'privacy_concern'),
        base: [
          accountRepositoryProvider.overrideWithValue(
            _FakeAccountRepository(),
          ),
        ],
      );

  /// 이메일(비밀번호) 로그인 유저 — 비밀번호 입력 필드 노출.
  DeletionVerifyPageBuilder asEmailUser() {
    addOverride(currentUserProvider.overrideWith((_) => _makeEmailUser()));
    return this;
  }

  /// 소셜 로그인 유저 — 재인증 안내 카드 노출.
  DeletionVerifyPageBuilder asSocialUser() {
    addOverride(currentUserProvider.overrideWith((_) => _makeSocialUser()));
    return this;
  }

  /// 탈퇴 사유 없이 진입.
  DeletionVerifyPageBuilder withNoReason() {
    return this;
  }

  /// 다크 모드 토글.
  DeletionVerifyPageBuilder dark() {
    useDarkTheme();
    return this;
  }
}
