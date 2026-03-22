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

/// Fix #299: Result from user-cancel-order Edge Function.
class CancelOrderResult {
  const CancelOrderResult({required this.type, this.refundAmount});

  /// 'cancelled' (결제 전/무료) or 'refunded' (유료 환불)
  final String type;

  /// 환불 금액 (type == 'refunded'일 때만)
  final int? refundAmount;
}

abstract class _SupabaseEventContext {
  SupabaseClient get supabaseClient;
}

abstract class _SupabaseEventContextBase implements _SupabaseEventContext {
  const _SupabaseEventContextBase(this.supabaseClient);

  @override
  final SupabaseClient supabaseClient;
}
