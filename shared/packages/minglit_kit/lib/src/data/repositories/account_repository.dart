import 'package:minglit_kit/src/data/models/deletion_status.dart';
import 'package:minglit_kit/src/data/models/withdrawal_reason.dart';
import 'package:minglit_kit/src/utils/exceptions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'account_repository.g.dart';

const _deletionGracePeriod = Duration(days: 7);

/// Provides the [AccountRepository].
@Riverpod(keepAlive: true)
AccountRepository accountRepository(Ref ref) {
  return AccountRepository(Supabase.instance.client);
}

/// Shared repository for account deletion and restoration flows.
class AccountRepository {
  /// Creates an [AccountRepository] with the given Supabase client.
  const AccountRepository(this._supabase);

  final SupabaseClient _supabase;

  /// Requests account deletion and returns the pending deletion status.
  Future<DeletionStatus> deleteAccount(WithdrawalReason? reason) async {
    try {
      final response = await _supabase.functions.invoke(
        'user-delete-account',
        body: {
          if (reason != null) ...reason.toJson(),
        },
      );

      if (response.status != 200) {
        throw _efError(response, '탈퇴 요청에 실패했습니다.');
      }

      final data = _decodeMap(response.data);
      final gracePeriodEnds = _parseDateTime(data['grace_period_ends']);
      return DeletionStatus(
        deletedAt: gracePeriodEnds?.subtract(_deletionGracePeriod),
        gracePeriodEnds: gracePeriodEnds,
        isPending: true,
      );
    } on Object catch (error, stackTrace) {
      throw MinglitException.from(error, stackTrace);
    }
  }

  /// Cancels a pending deletion request.
  Future<void> cancelDeletion() async {
    try {
      final response = await _supabase.functions.invoke('user-cancel-deletion');
      if (response.status != 200) {
        throw _efError(response, '탈퇴 취소에 실패했습니다.');
      }
    } on Object catch (error, stackTrace) {
      throw MinglitException.from(error, stackTrace);
    }
  }

  /// Fetches the current signed-in user's deletion status.
  Future<DeletionStatus?> getDeletionStatus() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const MinglitAuthException('로그인이 필요합니다.');
    }

    try {
      final data = await _supabase
          .from('user_profiles')
          .select('deleted_at')
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) return null;

      final deletedAt = _parseDateTime(data['deleted_at']);
      return DeletionStatus.fromDeletedAt(deletedAt);
    } on Object catch (error, stackTrace) {
      throw MinglitException.from(error, stackTrace);
    }
  }

  /// Performs a reauthentication step before deletion.
  ///
  /// Email users must pass [password]. Social users trigger Supabase
  /// reauthentication which continues in the provider-specific flow.
  Future<void> reauthenticate(String? password) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const MinglitAuthException('로그인이 필요합니다.');
    }

    try {
      if (_usesPasswordAuth(user)) {
        final email = user.email;
        if (email == null || email.isEmpty) {
          throw const MinglitAuthException('이메일 계정을 확인할 수 없습니다.');
        }
        if (password == null || password.isEmpty) {
          throw const MinglitUserException('비밀번호를 입력해주세요.');
        }

        await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        return;
      }

      await _supabase.auth.reauthenticate();
    } on Object catch (error, stackTrace) {
      throw MinglitException.from(error, stackTrace);
    }
  }

  bool _usesPasswordAuth(User user) {
    final hasPassword = user.appMetadata['has_password'];
    if (hasPassword is bool) {
      return hasPassword;
    }

    if (hasPassword is String) {
      return hasPassword.toLowerCase() == 'true';
    }
    return false;
  }

  MinglitUserException _efError(FunctionResponse response, String fallback) {
    final data = response.data;
    if (data is Map) {
      final message = (data['error'] as String?) ?? fallback;
      return MinglitUserException(message);
    }
    if (data is String && data.isNotEmpty) {
      return MinglitUserException(data);
    }
    return MinglitUserException(fallback);
  }

  Map<String, dynamic> _decodeMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return const <String, dynamic>{};
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
