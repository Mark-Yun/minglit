import 'package:minglit_kit/src/data/models/event.dart';
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
      // Using !inner for filtering based on nested data
      // Include partner info inside party relation
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
}
