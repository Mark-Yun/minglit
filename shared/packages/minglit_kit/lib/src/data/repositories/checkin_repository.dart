import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:minglit_kit/src/data/models/ticket_token.dart';
import 'package:minglit_kit/src/utils/ticket_crypto.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'checkin_repository.g.dart';

/// Provides the [CheckinRepository].
@riverpod
CheckinRepository checkinRepository(Ref ref) {
  return CheckinRepository(
    crypto: TicketCrypto(),
    supabase: Supabase.instance.client,
  );
}

/// **Check-in Repository**
///
/// Handles ticket minting (signing) and verification (check-in).
/// In production, minting happens on Edge Functions, but we provide
/// a repository interface for consistent client-side access.
class CheckinRepository {
  /// Creates a [CheckinRepository] with ticket crypto helpers.
  CheckinRepository({
    required TicketCrypto crypto,
    required SupabaseClient supabase,
  }) : _crypto = crypto,
       _supabase = supabase;

  final TicketCrypto _crypto;
  final SupabaseClient _supabase;

  /// Cached server public key to avoid repeated network calls.
  SimplePublicKey? _cachedPublicKey;

  /// Fetches the server's Ed25519 public key for ticket verification.
  /// Caches the result after the first successful fetch.
  Future<SimplePublicKey> fetchServerPublicKey() async {
    if (_cachedPublicKey != null) return _cachedPublicKey!;

    final result =
        await _supabase.rpc<String>('get_ticket_public_key');
    final keyBytes = base64Url.decode(result);
    _cachedPublicKey = SimplePublicKey(keyBytes, type: KeyPairType.ed25519);
    return _cachedPublicKey!;
  }

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
        '''${token.ticketId}|${token.eventId}|${token.userId}|${token.expiresAt.toIso8601String()}''';

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
    // TODO(Checkin): Call server-side check-in endpoint when ready.
    return true;
  }
}
