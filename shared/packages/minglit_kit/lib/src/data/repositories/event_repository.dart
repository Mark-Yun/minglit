import 'package:minglit_kit/src/data/models/event.dart';
import 'package:minglit_kit/src/data/models/event_application.dart';
import 'package:minglit_kit/src/data/models/event_feed_type.dart';
import 'package:minglit_kit/src/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'event_repository.g.dart';

/// Provider for EventRepository.
@Riverpod(keepAlive: true)
EventRepository eventRepository(Ref ref) {
  return EventRepository();
}

/// Repository for Event-related data operations.
class EventRepository {
  EventRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  /// Fetches applications for a specific event.
  Future<List<EventApplication>> getApplicationsByEventId(
    String eventId,
  ) async {
    Log.d('getApplicationsByEventId called | id: $eventId');
    try {
      final data = await _supabase
          .from('event_applications')
          .select(
            '*, '
            'user:user_profiles(*), '
            'submission:'
            'verification_submissions(*)',
          )
          .eq('event_id', eventId)
          .order('created_at', ascending: false);

      final result = (data as List).map((json) {
        final map = json as Map<String, dynamic>;

        // Fix: If 'user' is a List (due to some Supabase quirk),
        // take the first item or null
        if (map['user'] is List) {
          final list = map['user'] as List;
          map['user'] = list.isNotEmpty ? list.first : null;
        }

        // Fix: If 'submission' is a List
        if (map['submission'] is List) {
          final list = map['submission'] as List;
          map['submission'] = list.isNotEmpty ? list.first : null;
        }

        return EventApplication.fromJson(map);
      }).toList();

      Log.d('getApplicationsByEventId success | count: ${result.length}');
      return result;
    } catch (e, st) {
      Log.e('❌ [EventRepo] getApplicationsByEventId Error', e, st);
      rethrow;
    }
  }

  /// Deletes an application record.
  Future<void> deleteApplication({
    required String eventId,
    required String userId,
  }) async {
    Log.d('deleteApplication called | event: $eventId, user: $userId');
    try {
      await _supabase
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

  /// Fetches events based on a specific curation type.
  Future<List<Event>> getEventsByType({
    required EventFeedType type,
    double? latitude,
    double? longitude,
    int limit = 10,
  }) async {
    Log.d('getEventsByType called | type: $type');
    try {
      // 1. Base Query with Relations
      var selectQuery =
          '*, party:parties(*, location:locations(*), partner:partners(*)), '
          'entryGroups:entry_groups(*), tickets(*)';

      // Special case for Early Bird: filter by ticket name
      if (type == EventFeedType.earlyBird) {
        selectQuery =
            '*, party:parties(*, location:locations(*), partner:partners(*)), '
            'entryGroups:entry_groups(*), tickets!inner(*)';
      }

      dynamic query = _supabase.from('events').select(selectQuery);

      // 2. Common Filters
      // ignore: avoid_dynamic_calls, Reason: Supabase builder chaining
      query = query.eq('status', 'scheduled');
      // ignore: avoid_dynamic_calls, Reason: Supabase builder chaining
      query = query.gte('start_time', DateTime.now().toIso8601String());

      // 3. Early Bird Filter
      if (type == EventFeedType.earlyBird) {
        // ignore: avoid_dynamic_calls, Reason: Supabase builder chaining
        query = query.ilike('tickets.name', '%얼리버드%');
      }

      // 4. Sorting Strategy
      switch (type) {
        case EventFeedType.newArrivals:
          // ignore: avoid_dynamic_calls, Reason: Supabase builder chaining
          query = query.order('created_at', ascending: false);
        case EventFeedType.closingSoon:
          // ignore: avoid_dynamic_calls, Reason: Supabase builder chaining
          query = query.order('start_time', ascending: true);
        case EventFeedType.nearest:
          // ignore: avoid_dynamic_calls, Reason: Supabase builder chaining
          query = query.order('start_time', ascending: true);
        case EventFeedType.earlyBird:
          // ignore: avoid_dynamic_calls, Reason: Supabase builder chaining
          query = query.order('start_time', ascending: true);
      }

      final data = await (query as PostgrestTransformBuilder).limit(limit);

      final result = (data as List<dynamic>)
          .map((json) => Event.fromJson(json as Map<String, dynamic>))
          .toList();

      Log.d('getEventsByType success | count: ${result.length}');
      return result;
    } catch (e, st) {
      Log.e('❌ [EventRepo] getEventsByType Error', e, st);
      rethrow;
    }
  }

  /// Fetches a single event by ID with all relations.
  Future<Event> getEventById(String eventId) async {
    Log.d('getEventById called | id: $eventId');
    try {
      final data = await _supabase
          .from('events')
          .select(
            '*, party:parties(*, location:locations(*), partner:partners(*)), '
            'entryGroups:entry_groups(*), tickets(*)',
          )
          .eq('id', eventId)
          .single();

      final result = Event.fromJson(data);
      Log.d('getEventById success | title: ${result.title}');
      return result;
    } catch (e, st) {
      Log.e('❌ [EventRepo] getEventById Error', e, st);
      rethrow;
    }
  }

  /// Fetches ticket balance status for a specific event.
  Future<Map<String, bool>> getTicketBalanceStatus(String eventId) async {
    Log.d('getTicketBalanceStatus called | eventId: $eventId');
    try {
      final response = await _supabase.rpc(
        'get_event_ticket_balance_status',
        params: {'p_event_id': eventId},
      );

      if (response == null) return {};

      final result = <String, bool>{};
      for (final item in response as List<dynamic>) {
        final data = item as Map<String, dynamic>;
        final ticketId = data['ticket_id'] as String?;
        final allowed = data['allowed'] as bool?;
        if (ticketId != null && allowed != null) {
          result[ticketId] = allowed;
        }
      }

      Log.d('getTicketBalanceStatus success | count: ${result.length}');
      return result;
    } catch (e, st) {
      Log.e('❌ [EventRepo] getTicketBalanceStatus Error', e, st);
      rethrow;
    }
  }

  /// Fetches the application record for a specific user and event.
  Future<EventApplication?> getApplication({
    required String eventId,
    required String userId,
  }) async {
    Log.d('getApplication called | event: $eventId, user: $userId');
    try {
      final response = await _supabase
          .from('event_applications')
          .select()
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return EventApplication.fromJson(response);
    } catch (e, st) {
      Log.e('❌ [EventRepo] getApplication Error', e, st);
      rethrow;
    }
  }

  /// Checks if a user has already applied for an event.
  Future<bool> checkApplicationStatus({
    required String eventId,
    required String userId,
  }) async {
    final app = await getApplication(eventId: eventId, userId: userId);
    return app != null && app.status != 'rejected' && app.status != 'cancelled';
  }

  /// Fetches the current user's purchase history.
  Future<List<EventApplication>> getMyPurchaseHistory(String userId) async {
    Log.d('getMyPurchaseHistory called | userId: $userId');
    try {
      final data = await _supabase
          .from('event_applications')
          .select(
            '*, '
            'event:events(*, party:parties(*, location:locations(*))), '
            'ticket:tickets(*)',
          )
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final result = (data as List).map((json) {
        return EventApplication.fromJson(json as Map<String, dynamic>);
      }).toList();

      Log.d('getMyPurchaseHistory success | count: ${result.length}');
      return result;
    } catch (e, st) {
      Log.e('❌ [EventRepo] getMyPurchaseHistory Error', e, st);
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

        await _supabase
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

      await _supabase
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
        await _supabase
            .from('verification_submissions')
            .delete()
            .eq('application_id', existingApp.id)
            .eq('status', 'pending');
        return existingApp.id;
      }

      await _supabase
          .from('verification_submissions')
          .delete()
          .eq('application_id', existingApp.id)
          .eq('status', 'pending');

      await _supabase.from('verification_submissions').insert({
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
      await _supabase.functions.invoke(
        'verify-payment-v1',
        body: {'imp_uid': impUid, 'merchant_uid': merchantUid},
      );
      Log.i('✅ [EventRepo] Payment verified.');
    } catch (e, st) {
      Log.e('❌ [EventRepo] confirmPayment Error', e, st);
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

      final response = await _supabase.rpc<String>(
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

  /// [Partner Dashboard]
  /// Counts pending review applications for a specific partner.
  Future<int> getPendingApplicationCount(String partnerId) async {
    try {
      // Query verification_submissions joined with applications -> events
      // But RLS might restrict access. Assuming Partner has permission.
      final res = await _supabase
          .from('verification_submissions')
          .select('id')
          .eq('partner_id', partnerId)
          .eq('status', 'pending')
          .count(CountOption.exact);

      return res.count;
    } on Exception catch (e, st) {
      Log.e('❌ [EventRepo] getPendingApplicationCount Error', e, st);
      return 0; // Fail safe
    }
  }

  /// [Partner Dashboard]
  /// Fetches events scheduled for today for a specific partner.
  Future<List<Event>> getTodayEvents(String partnerId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(
        now.year,
        now.month,
        now.day,
      ).toIso8601String();
      final endOfDay = DateTime(
        now.year,
        now.month,
        now.day,
        23,
        59,
        59,
      ).toIso8601String();

      final data = await _supabase
          .from('events')
          .select('*, party:parties!inner(*)')
          .eq('party.partner_id', partnerId)
          .gte('start_time', startOfDay)
          .lte('start_time', endOfDay)
          .order('start_time');

      return (data as List)
          .map((dynamic json) => Event.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      Log.e('❌ [EventRepo] getTodayEvents Error', e, st);
      rethrow;
    }
  }
}
