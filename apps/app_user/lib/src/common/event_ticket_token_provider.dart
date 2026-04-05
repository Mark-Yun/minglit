import 'package:app_user/src/features/ticket/data/ticket_wallet_repository.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Fetches the user's [TicketToken] for a given event by scanning the
/// local ticket wallet.
///
/// Returns `null` if no matching token is found (e.g., not yet minted).
// ignore: specify_nonobvious_property_types, Reason: Type is inferred correctly by FutureProvider.family
final eventTicketTokenProvider = FutureProvider.family<TicketToken?, String>((
  ref,
  eventId,
) async {
  final wallet = ref.watch(ticketWalletRepositoryProvider);
  final ids = await wallet.listAllTicketIds();

  for (final id in ids) {
    final token = await wallet.getTicket(id);
    if (token != null && token.eventId == eventId) {
      return token;
    }
  }
  return null;
});
