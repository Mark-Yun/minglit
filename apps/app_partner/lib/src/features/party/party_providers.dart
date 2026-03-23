import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:app_partner/src/logic/current_partner_provider.dart';

part 'party_providers.g.dart';

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
