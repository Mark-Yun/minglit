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
  const factory TicketToken({
    required String ticketId,
    required String eventId,
    required String userId,
    required String signature,
    required DateTime expiresAt,
  }) = _TicketToken;

  factory TicketToken.fromJson(Map<String, dynamic> json) =>
      _$TicketTokenFromJson(json);
}
