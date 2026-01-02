// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Event _$EventFromJson(Map<String, dynamic> json) => _Event(
  id: json['id'] as String,
  partyId: json['party_id'] as String,
  startTime: DateTime.parse(json['startTime'] as String),
  endTime: DateTime.parse(json['endTime'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  locationId: json['location_id'] as String?,
  title: json['title'] as String?,
  description: json['description'] as Map<String, dynamic>?,
  contactOptions: json['contact_options'] as Map<String, dynamic>? ?? const {},
  conditions: json['conditions'] as Map<String, dynamic>? ?? const {},
  maxParticipants: (json['max_participants'] as num?)?.toInt() ?? 20,
  currentParticipants: (json['current_participants'] as num?)?.toInt() ?? 0,
  status: json['status'] as String? ?? 'scheduled',
  location: json['location'] == null
      ? null
      : Location.fromJson(json['location'] as Map<String, dynamic>),
  party: json['party'] == null
      ? null
      : Party.fromJson(json['party'] as Map<String, dynamic>),
);

Map<String, dynamic> _$EventToJson(_Event instance) => <String, dynamic>{
  'id': instance.id,
  'party_id': instance.partyId,
  'startTime': instance.startTime.toIso8601String(),
  'endTime': instance.endTime.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'location_id': instance.locationId,
  'title': instance.title,
  'description': instance.description,
  'contact_options': instance.contactOptions,
  'conditions': instance.conditions,
  'max_participants': instance.maxParticipants,
  'current_participants': instance.currentParticipants,
  'status': instance.status,
  'location': instance.location,
  'party': instance.party,
};

_EventApplication _$EventApplicationFromJson(Map<String, dynamic> json) =>
    _EventApplication(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      ticketId: json['ticket_id'] as String,
      userId: json['user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      status: json['status'] as String? ?? 'pending',
      message: json['message'] as String?,
      event: json['event'] == null
          ? null
          : Event.fromJson(json['event'] as Map<String, dynamic>),
      ticket: json['ticket'] == null
          ? null
          : Ticket.fromJson(json['ticket'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$EventApplicationToJson(_EventApplication instance) =>
    <String, dynamic>{
      'id': instance.id,
      'event_id': instance.eventId,
      'ticket_id': instance.ticketId,
      'user_id': instance.userId,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'status': instance.status,
      'message': instance.message,
      'event': instance.event,
      'ticket': instance.ticket,
    };

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
