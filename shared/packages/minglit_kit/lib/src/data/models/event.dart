import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:minglit_kit/src/data/models/party.dart';

part 'event.freezed.dart';
part 'event.g.dart';

/// **Event Model**
///
/// Represents an actual instance of a party.
@freezed
abstract class Event with _$Event {
  const factory Event({
    required String id,
    @JsonKey(name: 'party_id') required String partyId,
    required DateTime startTime,
    required DateTime endTime,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'location_id') String? locationId,
    String? title,
    Map<String, dynamic>? description,
    @JsonKey(name: 'contact_options')
    @Default({})
    Map<String, dynamic> contactOptions,
    @Default({}) Map<String, dynamic> conditions, // JSONB
    @JsonKey(name: 'max_participants') @Default(20) int maxParticipants,
    @JsonKey(name: 'current_participants') @Default(0) int currentParticipants,
    @Default('scheduled') String status,
    Location? location,
    Party? party,
  }) = _Event;

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);
}

/// **Event Ticket Model**
///
/// Represents a ticket configuration for an event or a party template.
@freezed
abstract class EventTicket with _$EventTicket {
  const factory EventTicket({
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
  }) = _EventTicket;

  factory EventTicket.fromJson(Map<String, dynamic> json) =>
      _$EventTicketFromJson(json);
}

/// **Event Application Model** (Pending/Approved)
@freezed
abstract class EventApplication with _$EventApplication {
  const factory EventApplication({
    required String id,
    @JsonKey(name: 'event_id') required String eventId,
    @JsonKey(name: 'ticket_id') required String ticketId,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @Default('pending') String status,
    String? message,
    // Relationships
    Event? event,
    EventTicket? ticket,
  }) = _EventApplication;

  factory EventApplication.fromJson(Map<String, dynamic> json) =>
      _$EventApplicationFromJson(json);
}

/// **Event Participant Model** (Confirmed)
@freezed
abstract class EventParticipant with _$EventParticipant {
  const factory EventParticipant({
    required String id,
    @JsonKey(name: 'event_id') required String eventId,
    @JsonKey(name: 'ticket_id') required String ticketId,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'application_id') String? applicationId,
    @Default('ticket_issued') String status,
    @JsonKey(name: 'ticket_code') String? ticketCode,
  }) = _EventParticipant;

  factory EventParticipant.fromJson(Map<String, dynamic> json) =>
      _$EventParticipantFromJson(json);
}
