import 'package:cryptography/cryptography.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:minglit_kit/src/utils/ticket_crypto.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'checkin_repository.g.dart';

@riverpod
CheckinRepository checkinRepository(Ref ref) {
  return CheckinRepository(TicketCrypto());
}

/// **Check-in Repository**
///
/// Handles ticket minting (signing) and verification (check-in).
/// In production, minting happens on Edge Functions, but we provide
/// a repository interface for consistent client-side access.
class CheckinRepository {
  CheckinRepository(this._crypto);
  final TicketCrypto _crypto;

  /// Mints a signed [TicketToken] for a given participant record.
  /// This simulates an Edge Function call.
  Future<TicketToken> mintTicket({
    required String ticketId,
    required String eventId,
    required String userId,
    required SimpleKeyPair serverPrivateKey, // In prod, this is on the server
  }) async {
    final expiresAt = DateTime.now().add(const Duration(days: 7));

    // Payload to sign
    final payload = '$ticketId|$eventId|$userId|${expiresAt.toIso8601String()}';

    final signature = await _crypto.sign(payload, serverPrivateKey);

    return TicketToken(
      ticketId: ticketId,
      eventId: eventId,
      userId: userId,
      signature: signature,
      expiresAt: expiresAt,
    );
  }

  /// Verifies a [TicketToken] and updates check-in status.
  /// Returns true if valid and check-in succeeded.
  Future<bool> verifyAndCheckin({
    required TicketToken token,
    required SimplePublicKey serverPublicKey,
  }) async {
    // 1. Reconstruct payload
    final payload =
        '${token.ticketId}|${token.eventId}|${token.userId}|${token.expiresAt.toIso8601String()}';

    // 2. Verify Signature
    final isValid = await _crypto.verify(
      payload,
      token.signature,
      serverPublicKey,
    );
    if (!isValid) return false;

    // 3. Check expiration
    if (token.expiresAt.isBefore(DateTime.now())) return false;

    // 4. Update DB (Simulated)
    // TODO(party_checkin_system_20260117): Call Supabase RPC to update participant status to 'checked_in'
    Log.i('✅ Check-in Success for user: ${token.userId}');

    return true;
  }
}
