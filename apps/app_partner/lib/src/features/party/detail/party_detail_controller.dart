import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'party_detail_controller.g.dart';

@riverpod
Future<Party> partyDetail(Ref ref, String partyId) async {
  final repo = ref.watch(partyRepositoryProvider);
  return repo.getPartyById(partyId);
}

@riverpod
Future<List<Event>> partyEvents(Ref ref, String partyId) async {
  final repo = ref.watch(partyRepositoryProvider);
  return repo.getEventsByPartyId(partyId);
}

@riverpod
Future<List<Ticket>> partyTickets(Ref ref, String partyId) async {
  final repo = ref.watch(ticketRepositoryProvider);
  return repo.getTicketsByPartyId(partyId);
}

@riverpod
Future<Location?> locationDetail(Ref ref, String? locationId) async {
  if (locationId == null || locationId.isEmpty) return null;
  final repo = ref.watch(locationRepositoryProvider);
  return repo.getLocationById(locationId);
}

@riverpod
Future<List<Verification>> partyVerifications(Ref ref, String partyId) async {
  final party = await ref.watch(partyDetailProvider(partyId).future);
  if (party.requiredVerificationIds.isEmpty) return [];

  final repo = ref.watch(verificationRepositoryProvider);
  return repo.getVerificationsByIds(party.requiredVerificationIds);
}
