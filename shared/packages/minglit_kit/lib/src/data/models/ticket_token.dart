import 'package:freezed_annotation/freezed_annotation.dart';

part 'ticket_token.freezed.dart';
part 'ticket_token.g.dart';

/// **Ticket Token**
///
/// A signed token that can be converted into a QR code.
/// Contains the minimal data needed for offline display
/// and online verification.
@freezed
abstract class TicketToken with _$TicketToken {
  /// Creates a [TicketToken] for QR-based verification.
  const factory TicketToken({
    required String ticketId,
    required String eventId,
    required String userId,
    required String signature,
    required DateTime expiresAt,
  }) = _TicketToken;

  /// Creates a [TicketToken] from a JSON map.
  factory TicketToken.fromJson(Map<String, dynamic> json) =>
      _$TicketTokenFromJson(json);
}
