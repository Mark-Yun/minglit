import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ticket_data_providers.g.dart';

/// Fetches entry groups for a party — ticket-local provider to avoid
/// importing party feature controllers.
@riverpod
Future<List<PartyEntryGroup>> ticketEntryGroups(
  Ref ref,
  String partyId,
) async {
  final repo = ref.watch(partyRepositoryProvider);
  final party = await repo.getPartyById(partyId);
  return party?.entryGroups ?? [];
}

/// Fetches ticket templates by party ID — ticket-local provider
/// (mirrors partyTicketsProvider from party feature).
@riverpod
Future<List<TicketTemplate>> ticketTemplatesByParty(
  Ref ref,
  String partyId,
) async {
  final repo = ref.watch(ticketRepositoryProvider);
  return repo.getTicketTemplatesByPartyId(partyId);
}

/// Fetches tickets by event ID — ticket-local provider
/// (mirrors eventTicketsProvider from party/event feature).
@riverpod
Future<List<Ticket>> ticketsByEvent(Ref ref, String eventId) async {
  final repo = ref.watch(ticketRepositoryProvider);
  return repo.getTicketsByEventId(eventId);
}
