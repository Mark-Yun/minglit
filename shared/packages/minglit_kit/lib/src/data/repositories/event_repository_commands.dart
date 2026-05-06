part of 'event_repository.dart';

/// Result returned by [EventRepository.applyEvent].
///
/// The `apply-event` Edge Function responds with a `type` field that
/// distinguishes free and paid applications.
sealed class ApplyEventResult {
  const ApplyEventResult({required this.applicationId});

  final String applicationId;
}

/// Returned when the event ticket is free — application is immediately
/// confirmed, no payment step required.
final class FreeApplyEventResult extends ApplyEventResult {
  const FreeApplyEventResult({required super.applicationId});
}

/// Returned when the event ticket is paid — caller must proceed to the
/// PG payment flow using [orderId] and [paymentAmount].
final class PaidApplyEventResult extends ApplyEventResult {
  const PaidApplyEventResult({
    required super.applicationId,
    required this.orderId,
    required this.paymentAmount,
  });

  final String orderId;
  final int paymentAmount;
}

mixin _EventRepositoryCommands on _SupabaseEventContext {
  /// Deletes an application record.
  Future<void> deleteApplication({
    required String eventId,
    required String userId,
  }) async {
    Log.d('deleteApplication called | event: $eventId, user: $userId');
    try {
      await supabaseClient
          .from('event_applications')
          .delete()
          .eq('event_id', eventId)
          .eq('user_id', userId);
      Log.i('✅ [EventRepo] Application deleted.');
    } catch (e, st) {
      Log.e('❌ [EventRepo] deleteApplication Error', e, st);
      rethrow;
    }
  }

  /// Fix #299: 주문 취소/환불을 user-cancel-order EF로 통합 호출.
  /// 결제 전 취소, 무료 이벤트 취소, 유료 이벤트 환불을 모두 처리한다.
  Future<CancelOrderResult> cancelOrder({
    required String eventId,
    String? reason,
  }) async {
    Log.d('cancelOrder called | event: $eventId');
    try {
      final response = await supabaseClient.functions.invoke(
        'user-cancel-order',
        body: {
          'event_id': eventId,
          'reason': reason,
        },
      );

      if (response.status != 200) {
        final data = response.data;
        final errorMsg = data is Map
            ? (data['error'] as String?) ?? '취소 요청에 실패했습니다.'
            : '취소 요청에 실패했습니다.';
        throw MinglitUserException(errorMsg);
      }

      final data = response.data as Map<String, dynamic>;
      final type = data['type'] as String;
      int? refundAmount;
      if (type == 'refunded') {
        final refundData = data['data'] as Map<String, dynamic>?;
        refundAmount = refundData?['refund_amount'] as int?;
      }

      return CancelOrderResult(type: type, refundAmount: refundAmount);
    } catch (e, st) {
      Log.e('❌ [EventRepo] cancelOrder Error', e, st);
      rethrow;
    }
  }

  /// Verifies the payment with the backend.
  Future<void> confirmPayment({
    required String impUid,
    required String merchantUid,
  }) async {
    Log.d('confirmPayment called | impUid: $impUid');
    try {
      // Fix #1945: functions.invoke() never throws on 4xx/5xx — check status.
      final response = await supabaseClient.functions.invoke(
        'payment-verify',
        body: {'imp_uid': impUid, 'merchant_uid': merchantUid},
      );
      if (response.status != 200) {
        final data = response.data;
        final msg = data is Map
            ? (data['error'] as String?) ?? '결제 검증에 실패했습니다.'
            : '결제 검증에 실패했습니다.';
        throw MinglitUserException(msg);
      }
      Log.i('✅ [EventRepo] Payment verified.');
    } catch (e, st) {
      Log.e('❌ [EventRepo] confirmPayment Error', e, st);
      rethrow;
    }
  }

  /// Cancels a payment using the Edge Function.
  Future<void> cancelPayment({
    required String paymentId,
    required int refundAmount,
    String? reason,
  }) async {
    Log.d(
      'cancelPayment called | paymentId: $paymentId, amount: $refundAmount',
    );
    try {
      final response = await supabaseClient.functions.invoke(
        'payment-cancel',
        body: {
          'payment_id': paymentId,
          'amount': refundAmount,
          ...?reason == null ? null : {'reason': reason},
        },
      );

      if (response.status != 200) {
        throw const MinglitUserException('환불 요청에 실패했습니다.');
      }

      Log.i('✅ [EventRepo] Payment cancellation requested.');
    } catch (e, st) {
      Log.e('❌ [EventRepo] cancelPayment Error', e, st);
      rethrow;
    }
  }

  /// Submits an event application via the `apply-event` Edge Function.
  ///
  /// Returns [FreeApplyEventResult] for free tickets (application confirmed
  /// immediately) or [PaidApplyEventResult] for paid tickets (caller must
  /// drive the PG payment flow).
  Future<ApplyEventResult> applyEvent({
    required String eventId,
    required String ticketId,
    Map<String, dynamic>? verificationData,
  }) async {
    Log.d('applyEvent called | event: $eventId, ticket: $ticketId');
    try {
      final response = await supabaseClient.functions.invoke(
        'apply-event',
        body: {
          'event_id': eventId,
          'ticket_id': ticketId,
          'verification_data': ?verificationData,
        },
      );

      // Fix #1409: 비-200 응답 시 response.data가 null이어서 캐스트 크래시 발생.
      // cancelOrder와 동일한 패턴으로 status 먼저 확인 후 캐스트한다.
      if (response.status != 200) {
        final errData = response.data;
        final errorMsg = errData is Map
            ? (errData['error'] as String?) ?? '이벤트 신청에 실패했습니다.'
            : '이벤트 신청에 실패했습니다.';
        throw MinglitUserException(errorMsg);
      }

      final data = response.data as Map<String, dynamic>;
      final type = data['type'] as String;
      final applicationId = data['application_id'] as String;

      if (type == 'paid') {
        final result = PaidApplyEventResult(
          applicationId: applicationId,
          orderId: data['order_id'] as String,
          paymentAmount: data['payment_amount'] as int,
        );
        Log.i(
          '✅ [EventRepo] Paid application created. '
          'ID: $applicationId, orderId: ${result.orderId}',
        );
        return result;
      }

      Log.i('✅ [EventRepo] Free application confirmed. ID: $applicationId');
      return FreeApplyEventResult(applicationId: applicationId);
    } catch (e, st) {
      Log.e('❌ [EventRepo] applyEvent Error', e, st);
      rethrow;
    }
  }

  /// Fix #653: Approves a single event application via Edge Function.
  Future<void> approveApplication({required String applicationId}) async {
    Log.d('approveApplication called | applicationId: $applicationId');
    try {
      // Fix #1945: functions.invoke() never throws on 4xx/5xx — check status.
      final response = await supabaseClient.functions.invoke(
        'partner-approve-application',
        body: {'action': 'approve', 'application_id': applicationId},
      );
      if (response.status != 200) {
        final data = response.data;
        final msg = data is Map
            ? (data['error'] as String?) ?? '승인 요청에 실패했습니다.'
            : '승인 요청에 실패했습니다.';
        throw MinglitUserException(msg);
      }
      Log.i('✅ [EventRepo] Application approved: $applicationId');
    } catch (e, st) {
      Log.e('❌ [EventRepo] approveApplication Error', e, st);
      rethrow;
    }
  }

  /// Fix #653: Rejects a single event application via Edge Function.
  Future<void> rejectApplication({
    required String applicationId,
    required String reason,
  }) async {
    Log.d('rejectApplication called | applicationId: $applicationId');
    try {
      // Fix #1945: functions.invoke() never throws on 4xx/5xx — check status.
      final response = await supabaseClient.functions.invoke(
        'partner-reject-application',
        body: {'application_id': applicationId, 'reason': reason},
      );
      if (response.status != 200) {
        final data = response.data;
        final msg = data is Map
            ? (data['error'] as String?) ?? '거절 요청에 실패했습니다.'
            : '거절 요청에 실패했습니다.';
        throw MinglitUserException(msg);
      }
      Log.i('✅ [EventRepo] Application rejected: $applicationId');
    } catch (e, st) {
      Log.e('❌ [EventRepo] rejectApplication Error', e, st);
      rethrow;
    }
  }

  /// Fix #653: Bulk-approves all pending applications for a given event.
  Future<void> bulkApproveApplications({required String eventId}) async {
    Log.d('bulkApproveApplications called | eventId: $eventId');
    try {
      // Fix #1945: functions.invoke() never throws on 4xx/5xx — check status.
      final response = await supabaseClient.functions.invoke(
        'partner-approve-application',
        body: {'action': 'bulk_approve', 'event_id': eventId},
      );
      if (response.status != 200) {
        final data = response.data;
        final msg = data is Map
            ? (data['error'] as String?) ?? '일괄 승인에 실패했습니다.'
            : '일괄 승인에 실패했습니다.';
        throw MinglitUserException(msg);
      }
      Log.i('✅ [EventRepo] Bulk approve completed for event: $eventId');
    } catch (e, st) {
      Log.e('❌ [EventRepo] bulkApproveApplications Error', e, st);
      rethrow;
    }
  }

  // Fix #2123: marks match_results_viewed_at via user-mark-match-results-viewed
  // EF (idempotent — EF returns already_viewed:true on repeat calls).
  Future<void> markMatchResultsViewed({
    required String applicationId,
  }) async {
    Log.d('markMatchResultsViewed | applicationId: $applicationId');
    try {
      final response = await supabaseClient.functions.invoke(
        'user-mark-match-results-viewed',
        body: {'application_id': applicationId},
      );
      if (response.status != 200) {
        final data = response.data;
        final msg = data is Map
            ? (data['error'] as String?) ?? '결과 확인 처리에 실패했습니다.'
            : '결과 확인 처리에 실패했습니다.';
        throw MinglitUserException(msg);
      }
      Log.i('✅ [EventRepo] markMatchResultsViewed: $applicationId');
    } catch (e, st) {
      Log.e('❌ [EventRepo] markMatchResultsViewed Error', e, st);
      rethrow;
    }
  }
}
