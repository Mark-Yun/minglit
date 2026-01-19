// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Event _$EventFromJson(Map<String, dynamic> json) => _Event(
  id: json['id'] as String,
  partyId: json['party_id'] as String,
  startTime: DateTime.parse(json['start_time'] as String),
  endTime: DateTime.parse(json['end_time'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  locationId: json['location_id'] as String?,
  title: json['title'] as String?,
  description: json['description'] as Map<String, dynamic>?,
  imageUrls: (json['image_urls'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  contactOptions: json['contact_options'] as Map<String, dynamic>? ?? const {},
  maxParticipants: (json['max_participants'] as num?)?.toInt() ?? 20,
  currentParticipants: (json['current_participants'] as num?)?.toInt() ?? 0,
  status: json['status'] as String? ?? 'scheduled',
  location: json['location'] == null
      ? null
      : Location.fromJson(json['location'] as Map<String, dynamic>),
  party: json['party'] == null
      ? null
      : Party.fromJson(json['party'] as Map<String, dynamic>),
  tickets: (json['tickets'] as List<dynamic>?)
      ?.map((e) => Ticket.fromJson(e as Map<String, dynamic>))
      .toList(),
  entryGroups: (json['entryGroups'] as List<dynamic>?)
      ?.map((e) => EntryGroup.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$EventToJson(_Event instance) => <String, dynamic>{
  'id': instance.id,
  'party_id': instance.partyId,
  'start_time': instance.startTime.toIso8601String(),
  'end_time': instance.endTime.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'location_id': instance.locationId,
  'title': instance.title,
  'description': instance.description,
  'image_urls': instance.imageUrls,
  'contact_options': instance.contactOptions,
  'max_participants': instance.maxParticipants,
  'current_participants': instance.currentParticipants,
  'status': instance.status,
};
