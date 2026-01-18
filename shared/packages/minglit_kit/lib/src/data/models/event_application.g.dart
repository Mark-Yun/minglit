// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_application.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EventApplication _$EventApplicationFromJson(Map<String, dynamic> json) =>
    _EventApplication(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      ticketId: json['ticket_id'] as String,
      userId: json['user_id'] as String,
      status: json['status'] as String,
      paymentId: json['payment_id'] as String?,
      paymentAmount: (json['payment_amount'] as num?)?.toInt(),
      refundStatus: json['refund_status'] as String? ?? 'none',
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      user: json['user'] == null
          ? null
          : UserProfile.fromJson(json['user'] as Map<String, dynamic>),
      submission: json['submission'] == null
          ? null
          : VerificationSubmission.fromJson(
              json['submission'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$EventApplicationToJson(_EventApplication instance) =>
    <String, dynamic>{
      'id': instance.id,
      'event_id': instance.eventId,
      'ticket_id': instance.ticketId,
      'user_id': instance.userId,
      'status': instance.status,
      'payment_id': instance.paymentId,
      'payment_amount': instance.paymentAmount,
      'refund_status': instance.refundStatus,
      'rejection_reason': instance.rejectionReason,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'user': instance.user,
      'submission': instance.submission,
    };
