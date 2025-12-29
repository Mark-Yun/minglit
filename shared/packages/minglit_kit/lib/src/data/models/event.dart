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
    @JsonKey(name: 'start_time') required DateTime startTime,
    @JsonKey(name: 'end_time') required DateTime endTime,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'location_id') String? locationId,
    String? title, // Override
    Map<String, dynamic>? description, // Override
    @JsonKey(name: 'contact_options')
    @Default({})
    Map<String, dynamic> contactOptions,
    @JsonKey(name: 'max_participants') @Default(20) int maxParticipants,
    @JsonKey(name: 'current_participants') @Default(0) int currentParticipants,
    @Default('scheduled') String status,
    // Relationships (Optional, loaded via join)
    Party? party,
    Location? location,
  }) = _Event;

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);
}

/// **Event Ticket Model**
@freezed
abstract class EventTicket with _$EventTicket {
  const factory EventTicket({
    required String id,
    @JsonKey(name: 'event_id') required String eventId,
    required String name,
    required int quantity,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    String? description,
    @Default(0) int price,
    @JsonKey(name: 'sold_count') @Default(0) int soldCount,
    String? gender, // 'male', 'female', null
    @JsonKey(name: 'min_birth_year') int? minBirthYear,
    @JsonKey(name: 'max_birth_year') int? maxBirthYear,
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
