import 'package:minglit_kit/src/utils/exceptions.dart';
import 'package:minglit_kit/src/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'identity_repository.g.dart';

/// **Identity Repository**
///
/// Handles Identity Verification (PASS/SMS) to verify user's real name,
/// birth date, and gender. This is the "Base Layer" of trust.
class IdentityRepository {
  IdentityRepository(this._supabase);

  final SupabaseClient _supabase;

  /// Verifies user identity using the Edge Function which interacts
  /// with Iamport V1.
  Future<void> verifyIdentity({
    required String identityVerificationId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw const MinglitAuthException('User not logged in');

    try {
      Log.d('Calling verify-identity-v1 edge function...');

      final response = await _supabase.functions.invoke(
        'verify-identity-v1',
        body: {'identity_verification_id': identityVerificationId},
      );

      if (response.status != 200) {
        throw MinglitUserException('인증 검증 실패: ${response.data}');
      }

      Log.d('✅ Identity Verified successfully via Edge Function.');
    } on Object catch (e, st) {
      Log.e('❌ [IdentityRepo] verifyIdentity Error', e, st);
      // Use handleMinglitError or rethrow a concrete exception
      rethrow;
    }
  }

  /// Checks if the current user is identity-verified.
  Future<bool> isVerified() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final data = await _supabase
          .from('user_profiles')
          .select('is_verified')
          .eq('id', user.id)
          .single();
      return data['is_verified'] as bool? ?? false;
    } on Object catch (_) {
      return false;
    }
  }
}

@riverpod
IdentityRepository identityRepository(Ref ref) {
  return IdentityRepository(Supabase.instance.client);
}
