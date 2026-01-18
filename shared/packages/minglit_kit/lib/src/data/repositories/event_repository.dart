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
            '*, user:user_profiles(*), submission:verification_submissions(*)',
          )
          .eq('event_id', eventId)
          .order('created_at', ascending: false);

      final result = (data as List)
          .map(
            (json) => EventApplication.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      Log.d('getApplicationsByEventId success | count: ${result.length}');
      return result;
    } catch (e, st) {
      Log.e('❌ [EventRepo] getApplicationsByEventId Error', e, st);
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

  /// Checks if a user has already applied for an event.
  Future<bool> checkApplicationStatus({
    required String eventId,
    required String userId,
  }) async {
    Log.d('checkApplicationStatus called | event: $eventId, user: $userId');
    try {
      final response = await _supabase
          .from('event_applications')
          .select('id')
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e, st) {
      Log.e('❌ [EventRepo] checkApplicationStatus Error', e, st);
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
}
