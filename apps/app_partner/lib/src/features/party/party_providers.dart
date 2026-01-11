import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'party_providers.g.dart';

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

@riverpod
Future<List<Verification>> partyVerificationTypes(Ref ref) async {
  final repo = ref.watch(verificationRepositoryProvider);

  // 1. Fetch Global Verifications (System Defaults)
  final globalVerifications = await repo.getGlobalVerifications();

  // 2. Fetch Partner Specific Verifications
  final partner = await ref.watch(currentPartnerInfoProvider.future);
  if (partner != null) {
    final partnerVerifications = await repo.getPartnerVerifications(partner.id);
    // Return combined list
    return [...globalVerifications, ...partnerVerifications];
  }

  return globalVerifications;
}
