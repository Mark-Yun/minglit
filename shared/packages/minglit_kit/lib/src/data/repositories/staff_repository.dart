import 'package:minglit_kit/src/config/url_config.dart';
import 'package:minglit_kit/src/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'staff_repository.g.dart';

@Riverpod(keepAlive: true)
StaffRepository staffRepository(Ref ref) {
  final urlConfig = ref.watch(minglitUrlConfigProvider);
  return StaffRepository(
    redirectUrl: urlConfig.authRedirectUrl,
  );
}

class StaffRepository {
  StaffRepository({SupabaseClient? supabase, String? redirectUrl})
    : _supabase = supabase ?? Supabase.instance.client,
      _redirectUrl = redirectUrl;
  static const _staffTokenKey = 'minglit_staff_proof_token';

  final SupabaseClient _supabase;
  final String? _redirectUrl;

  /// Saves the provided JWT as a permanent staff proof.
  Future<void> saveStaffToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_staffTokenKey, token);
    Log.i('🛡️ [StaffRepo] Staff proof token saved locally.');
  }

  /// Clears the staff proof token (e.g., for re-authentication).
  Future<void> clearStaffToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_staffTokenKey);
    Log.i('🛡️ [StaffRepo] Staff proof token cleared.');
  }

  /// Verifies the stored token against Supabase server.
  /// Returns the staff user if valid and email matches @minglit.com.
  Future<User?> verifyStaffStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_staffTokenKey);

    if (token == null) {
      Log.d('🛡️ [StaffRepo] No staff token found locally.');
      return null;
    }

    try {
      // Use Supabase Admin API behavior: getUser(token) validates the JWT
      // and returns the associated user data.
      final response = await _supabase.auth.getUser(token);
      final user = response.user;

      if (user != null &&
          user.email != null &&
          user.email!.endsWith('@minglit.com')) {
        Log.i('🛡️ [StaffRepo] Staff verification successful: ${user.email}');
        return user;
      }

      Log.w('🛡️ [StaffRepo] Token valid but email domain is unauthorized.');
      await clearStaffToken();
      return null;
    } on Object catch (e) {
      Log.e('🛡️ [StaffRepo] Token verification failed or expired: $e');
      await clearStaffToken();
      return null;
    }
  }

  /// Sends a Magic Link (OTP) to the staff email.
  Future<void> sendMagicLink(String email) async {
    if (!email.endsWith('@minglit.com')) {
      throw const AuthException('오직 @minglit.com 계정만 인증할 수 있습니다.');
    }

    Log.d('🛡️ [StaffRepo] Sending Magic Link to $email');
    
    // Normalize URL: Remove trailing slash to match exact redirect URL registration
    final redirectTo = _redirectUrl != null && _redirectUrl!.endsWith('/')
        ? _redirectUrl!.substring(0, _redirectUrl!.length - 1)
        : _redirectUrl;

    Log.d('🛡️ [StaffRepo] Magic Link redirect URL: $redirectTo');

    await _supabase.auth.signInWithOtp(
      email: email,
      emailRedirectTo: redirectTo,
    );
  }
}
