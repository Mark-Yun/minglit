import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_edit_controller.g.dart';

typedef EventEditState = _EditState;

EventEditState createEventEditState({
  required Event event,
  required int confirmedCount,
  required String title,
  required DateTime startTime,
  required DateTime endTime,
  required int maxParticipants,
  required String? location,
  bool isDirty = false,
  bool isLoading = false,
}) {
  return _EditState(
    event: event,
    confirmedCount: confirmedCount,
    title: title,
    startTime: startTime,
    endTime: endTime,
    maxParticipants: maxParticipants,
    location: location,
    isDirty: isDirty,
    isLoading: isLoading,
  );
}

class _EditState {
  const _EditState({
    required this.event,
    required this.confirmedCount,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.maxParticipants,
    required this.location,
    required this.isDirty,
    required this.isLoading,
  });

  final Event event;
  final int confirmedCount;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final int maxParticipants;
  final String? location;
  final bool isDirty;
  final bool isLoading;

  bool get isScheduleChanged =>
      startTime != event.startTime || endTime != event.endTime;

  _EditState copyWith({
    Event? event,
    int? confirmedCount,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    int? maxParticipants,
    Object? location = _copySentinel,
    bool? isDirty,
    bool? isLoading,
  }) {
    return _EditState(
      event: event ?? this.event,
      confirmedCount: confirmedCount ?? this.confirmedCount,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      location: identical(location, _copySentinel)
          ? this.location
          : location as String?,
      isDirty: isDirty ?? this.isDirty,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

const Object _copySentinel = Object();

@riverpod
class EventEditController extends _$EventEditController {
  @override
  Future<EventEditState> build(String eventId) async {
    final eventRepository = ref.watch(eventRepositoryProvider);
    final event = await eventRepository.getEventById(eventId);
    // Fix #2110: Use event.currentParticipants as authoritative confirmed count.
    // getApplicationsByEventId() may return paginated/incomplete results, causing
    // under-counting that could bypass lock policy and min-participant guards.
    // Mirrors event_detail_page.dart which already uses the same source.
    final confirmedCount = event.currentParticipants;

    return createEventEditState(
      event: event,
      confirmedCount: confirmedCount,
      title: event.title ?? '',
      startTime: event.startTime,
      endTime: event.endTime,
      maxParticipants: event.maxParticipants,
      location: _displayLocation(event),
    );
  }

  void updateTitle(String value) {
    final current = state.asData?.value;
    if (current == null) return;
    final nextState = current.copyWith(title: value);
    state = AsyncValue.data(
      nextState.copyWith(isDirty: _computeIsDirty(nextState)),
    );
  }

  void updateMaxParticipants(int value) {
    final current = state.asData?.value;
    if (current == null) return;
    final minimum = current.confirmedCount >= 1 ? current.confirmedCount : 1;
    final nextValue = value < minimum ? minimum : value;
    final nextState = current.copyWith(maxParticipants: nextValue);
    state = AsyncValue.data(
      nextState.copyWith(isDirty: _computeIsDirty(nextState)),
    );
  }

  void updateSchedule({
    required DateTime startTime,
    required DateTime endTime,
    required String? location,
  }) {
    final current = state.asData?.value;
    if (current == null) return;
    final normalizedEndTime = endTime.isBefore(startTime) ? startTime : endTime;
    final nextState = current.copyWith(
      startTime: startTime,
      endTime: normalizedEndTime,
      location: location,
    );
    state = AsyncValue.data(
      nextState.copyWith(isDirty: _computeIsDirty(nextState)),
    );
  }

  // Fix #2110: submit via partner-manage-event EF (action=update) instead of
  // direct client write — EF enforces PARTY_MANAGE/EVENT_MANAGE permission and
  // service_role writes, preventing RLS policy bypass.
  // `reason` is required when confirmedCount >= 1 and schedule changed (UI enforces via dialog).
  Future<void> submit({String? reason}) async {
    final current = state.asData?.value;
    if (current == null || !current.isDirty || current.isLoading) return;

    state = AsyncValue.data(current.copyWith(isLoading: true));

    try {
      final supabase = ref.read(supabaseClientProvider);
      final response = await supabase.functions.invoke(
        'partner-manage-event',
        body: {
          'action': 'update',
          'event_id': current.event.id,
          'event': {
            'title': current.title,
            'start_time': current.startTime.toUtc().toIso8601String(),
            'end_time': current.endTime.toUtc().toIso8601String(),
            'max_participants': current.maxParticipants,
          },
          ?'reason': reason,
        },
      );

      if (response.status != 200) {
        throw Exception(
          'partner-manage-event update failed (${response.status})',
        );
      }

      // Re-fetch event from DB to get the authoritative updated state.
      final updatedEvent = await ref
          .read(eventRepositoryProvider)
          .getEventById(current.event.id);

      ref
        ..invalidate(partyDetailProvider(current.event.partyId))
        ..invalidate(partyEventsProvider(current.event.partyId))
        ..invalidate(eventDetailProvider(current.event.id));

      state = AsyncValue.data(
        createEventEditState(
          event: updatedEvent,
          confirmedCount: current.confirmedCount,
          title: current.title,
          startTime: current.startTime,
          endTime: current.endTime,
          maxParticipants: current.maxParticipants,
          location: current.location,
        ),
      );
    } catch (_) {
      state = AsyncValue.data(current.copyWith(isLoading: false));
      rethrow;
    }
  }

  bool _computeIsDirty(EventEditState current) {
    // Fix #2110: location is read from party.location (display-only) and
    // cannot be changed via this UI — exclude from dirty computation.
    return current.title != (current.event.title ?? '') ||
        current.startTime != current.event.startTime ||
        current.endTime != current.event.endTime ||
        current.maxParticipants != current.event.maxParticipants;
  }

  static String? _displayLocation(Event event) {
    final location = event.party?.location;
    return location?.name ?? location?.address;
  }
}
