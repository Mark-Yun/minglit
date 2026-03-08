// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'iamport_result_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_IamportResultModel _$IamportResultModelFromJson(Map<String, dynamic> json) =>
    _IamportResultModel(
      impUid: json['imp_uid'] as String?,
      merchantUid: json['merchant_uid'] as String?,
      success: json['success'] as bool? ?? false,
      errorMsg: json['error_msg'] as String?,
      pgProvider: json['pg_provider'] as String?,
      pgType: json['pg_type'] as String?,
    );

Map<String, dynamic> _$IamportResultModelToJson(_IamportResultModel instance) =>
    <String, dynamic>{
      'imp_uid': instance.impUid,
      'merchant_uid': instance.merchantUid,
      'success': instance.success,
      'error_msg': instance.errorMsg,
      'pg_provider': instance.pgProvider,
      'pg_type': instance.pgType,
    };
