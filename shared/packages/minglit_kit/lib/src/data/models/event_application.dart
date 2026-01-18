import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:minglit_kit/src/data/models/user_profile.dart';
import 'package:minglit_kit/src/data/models/verification_submission.dart';

part 'event_application.freezed.dart';
part 'event_application.g.dart';

@freezed
class EventApplication with _$EventApplication {
  const factory EventApplication({
    required String id,
    @JsonKey(name: 'event_id') required String eventId,
    @JsonKey(name: 'ticket_id') required String ticketId,
    @JsonKey(name: 'user_id') required String userId,
    required String status, // pending, pending_review, approved, rejected, cancelled, paid
    @JsonKey(name: 'payment_id') String? paymentId,
    @JsonKey(name: 'payment_amount') int? paymentAmount,
    @JsonKey(name: 'refund_status') @Default('none') String refundStatus,
    @JsonKey(name: 'rejection_reason') String? rejectionReason,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    
    // Relations (Nullable)
    UserProfile? user,
    VerificationSubmission? submission,
  }) = _EventApplication;

  factory EventApplication.fromJson(Map<String, dynamic> json) =>
      _$EventApplicationFromJson(json);
}
