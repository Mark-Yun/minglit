import 'package:minglit_kit/src/data/models/user_consent.dart';
import 'package:minglit_kit/src/data/repositories/auth_repository.dart';
import 'package:minglit_kit/src/data/repositories/consent_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'consent_controller.g.dart';

/// Manages user consent state for the current user.
///
/// Loads active consents on build, provides methods to save
/// signup consents and toggle individual consents.
@riverpod
class ConsentController extends _$ConsentController {
  /// Loads the current user's active consents.
  @override
  FutureOr<List<UserConsent>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];

    final repository = ref.watch(consentRepositoryProvider);
    return repository.getConsents(user.id);
  }

  /// Saves signup consents for the given consent types.
  ///
  /// All specified types are saved as `consented: true` with
  /// the given [policyVersion].
  Future<void> saveSignupConsents(
    List<ConsentType> types, {
    int? policyVersion,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    state = const AsyncLoading();

    try {
      final repository = ref.read(consentRepositoryProvider);
      final consents = types
          .map(
            (type) => ConsentInput(
              consentKey: type,
              consented: true,
              policyVersion: policyVersion,
            ),
          )
          .toList();

      await repository.saveConsents(user.id, consents);

      // Reload from server to get the full records
      final updated = await repository.getConsents(user.id);
      state = AsyncData(updated);

      ref.invalidate(hasRequiredConsentsProvider);
    } on Object catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Toggles a single consent on or off.
  ///
  /// Used from the settings/privacy page to manage individual consents.
  Future<void> toggleConsent(
    ConsentType type, {
    required bool consented,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final repository = ref.read(consentRepositoryProvider);
      final input = ConsentInput(consentKey: type, consented: consented);
      await repository.saveConsents(user.id, [input]);

      // Reload from server
      final updated = await repository.getConsents(user.id);
      state = AsyncData(updated);

      ref.invalidate(hasRequiredConsentsProvider);
    } on Object catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// Provider that checks if the current user has all required consents.
///
/// Used by the route guard to decide whether to redirect to the
/// consent screen.
@riverpod
Future<bool> hasRequiredConsents(Ref ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;

  final repository = ref.watch(consentRepositoryProvider);
  return repository.hasRequiredConsents();
}
