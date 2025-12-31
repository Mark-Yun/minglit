import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'party_list_controller.g.dart';

@riverpod
Future<List<Party>> partyList(Ref ref) async {
  final partnerRepo = ref.watch(partnerRepositoryProvider);
  final myPartners = await partnerRepo.getMyManagedPartners();

  if (myPartners.isEmpty) return [];

  final partnerId = myPartners.first.id;
  final partyRepo = ref.watch(partyRepositoryProvider);

  return partyRepo.getPartiesByPartnerId(partnerId);
}
