import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:minglit_kit/src/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_repository.g.dart';

/// Configuration for AuthRepository.
class AuthConfig {
  /// Creates an [AuthConfig] with optional client settings.
  const AuthConfig({
    this.webClientId,
    this.defaultRedirectUrl,
    this.mobileRedirectScheme,
  });

  /// OAuth client ID used for web sign-in.
  final String? webClientId;

  /// Default redirect URL for OAuth flows.
  final String? defaultRedirectUrl;

  /// Mobile deep link scheme for OAuth callbacks (e.g., 'com.minglit.app_user').
  final String? mobileRedirectScheme;
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
    mobileRedirectScheme: config.mobileRedirectScheme,
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
    String? mobileRedirectScheme,
  }) : _supabase = supabase ?? Supabase.instance.client,
       _defaultRedirectUrl = defaultRedirectUrl,
       _mobileRedirectScheme = mobileRedirectScheme,
       _googleSignIn = GoogleSignIn(
         clientId: kIsWeb ? webClientId : null,
         serverClientId: kIsWeb ? null : webClientId,
       );

  final SupabaseClient _supabase;
  final GoogleSignIn _googleSignIn;
  final String? _defaultRedirectUrl;
  final String? _mobileRedirectScheme;

  /// Returns the current logged-in user.
  User? get currentUser => _supabase.auth.currentUser;

  /// Stream of authentication state changes.
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;

  /// Initiates Google Sign-In process.
  Future<void> signInWithGoogle({String? redirectTo}) async {
    Log.d('🔐 [AuthRepo] Google Sign-In started (Web=$kIsWeb)');
    try {
      if (kIsWeb) {
        final targetRedirect =
            redirectTo ?? _defaultRedirectUrl ?? Uri.base.origin;
        Log.d('🌐 [AuthRepo] OAuth redirect to: $targetRedirect');

        await _supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: targetRedirect,
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

  /// Initiates Apple Sign-In process.
  Future<void> signInWithApple({String? redirectTo}) async {
    Log.d('🍎 [AuthRepo] Apple Sign-In started (Web=$kIsWeb)');
    try {
      if (kIsWeb) {
        final targetRedirect =
            redirectTo ?? _defaultRedirectUrl ?? Uri.base.origin;
        Log.d('🌐 [AuthRepo] Apple OAuth redirect to: $targetRedirect');
        await _supabase.auth.signInWithOAuth(
          OAuthProvider.apple,
          redirectTo: targetRedirect,
        );
        return;
      }

      final isAppleNative =
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS;

      if (!isAppleNative) {
        throw const AuthException(
          'Apple sign-in is supported on iOS/macOS and web only.',
        );
      }

      final rawNonce = _supabase.auth.generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const AuthException('No ID Token found from Apple.');
      }

      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      if (credential.givenName != null || credential.familyName != null) {
        final nameParts = <String>[];
        if (credential.givenName != null) {
          nameParts.add(credential.givenName!);
        }
        if (credential.familyName != null) {
          nameParts.add(credential.familyName!);
        }

        await _supabase.auth.updateUser(
          UserAttributes(
            data: {
              'full_name': nameParts.join(' '),
              'given_name': credential.givenName ?? '',
              'family_name': credential.familyName ?? '',
            },
          ),
        );
      }

      Log.i('🎉 [AuthRepo] Apple Sign-In successful!');
    } on Exception catch (e, stackTrace) {
      Log.e('❌ [AuthRepo] Apple Sign-In Error', e, stackTrace);
      rethrow;
    }
  }

  /// Initiates Kakao Sign-In process via web OAuth redirect.
  ///
  /// Uses `signInWithOAuth` on all platforms to avoid audience mismatch
  /// issues with native Kakao SDK tokens.
  Future<void> signInWithKakao({String? redirectTo}) async {
    Log.d('🟡 [AuthRepo] Kakao Sign-In started');
    try {
      final targetRedirect =
          redirectTo ??
          (kIsWeb
              ? (_defaultRedirectUrl ?? Uri.base.origin)
              : (_mobileRedirectScheme != null
                    ? '$_mobileRedirectScheme://callback'
                    : null));
      Log.d('🌐 [AuthRepo] Kakao OAuth redirect to: $targetRedirect');

      await _supabase.auth.signInWithOAuth(
        OAuthProvider.kakao,
        redirectTo: targetRedirect,
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );
    } on Exception catch (e, stackTrace) {
      Log.e('❌ [AuthRepo] Kakao Sign-In Error', e, stackTrace);
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

  /// **Dev/Test**: Sign in with Email and Password.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    Log.d('🔐 [AuthRepo] Email Sign-In started: $email');
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      Log.i('🎉 [AuthRepo] Email Sign-In successful!');
    } on Exception catch (e, stackTrace) {
      Log.e('❌ [AuthRepo] Email Sign-In Error', e, stackTrace);
      rethrow;
    }
  }
}
