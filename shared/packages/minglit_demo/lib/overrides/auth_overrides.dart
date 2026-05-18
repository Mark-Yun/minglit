/// Auth-domain provider overrides for demo flavor.
///
/// Owned by **P1-1 agent**. See task #11.
///
/// Each `_Demo*` class extends the real concrete Repository, passes
/// [PoisonSupabaseClient] to `super(...)`, and overrides only the methods
/// exercised in the demo flow. Unoverridden methods inherit from the parent
/// and will throw via [PoisonSupabaseClient] — intentional loud failure that
/// surfaces missing coverage.
library;

// ignore: implementation_imports
import 'package:riverpod/src/internals.dart' show Override;
import 'package:minglit_kit/minglit_data.dart';

import '../fixtures/demo_users.dart';
import 'poison_supabase_client.dart';

// ── Fake AuthRepository ───────────────────────────────────────────────────────

class _DemoAuthRepository extends AuthRepository {
  _DemoAuthRepository()
    : super(
        supabase: const PoisonSupabaseClient(),
        // Blank strings: demo never initiates real OAuth flows.
        webClientId: '',
        defaultRedirectUrl: '',
        mobileRedirectScheme: '',
      );

  @override
  User? get currentUser => demoUser;

  /// No-op: demo is always "signed in" — sign-out is a dead end.
  @override
  Future<void> signOut() async {
    // Demo: no auth state to clear. Return immediately.
  }

  /// Instant success: demo user is always logged in via Kakao.
  /// Returns without touching Supabase.
  @override
  Future<void> signInWithKakao({String? redirectTo}) async {
    // Demo: already signed in as demoUser, nothing to do.
  }

  /// Instant success: no Google SDK call in demo.
  @override
  Future<void> signInWithGoogle({String? redirectTo}) async {
    // Demo: already signed in as demoUser, nothing to do.
  }

  /// Instant success: no Apple SDK call in demo.
  @override
  Future<void> signInWithApple({String? redirectTo}) async {
    // Demo: already signed in as demoUser, nothing to do.
  }
}

// ── Fake AccountRepository ────────────────────────────────────────────────────

class _DemoAccountRepository extends AccountRepository {
  const _DemoAccountRepository() : super(const PoisonSupabaseClient());

  /// Demo user has no pending deletion — return null (account healthy).
  @override
  Future<DeletionStatus?> getDeletionStatus() async => null;

  /// No-op reauthenticate — demo has no password or social session.
  @override
  Future<void> reauthenticate(String? password) async {
    // Demo: always authenticated, nothing to do.
  }

  // deleteAccount / cancelDeletion intentionally NOT overridden —
  // touching them in demo is unexpected and should throw via PoisonSupabaseClient.
}

// ── Fake ConsentRepository ────────────────────────────────────────────────────

class _DemoConsentRepository extends ConsentRepository {
  const _DemoConsentRepository() : super(const PoisonSupabaseClient());

  /// Returns the pre-built demo consent list from fixtures.
  @override
  Future<List<UserConsent>> getConsents(String userId) async =>
      demoUserConsents;

  /// Demo user has all required consents — always returns true.
  @override
  Future<bool> hasRequiredConsents() async => true;

  /// No-op: demo consents are fixed in-memory fixtures.
  @override
  Future<void> saveConsents(String userId, List<ConsentInput> consents) async {
    // Demo: in-memory only, no persistence.
  }
}

// ── Fake UserRepository ───────────────────────────────────────────────────────

class _DemoUserRepository extends SupabaseUserRepository {
  _DemoUserRepository() : super(supabase: const PoisonSupabaseClient());

  /// Returns the pre-built demo profile from fixtures.
  @override
  Future<UserProfile?> getUserProfile(String userId) async =>
      demoUserProfile;

  /// Demo user has no partner verification IDs — return empty list.
  ///
  // TODO(P6): populate with realistic verification IDs once partner fixtures
  // are defined (P1-4 agent scope).
  @override
  Future<List<String>> getApprovedVerificationIds(String userId) async => [];
}

// ── Domain-level overrides composer ──────────────────────────────────────────

/// Returns the ProviderScope override list for the auth/user domain.
///
/// Imported and spread by [demoOverrides()] in demo_overrides.dart (P1-5).
///
List<Override> authDomainOverrides() => [
  // Pin the current user to demoUser so every guard/redirect sees a logged-in
  // user without touching Supabase.
  currentUserProvider.overrideWith((_) => demoUser),

  // Repository overrides — each backed by a Fake that serves fixture data.
  authRepositoryProvider.overrideWith((_) => _DemoAuthRepository()),
  accountRepositoryProvider.overrideWith((_) => const _DemoAccountRepository()),
  consentRepositoryProvider.overrideWith((_) => const _DemoConsentRepository()),
  userRepositoryProvider.overrideWith((_) => _DemoUserRepository()),
];
