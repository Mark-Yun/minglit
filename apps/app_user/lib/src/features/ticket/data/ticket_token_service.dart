import 'package:app_user/src/features/ticket/data/ticket_wallet_repository.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'ticket_token_service.g.dart';

@riverpod
TicketTokenService ticketTokenService(Ref ref) {
  return TicketTokenService(
    wallet: ref.watch(ticketWalletRepositoryProvider),
    supabase: ref.watch(supabaseClientProvider),
  );
}

/// Fetches a [TicketToken] for display on the QR screen.
/// Checks local wallet first; fetches from Edge Function if not found
/// or expired.
///
/// Fix #1206: Fetches token from Edge Function when not in local wallet
class TicketTokenService {
  TicketTokenService({required this.wallet, required SupabaseClient supabase})
      : _supabase = supabase;

  final TicketWalletRepository wallet;
  final SupabaseClient _supabase;

  Future<TicketToken?> getToken(String ticketId) async {
    // 1. Check local wallet first
    final cached = await wallet.getTicket(ticketId);
    if (cached != null && cached.expiresAt.isAfter(DateTime.now())) {
      return cached;
    }

    // 2. Fetch from Edge Function
    try {
      final response = await _supabase.functions.invoke(
        'user-get-ticket-token',
        body: {'ticket_id': ticketId},
      );

      if (response.status != 200) {
        Log.e('Failed to fetch ticket token: ${response.status}');
        return null;
      }

      final data = response.data as Map<String, dynamic>;
      final token = TicketToken(
        ticketId: data['ticket_id'] as String,
        eventId: data['event_id'] as String,
        userId: data['user_id'] as String,
        signature: data['signature'] as String,
        expiresAt: DateTime.parse(data['expires_at'] as String),
      );

      // 3. Save to wallet for offline use
      await wallet.saveTicket(token);
      return token;
    } on Object catch (e, st) {
      Log.e('Error fetching ticket token', e, st);
      return null;
    }
  }
}
