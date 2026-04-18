import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'current_partner_provider.g.dart';

@riverpod
Future<Partner?> currentPartnerInfo(Ref ref) async {
  final authState = ref.watch(authStateChangesProvider).value;
  final user = authState?.session?.user;
  if (user == null) return null;

  final repo = ref.watch(partnerRepositoryProvider);
  // Fetch managed partners and return the first one as current context
  final partners = await repo.getMyManagedPartners();
  return partners.isNotEmpty ? partners.first : null;
}

/// Returns the current user's permission list for the active partner.
/// Empty list when partner or auth state is unavailable.
@riverpod
Future<List<String>> currentMemberPermissions(Ref ref) async {
  final partner = await ref.watch(currentPartnerInfoProvider.future);
  if (partner == null) return [];

  final repo = ref.watch(partnerRepositoryProvider);
  final memberRole = await repo.getMyMemberRole(partner.id);
  if (memberRole == null) return [];

  return List<String>.from(
    memberRole['permissions'] as Iterable<dynamic>? ?? [],
  );
}
