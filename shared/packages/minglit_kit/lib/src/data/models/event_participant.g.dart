// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_participant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EventParticipant _$EventParticipantFromJson(Map<String, dynamic> json) =>
    _EventParticipant(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      ticketId: json['ticket_id'] as String,
      userId: json['user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      applicationId: json['application_id'] as String?,
      status: json['status'] as String? ?? 'ticket_issued',
      ticketCode: json['ticket_code'] as String?,
    );

Map<String, dynamic> _$EventParticipantToJson(_EventParticipant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'event_id': instance.eventId,
      'ticket_id': instance.ticketId,
      'user_id': instance.userId,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'application_id': instance.applicationId,
      'status': instance.status,
      'ticket_code': instance.ticketCode,
    };
