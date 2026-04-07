// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Tag _$TagFromJson(Map<String, dynamic> json) => _Tag(
  id: json['id'] as String,
  name: json['name'] as String,
  isFeatured: json['is_featured'] as bool? ?? false,
  usageCount: (json['usage_count'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$TagToJson(_Tag instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'is_featured': instance.isFeatured,
  'usage_count': instance.usageCount,
};
