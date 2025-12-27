import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'partner.freezed.dart';
part 'partner.g.dart';

@freezed
abstract class Partner with _$Partner {
  const factory Partner({
    required String id,
    required String name,
    String? introduction,
    String? address,
    @JsonKey(name: 'contact_phone') String? contactPhone,
    @JsonKey(name: 'contact_email') String? contactEmail,
    @JsonKey(name: 'representative_name') String? representativeName,
    @JsonKey(name: 'biz_name') String? bizName,
    @JsonKey(name: 'biz_number') String? bizNumber,
    @JsonKey(name: 'profile_image_url') String? profileImageUrl,
    @Default(true) @JsonKey(name: 'is_active') bool isActive,
  }) = _Partner;

  factory Partner.fromJson(Map<String, dynamic> json) => _$PartnerFromJson(json);
}