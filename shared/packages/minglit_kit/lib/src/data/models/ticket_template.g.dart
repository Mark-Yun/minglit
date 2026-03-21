// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TicketTemplate _$TicketTemplateFromJson(Map<String, dynamic> json) =>
    _TicketTemplate(
      id: json['id'] as String,
      partyId: json['party_id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toInt() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      targetEntryGroupIds: (json['target_entry_group_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      requiredVerificationIds:
          (json['required_verification_ids'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              const [],
    );

Map<String, dynamic> _$TicketTemplateToJson(_TicketTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'party_id': instance.partyId,
      'name': instance.name,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'description': instance.description,
      'price': instance.price,
      'quantity': instance.quantity,
      'target_entry_group_ids': instance.targetEntryGroupIds,
      'required_verification_ids': instance.requiredVerificationIds,
    };
