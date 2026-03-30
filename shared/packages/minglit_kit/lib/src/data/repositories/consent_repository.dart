import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'consent_repository.g.dart';

/// Provides a [ConsentRepository] instance.
@Riverpod(keepAlive: true)
ConsentRepository consentRepository(Ref ref) {
  return ConsentRepository(Supabase.instance.client);
}

/// Repository for managing user consent state via Supabase.
class ConsentRepository {
  /// Creates a [ConsentRepository] with the given Supabase client.
  const ConsentRepository(this._supabase);

  final SupabaseClient _supabase;

  /// Checks whether the current user has completed all required consents.
  ///
  /// Calls the `has_required_consents()` RPC function which verifies that
  /// the user has consented to: terms_of_service, privacy_collection,
  /// and age_confirmation.
  Future<bool> hasRequiredConsents() async {
    final result = await _supabase.rpc<bool>('has_required_consents');
    return result;
  }
}
