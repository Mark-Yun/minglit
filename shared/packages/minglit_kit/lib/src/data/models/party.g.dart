// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'party.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Location _$LocationFromJson(Map<String, dynamic> json) => _Location(
  id: json['id'] as String,
  partnerId: json['partner_id'] as String,
  name: json['name'] as String,
  address: json['address'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  addressDetail: json['address_detail'] as String?,
  sido: json['sido'] as String?,
  sigungu: json['sigungu'] as String?,
);

Map<String, dynamic> _$LocationToJson(_Location instance) => <String, dynamic>{
  'id': instance.id,
  'partner_id': instance.partnerId,
  'name': instance.name,
  'address': instance.address,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'address_detail': instance.addressDetail,
  'sido': instance.sido,
  'sigungu': instance.sigungu,
};

_Party _$PartyFromJson(Map<String, dynamic> json) => _Party(
  id: json['id'] as String,
  partnerId: json['partner_id'] as String,
  title: json['title'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  description: json['description'] as Map<String, dynamic>?,
  imageUrl: json['image_url'] as String?,
  contactOptions: json['contact_options'] as Map<String, dynamic>? ?? const {},
  requiredVerificationIds:
      (json['required_verification_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  minConfirmedCount: (json['min_confirmed_count'] as num?)?.toInt() ?? 0,
  maxParticipants: (json['max_participants'] as num?)?.toInt() ?? 20,
  status: json['status'] as String? ?? 'active',
);

Map<String, dynamic> _$PartyToJson(_Party instance) => <String, dynamic>{
  'id': instance.id,
  'partner_id': instance.partnerId,
  'title': instance.title,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'description': instance.description,
  'image_url': instance.imageUrl,
  'contact_options': instance.contactOptions,
  'required_verification_ids': instance.requiredVerificationIds,
  'min_confirmed_count': instance.minConfirmedCount,
  'max_participants': instance.maxParticipants,
  'status': instance.status,
};
