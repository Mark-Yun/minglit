import 'package:minglit_kit/src/data/models/event.dart';
import 'package:minglit_kit/src/data/models/event_application.dart';
import 'package:minglit_kit/src/data/models/event_feed_type.dart';
import 'package:minglit_kit/src/utils/exceptions.dart';
import 'package:minglit_kit/src/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'event_repository.g.dart';
part 'event_repository_queries.dart';
part 'event_repository_commands.dart';

/// Provider for EventRepository.
@Riverpod(keepAlive: true)
EventRepository eventRepository(Ref ref) {
  return EventRepository();
}

/// Repository for Event-related data operations.
class EventRepository extends _SupabaseEventContextBase
    with _EventRepositoryQueries, _EventRepositoryCommands {
  EventRepository({SupabaseClient? supabase})
    : super(supabase ?? Supabase.instance.client);
}

abstract class _SupabaseEventContext {
  SupabaseClient get supabaseClient;
}

abstract class _SupabaseEventContextBase implements _SupabaseEventContext {
  const _SupabaseEventContextBase(this.supabaseClient);

  @override
  final SupabaseClient supabaseClient;
}
