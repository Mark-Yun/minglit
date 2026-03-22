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
  /// Creates an [EventRepository] with a Supabase client.
  EventRepository({SupabaseClient? supabase})
    : super(supabase ?? Supabase.instance.client);
}

/// Result from user-create-order Edge Function.
class CreateOrderResult {
  const CreateOrderResult({
    required this.applicationId,
    required this.amount,
    required this.requiresPayment,
    required this.ticketName,
  });

  final String applicationId;
  final int amount;
  final bool requiresPayment;
  final String ticketName;
}

abstract class _SupabaseEventContext {
  SupabaseClient get supabaseClient;
}

abstract class _SupabaseEventContextBase implements _SupabaseEventContext {
  const _SupabaseEventContextBase(this.supabaseClient);

  @override
  final SupabaseClient supabaseClient;
}
