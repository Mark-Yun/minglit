// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'partner_application.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PartnerApplication _$PartnerApplicationFromJson(Map<String, dynamic> json) =>
    _PartnerApplication(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      contactPhone: json['contact_phone'] as String,
      contactEmail: json['contact_email'] as String,
      brandName: json['brand_name'] as String?,
      introduction: json['introduction'] as String?,
      address: json['address'] as String?,
      bizType: json['biz_type'] as String?,
      bizName: json['biz_name'] as String?,
      bizNumber: json['biz_number'] as String?,
      representativeName: json['representative_name'] as String?,
      bankName: json['bank_name'] as String?,
      accountNumber: json['account_number'] as String?,
      accountHolder: json['account_holder'] as String?,
      bizRegistrationPath: json['biz_registration_path'] as String?,
      bankbookPath: json['bankbook_path'] as String?,
      profileImagePath: json['profile_image_path'] as String?,
      currentStep: (json['current_step'] as num?)?.toInt() ?? 0,
      taxEmail: json['tax_email'] as String?,
      status: json['status'] as String? ?? 'draft',
      adminComment: json['admin_comment'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );

Map<String, dynamic> _$PartnerApplicationToJson(_PartnerApplication instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'contact_phone': instance.contactPhone,
      'contact_email': instance.contactEmail,
      'brand_name': instance.brandName,
      'introduction': instance.introduction,
      'address': instance.address,
      'biz_type': instance.bizType,
      'biz_name': instance.bizName,
      'biz_number': instance.bizNumber,
      'representative_name': instance.representativeName,
      'bank_name': instance.bankName,
      'account_number': instance.accountNumber,
      'account_holder': instance.accountHolder,
      'biz_registration_path': instance.bizRegistrationPath,
      'bankbook_path': instance.bankbookPath,
      'profile_image_path': instance.profileImagePath,
      'current_step': instance.currentStep,
      'tax_email': instance.taxEmail,
      'status': instance.status,
      'admin_comment': instance.adminComment,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
