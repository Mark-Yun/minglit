// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'withdrawal_reason.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WithdrawalReason _$WithdrawalReasonFromJson(Map<String, dynamic> json) =>
    _WithdrawalReason(
      reasonCode: $enumDecode(
        _$WithdrawalReasonCodeEnumMap,
        json['reason_code'],
      ),
      detail: json['reason_text'] as String?,
    );

Map<String, dynamic> _$WithdrawalReasonToJson(_WithdrawalReason instance) =>
    <String, dynamic>{
      'reason_code': _$WithdrawalReasonCodeEnumMap[instance.reasonCode]!,
      'reason_text': instance.detail,
    };

const _$WithdrawalReasonCodeEnumMap = {
  WithdrawalReasonCode.noLongerUse: 'no_longer_use',
  WithdrawalReasonCode.noDesiredEvents: 'no_desired_events',
  WithdrawalReasonCode.usingOtherService: 'using_other_service',
  WithdrawalReasonCode.privacyConcern: 'privacy_concern',
  WithdrawalReasonCode.poorUsability: 'poor_usability',
  WithdrawalReasonCode.other: 'other',
};
