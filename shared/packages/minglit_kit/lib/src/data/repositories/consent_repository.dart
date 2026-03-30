import 'package:minglit_kit/src/data/models/user_consent.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'consent_repository.g.dart';

/// Provides the [ConsentRepository].
@Riverpod(keepAlive: true)
ConsentRepository consentRepository(Ref ref) {
  return ConsentRepository(Supabase.instance.client);
}

/// Repository for user consent data from Supabase.
///
/// Reads use direct table queries (SELECT-only RLS).
/// Writes use the `save_user_consents` SECURITY DEFINER RPC.
class ConsentRepository {
  /// Creates a [ConsentRepository] with the given Supabase client.
  const ConsentRepository(this._supabase);

  final SupabaseClient _supabase;

  /// Fetches active consents for the given [userId].
  ///
  /// Returns only rows where `consented = true` (active consents).
  Future<List<UserConsent>> getConsents(String userId) async {
    try {
      final data = await _supabase
          .from('user_consents')
          .select()
          .eq('user_id', userId)
          .eq('consented', true);
      return (data as List)
          .map(
            (dynamic e) =>
                UserConsent.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } on Object {
      return [];
    }
  }

  /// Saves consents via the `save_user_consents` RPC.
  ///
  /// Each [ConsentInput] is upserted: existing rows are updated,
  /// new rows are inserted. Uses ON CONFLICT (user_id, consent_key).
  Future<void> saveConsents(
    String userId,
    List<ConsentInput> consents,
  ) async {
    final payload = consents.map((c) => c.toJson()).toList();
    await _supabase.rpc<void>(
      'save_user_consents',
      params: {
        'p_user_id': userId,
        'p_consents': payload,
      },
    );
  }

  /// Checks whether the user has all required consents.
  ///
  /// Calls the `has_required_consents()` RPC which checks for
  /// terms_of_service, privacy_collection, and age_confirmation.
  Future<bool> hasRequiredConsents() async {
    try {
      final result = await _supabase.rpc<bool>('has_required_consents');
      return result;
    } on Object {
      return false;
    }
  }
}
