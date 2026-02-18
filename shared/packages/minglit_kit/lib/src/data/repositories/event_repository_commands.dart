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

  /// Verifies the payment with the backend.
  Future<void> confirmPayment({
    required String impUid,
    required String merchantUid,
  }) async {
    Log.d('confirmPayment called | impUid: $impUid');
    try {
      await supabaseClient.functions.invoke(
        'verify-payment-v1',
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
        'cancel-payment',
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
