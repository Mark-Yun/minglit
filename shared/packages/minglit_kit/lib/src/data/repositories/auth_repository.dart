import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:minglit_kit/src/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_repository.g.dart';

/// Configuration for AuthRepository.
class AuthConfig {
  const AuthConfig({this.webClientId, this.defaultRedirectUrl});
  final String? webClientId;
  final String? defaultRedirectUrl;
}

/// Provider for AuthConfig. Must be overridden in main.dart.
@Riverpod(keepAlive: true)
AuthConfig authConfig(Ref ref) {
  throw UnimplementedError('AuthConfig must be overridden via ProviderScope');
}

/// Provider for the AuthRepository instance.
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  final config = ref.watch(authConfigProvider);
  return AuthRepository(
    webClientId: config.webClientId,
    defaultRedirectUrl: config.defaultRedirectUrl,
  );
}

/// Provider for authentication state changes stream.
@Riverpod(keepAlive: true)
Stream<AuthState> authStateChanges(Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.onAuthStateChange;
}

/// Provider for the current user. Updates automatically on auth state change.
@Riverpod(keepAlive: true)
User? currentUser(Ref ref) {
  // Listen to auth state changes to update this provider
  ref.watch(authStateChangesProvider);
  return ref.watch(authRepositoryProvider).currentUser;
}

/// Repository for handling Authentication data sources.
class AuthRepository {
  /// Creates an [AuthRepository] with necessary clients.
  AuthRepository({
    SupabaseClient? supabase,
    String? webClientId,
    String? defaultRedirectUrl,
  }) : _supabase = supabase ?? Supabase.instance.client,
       _defaultRedirectUrl = defaultRedirectUrl,
       _googleSignIn = GoogleSignIn(
         clientId: kIsWeb ? webClientId : null,
       );

  final SupabaseClient _supabase;
  final GoogleSignIn _googleSignIn;
  final String? _defaultRedirectUrl;

  /// Returns the current logged-in user.
  User? get currentUser => _supabase.auth.currentUser;

  /// Stream of authentication state changes.
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;

  /// Initiates Google Sign-In process.
  Future<void> signInWithGoogle() async {
    Log.d('🔐 [AuthRepo] Google Sign-In started (Web=$kIsWeb)');
    try {
      if (kIsWeb) {
        final redirectTo = _defaultRedirectUrl ?? Uri.base.origin;
        Log.d('🌐 [AuthRepo] OAuth redirect to: $redirectTo');

        await _supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: redirectTo,
        );
        return;
      }

      // Mobile Native Sign-In
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException('Google sign-in was cancelled.');
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw const AuthException('No ID Token found from Google.');
      }

      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      Log.i('🎉 [AuthRepo] Supabase Sign-In successful!');
    } on Exception catch (e, stackTrace) {
      Log.e('❌ [AuthRepo] Sign-In Error', e, stackTrace);
      rethrow;
    }
  }

  /// Signs out from both Supabase and Google.
  Future<void> signOut() async {
    try {
      await Future.wait([
        _supabase.auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      Log.i('👋 [AuthRepo] Sign-Out successful');
    } on Exception catch (e, stackTrace) {
      Log.e('❌ [AuthRepo] Sign-Out Error', e, stackTrace);
      rethrow;
    }
  }
}
