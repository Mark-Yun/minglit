part of 'event_repository.dart';

mixin _EventRepositoryCommands
    on _SupabaseEventContext, _EventRepositoryQueries {
  /// Deletes an application record.
  @Deprecated('Use cancelOrder() instead — #299 user-cancel-order EF 전환')
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
          'reason': ?reason,
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

  /// Creates a pending order for payment processing.
  /// Returns the application ID (merchant_uid).
  Future<String> createOrder({
    required String eventId,
    required String ticketId,
    required String userId,
    required int amount,
    Map<String, dynamic>? verificationData,
  }) async {
    Log.d('createOrder called | event: $eventId');
    try {
      final pendingPaymentId =
          'PENDING_${DateTime.now().millisecondsSinceEpoch}';
      final existingApp = await getApplication(
        eventId: eventId,
        userId: userId,
      );

      if (existingApp == null) {
        final appId = await applyEvent(
          eventId: eventId,
          ticketId: ticketId,
          userId: userId,
          paymentId: pendingPaymentId,
          paymentAmount: amount,
          verificationData: verificationData,
        );

        await supabaseClient
            .from('event_applications')
            .update({
              'status': 'pending',
              'payment_id': pendingPaymentId,
              'ticket_id': ticketId,
              'payment_amount': amount,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', appId);

        return appId;
      }

      await supabaseClient
          .from('event_applications')
          .update({
            'ticket_id': ticketId,
            'payment_id': pendingPaymentId,
            'payment_amount': amount,
            'status': 'pending',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', existingApp.id);

      if (verificationData == null) {
        await supabaseClient
            .from('verification_submissions')
            .delete()
            .eq('application_id', existingApp.id)
            .eq('status', 'pending');
        return existingApp.id;
      }

      await supabaseClient
          .from('verification_submissions')
          .delete()
          .eq('application_id', existingApp.id)
          .eq('status', 'pending');

      await supabaseClient.from('verification_submissions').insert({
        'application_id': existingApp.id,
        'partner_id': verificationData['partner_id'],
        'verification_id': verificationData['verification_id'],
        'user_id': userId,
        'status': 'pending',
        'snapshot_data': verificationData['data'],
      });

      return existingApp.id;
    } catch (e, st) {
      Log.e('❌ [EventRepo] createOrder Error', e, st);
      rethrow;
    }
  }

  /// Creates a pending order via user-create-order Edge Function.
  /// Server validates all business rules (price, eligibility, capacity, etc.).
  /// Returns the order result with server-determined amount.
  Future<CreateOrderResult> createOrderViaEF({
    required String eventId,
    required String ticketId,
    Map<String, dynamic>? verificationData,
  }) async {
    Log.d('createOrderViaEF called | event: $eventId, ticket: $ticketId');
    try {
      final response = await supabaseClient.functions.invoke(
        'user-create-order',
        body: {
          'event_id': eventId,
          'ticket_id': ticketId,
          'verification_data': ?verificationData,
        },
      );

      if (response.status != 200) {
        final data = response.data;
        final errorMsg = data is Map
            ? (data['error'] as String?) ?? '주문 생성에 실패했습니다.'
            : '주문 생성에 실패했습니다.';
        throw MinglitUserException(errorMsg);
      }

      final data = response.data as Map<String, dynamic>;
      return CreateOrderResult(
        applicationId: data['application_id'] as String,
        amount: data['amount'] as int,
        requiresPayment: data['requires_payment'] as bool,
        ticketName: data['ticket_name'] as String,
      );
    } catch (e, st) {
      Log.e('❌ [EventRepo] createOrderViaEF Error', e, st);
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
