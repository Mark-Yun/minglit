import 'package:minglit_kit/src/data/repositories/staff_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'staff_guard_provider.g.dart';

@Riverpod(keepAlive: true)
class StaffGuard extends _$StaffGuard {
  @override
  FutureOr<User?> build() async {
    // Check local storage and verify with server on app startup
    return ref.read(staffRepositoryProvider).verifyStaffStatus();
  }

  Future<void> requestMagicLink(String email) async {
    await ref.read(staffRepositoryProvider).sendMagicLink(email);
  }

  /// Called after successful Magic Link login to persist the "staff proof"
  Future<void> setVerified(Session session) async {
    if (session.user.email?.endsWith('@minglit.com') ?? false) {
      await ref
          .read(staffRepositoryProvider)
          .saveStaffToken(session.accessToken);
      state = AsyncData(session.user);
    }
  }

  Future<void> reset() async {
    await ref.read(staffRepositoryProvider).clearStaffToken();
    state = const AsyncData(null);
  }
}
