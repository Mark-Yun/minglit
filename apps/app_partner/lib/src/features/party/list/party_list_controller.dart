import 'package:app_partner/src/features/party/list/party_with_stats.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'party_list_controller.g.dart';

@riverpod
Future<List<PartyWithStats>> partyList(Ref ref) async {
  final partnerRepo = ref.watch(partnerRepositoryProvider);
  final myPartners = await partnerRepo.getMyManagedPartners();

  if (myPartners.isEmpty) return [];

  final partnerId = myPartners.first.id;
  final partyRepo = ref.watch(partyRepositoryProvider);

  final parties = await partyRepo.getPartiesByPartnerId(partnerId);
  if (parties.isEmpty) return [];

  // Parallel-fetch events for every party, then aggregate stats client-side.
  // Typical partner has < 15 parties so N concurrent queries is acceptable.
  final eventLists = await Future.wait(
    parties.map((p) => partyRepo.getEventsByPartyId(p.id)),
  );

  final now = DateTime.now();
  return List.generate(parties.length, (i) {
    final party = parties[i];
    final events = eventLists[i];

    final completedCount = events.where((e) => e.status == 'completed').length;
    final upcoming =
        events
            .where(
              (e) =>
                  (e.status == 'scheduled' || e.status == 'active') &&
                  e.startTime.isAfter(now),
            )
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return PartyWithStats(
      party: party,
      completedCount: completedCount,
      upcomingCount: upcoming.length,
      nextEvent: upcoming.isEmpty ? null : upcoming.first,
    );
  });
}
