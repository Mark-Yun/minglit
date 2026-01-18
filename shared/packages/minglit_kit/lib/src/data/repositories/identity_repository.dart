import 'package:minglit_kit/minglit_kit.dart';
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

  /// Verifies user identity using mock data for now.
  ///
  /// In the future, this will integrate with PASS/SMS verification providers.
  Future<void> verifyIdentity({
    required String name,
    required DateTime birthDate,
    required String gender, // 'male' or 'female'
    required String phoneNumber,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw const MinglitAuthException('User not logged in');

    // TODO(identity_verification_integration_20260117): Integrate with real PASS/SMS API provider here.
    // 1. Send request to provider
    // 2. Receive CI/DI and verified info

    // For now, we simulate a successful verification by directly updating
    // the profile.
    try {
      await _supabase
          .from('user_profiles')
          .update({
            'name': name,
            'birth_date': birthDate.toIso8601String().split(
              'T',
            )[0], // YYYY-MM-DD
            'gender': gender,
            'phone_number': phoneNumber,
            'is_verified': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      Log.d('✅ Identity Verified for user: ${user.id}');
    } on PostgrestException catch (e, st) {
      throw MinglitException.from(e, st);
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
