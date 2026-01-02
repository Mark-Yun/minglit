import 'package:freezed_annotation/freezed_annotation.dart';

part 'ticket.freezed.dart';
part 'ticket.g.dart';

/// **Ticket Model**
///
/// Represents a ticket configuration for an event or a party template.
@freezed
abstract class Ticket with _$Ticket {
  const factory Ticket({
    required String id,
    required String name,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'event_id') String? eventId, // Nullable for templates
    @JsonKey(name: 'party_id') String? partyId, // Nullable for event instances
    String? description,
    @Default(0) int price,
    @Default(0) int quantity,
    @JsonKey(name: 'sold_count') @Default(0) int soldCount,
    @Default({}) Map<String, dynamic> conditions, // JSONB (gender, age, etc.)
    @JsonKey(name: 'required_verification_ids')
    @Default([])
    List<String> requiredVerificationIds,
    @Default('on_sale') String status,
  }) = _Ticket;

  factory Ticket.fromJson(Map<String, dynamic> json) => _$TicketFromJson(json);
}
