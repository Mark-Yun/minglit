// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Ticket _$TicketFromJson(Map<String, dynamic> json) => _Ticket(
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

Map<String, dynamic> _$TicketToJson(_Ticket instance) => <String, dynamic>{
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
