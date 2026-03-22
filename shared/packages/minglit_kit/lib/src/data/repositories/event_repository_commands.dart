part of 'event_repository.dart';

mixin _EventRepositoryCommands
    on _SupabaseEventContext, _EventRepositoryQueries {
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

  /// Creates a validated order via the user-create-order Edge Function.
  ///
  /// Performs server-side validation of all business rules (V1~V8) and
  /// returns the result including [applicationId], [amount],
  /// [requiresPayment], and [ticketName].
  ///
  /// Throws [MinglitUserException] on known error codes, or rethrows
  /// unexpected errors.
  Future<CreateOrderResult> createOrder({
    required String eventId,
    required String ticketId,
  }) async {
    Log.d('createOrder called | event: $eventId, ticket: $ticketId');
    try {
      final response = await supabaseClient.functions.invoke(
        'user-create-order',
        body: {'event_id': eventId, 'ticket_id': ticketId},
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        throw const MinglitUserException('서버 응답이 올바르지 않습니다.');
      }

      if (data.containsKey('error')) {
        final code = data['error'] as String;
        throw MinglitUserException(_orderErrorMessage(code));
      }

      Log.i('✅ [EventRepo] createOrder success. ID: ${data['application_id']}');
      return CreateOrderResult(
        applicationId: data['application_id'] as String,
        amount: (data['amount'] as num).toInt(),
        requiresPayment: data['requires_payment'] as bool,
        ticketName: data['ticket_name'] as String,
      );
    } catch (e, st) {
      Log.e('❌ [EventRepo] createOrder Error', e, st);
      rethrow;
    }
  }

  static String _orderErrorMessage(String code) {
    switch (code) {
      case 'EVENT_NOT_FOUND':
        return '이벤트를 찾을 수 없습니다.';
      case 'TICKET_NOT_FOUND':
        return '티켓을 찾을 수 없습니다.';
      case 'ALREADY_APPLIED':
        return '이미 신청한 이벤트입니다.';
      case 'EVENT_NOT_ACTIVE':
        return '신청 가능한 이벤트가 아닙니다.';
      case 'EVENT_FULL':
        return '정원이 가득 찼습니다.';
      case 'TICKET_SOLD_OUT':
        return '티켓이 매진되었습니다.';
      case 'IDENTITY_REQUIRED':
        return '본인 인증이 필요합니다.';
      case 'ELIGIBILITY_FAILED':
        return '신청 자격이 충족되지 않았습니다.';
      case 'VERIFICATION_REQUIRED':
        return '필수 서류 제출이 필요합니다.';
      case 'BALANCE_LIMIT':
        return '성비 조절 중입니다. 잠시 후 다시 시도해 주세요.';
      default:
        return '신청 처리 중 오류가 발생했습니다.';
    }
  }

  /// Verifies the payment with the backend.
  Future<void> confirmPayment({
    required String impUid,
    required String merchantUid,
  }) async {
    Log.d('confirmPayment called | impUid: $impUid');
    try {
      await supabaseClient.functions.invoke(
        'payment-verify',
        body: {'imp_uid': impUid, 'merchant_uid': merchantUid},
      );
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

  /// Submits an event application (One-Shot Flow).
  /// Handles application creation and verification submission in one trans.
  ///
  /// Deprecated: Use [createOrder] which calls the user-create-order Edge
  /// Function for server-side validated order creation.
  @Deprecated('Phase 3에서 삭제 예정. createOrder EF 방식으로 교체됨.')
  Future<String> applyEvent({
    required String eventId,
    required String ticketId,
    required String userId,
    required String paymentId,
    required int paymentAmount,
    Map<String, dynamic>? verificationData,
  }) async {
    Log.d('applyEvent called | event: $eventId, ticket: $ticketId');
    try {
      final params = {
        'p_event_id': eventId,
        'p_ticket_id': ticketId,
        'p_user_id': userId,
        'p_payment_id': paymentId,
        'p_payment_amount': paymentAmount,
        'p_verification_data': verificationData,
      };

      final response = await supabaseClient.rpc<String>(
        'apply_event',
        params: params,
      );

      Log.i('✅ [EventRepo] Application successful. ID: $response');
      return response;
    } catch (e, st) {
      Log.e('❌ [EventRepo] applyEvent Error', e, st);
      rethrow;
    }
  }
}
