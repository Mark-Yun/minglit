import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_participant.freezed.dart';
part 'event_participant.g.dart';

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
