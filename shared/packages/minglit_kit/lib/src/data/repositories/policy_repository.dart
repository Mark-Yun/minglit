import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'policy_repository.g.dart';

@Riverpod(keepAlive: true)
PolicyRepository policyRepository(Ref ref) {
  return PolicyRepository(Supabase.instance.client);
}

class PolicyRepository {
  const PolicyRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<Map<String, dynamic>?> getRefundPolicy() async {
    final result = await _supabase.rpc(
      'get_current_policy',
      params: {'p_key': 'refund'},
    );
    if (result == null) return null;
    return result as Map<String, dynamic>;
  }
}
