import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'consent_providers.g.dart';

/// Whether the current user has completed all required consents.
///
/// keepAlive so the value is cached app-wide and only re-fetched on
/// explicit invalidation (e.g. after saving consents).
@Riverpod(keepAlive: true)
class HasRequiredConsents extends _$HasRequiredConsents {
  @override
  Future<bool> build() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    final repo = ref.watch(consentRepositoryProvider);
    return repo.hasRequiredConsents();
  }
}
