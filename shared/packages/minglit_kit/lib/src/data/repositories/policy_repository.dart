import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'policy_repository.g.dart';

/// Provides a [PolicyRepository] instance.
@Riverpod(keepAlive: true)
PolicyRepository policyRepository(Ref ref) {
  return PolicyRepository(Supabase.instance.client);
}

/// Repository for fetching app policy data from Supabase.
class PolicyRepository {
  /// Creates a [PolicyRepository] with the given Supabase client.
  const PolicyRepository(this._supabase);

  final SupabaseClient _supabase;

  /// Fetches the current refund policy. Returns null if not found.
  Future<Map<String, dynamic>?> getRefundPolicy() async {
    final result = await _supabase.rpc<Map<String, dynamic>?>(
      'get_current_policy',
      params: {'p_key': 'refund'},
    );
    if (result == null) return null;
    return result;
  }
}
