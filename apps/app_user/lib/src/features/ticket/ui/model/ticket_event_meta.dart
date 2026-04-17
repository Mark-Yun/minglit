/// Event metadata passed to the QR screen for the boarding pass display.
///
/// Holds display-only information about the event — not used for QR
/// verification. All fields are optional to maintain backwards compatibility
/// with callers that have not yet been updated to pass metadata
/// (e.g. deep link navigation).
class TicketEventMeta {
  const TicketEventMeta({
    required this.eventTitle,
    required this.eventDateTime,
    this.eventVenue,
    this.ticketName,
  });

  /// Event name shown as the boarding pass title.
  final String eventTitle;

  /// Event start time — used to determine boarding pass status and format the
  /// DATE section of the boarding pass.
  final DateTime eventDateTime;

  /// Venue name shown in the VENUE section.
  final String? eventVenue;

  /// Ticket type label (e.g. "일반 입장권").
  final String? ticketName;
}
