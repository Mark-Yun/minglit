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

_EventTicket _$EventTicketFromJson(Map<String, dynamic> json) => _EventTicket(
  id: json['id'] as String,
  name: json['name'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  eventId: json['event_id'] as String?,
  partyId: json['party_id'] as String?,
  description: json['description'] as String?,
  price: (json['price'] as num?)?.toInt() ?? 0,
  quantity: (json['quantity'] as num?)?.toInt() ?? 0,
  soldCount: (json['sold_count'] as num?)?.toInt() ?? 0,
  conditions: json['conditions'] as Map<String, dynamic>? ?? const {},
  requiredVerificationIds:
      (json['required_verification_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  status: json['status'] as String? ?? 'on_sale',
);

Map<String, dynamic> _$EventTicketToJson(_EventTicket instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'event_id': instance.eventId,
      'party_id': instance.partyId,
      'description': instance.description,
      'price': instance.price,
      'quantity': instance.quantity,
      'sold_count': instance.soldCount,
      'conditions': instance.conditions,
      'required_verification_ids': instance.requiredVerificationIds,
      'status': instance.status,
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
          : EventTicket.fromJson(json['ticket'] as Map<String, dynamic>),
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
