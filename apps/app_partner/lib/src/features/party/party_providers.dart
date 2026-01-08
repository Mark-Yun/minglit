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
  // Assuming getGlobalVerifications exists
  return repo.getGlobalVerifications();
}
