// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'partner.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Partner _$PartnerFromJson(Map<String, dynamic> json) => _Partner(
  id: json['id'] as String,
  name: json['name'] as String,
  introduction: json['introduction'] as String?,
  address: json['address'] as String?,
  contactPhone: json['contact_phone'] as String?,
  contactEmail: json['contact_email'] as String?,
  representativeName: json['representative_name'] as String?,
  bizName: json['biz_name'] as String?,
  bizNumber: json['biz_number'] as String?,
  profileImageUrl: json['profile_image_url'] as String?,
  isActive: json['is_active'] as bool? ?? true,
);

Map<String, dynamic> _$PartnerToJson(_Partner instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'introduction': instance.introduction,
  'address': instance.address,
  'contact_phone': instance.contactPhone,
  'contact_email': instance.contactEmail,
  'representative_name': instance.representativeName,
  'biz_name': instance.bizName,
  'biz_number': instance.bizNumber,
  'profile_image_url': instance.profileImageUrl,
  'is_active': instance.isActive,
};
