import 'dart:async';

import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:app_partner/src/features/party/logic/recurrence_settings_controller.dart';
import 'package:app_partner/src/logic/dashboard_refresh_notifier.dart';
import 'package:app_partner/src/logic/event_create_draft_repository.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_create_controller.freezed.dart';
part 'event_create_controller.g.dart';

@freezed
abstract class EventCreateState with _$EventCreateState {
  const factory EventCreateState({
    required String partyId,
    required DateTime startTime,
    required DateTime endTime,
    String? draftId,
    @Default(0) int checkpointTabIndex,
    @Default(20) int maxParticipants,
    @Default('') String title,
    @Default({}) Map<String, dynamic> description,
    String? imageUrl,
    String? locationId,
    Location? selectedLocation,
    String? addressDetail,
    String? directionsGuide,
    @Default({}) Map<String, dynamic> contactOptions,
    @Default([]) List<EntryGroup> entryGroups,
    @Default([]) List<Ticket> tickets,
    String? visibility,
    DateTime? draftUpdatedAt,
    @Default(AsyncValue.data(null)) AsyncValue<void> status,
  }) = _EventCreateState;
}

@riverpod
class EventCreateController extends _$EventCreateController {
  Timer? _draftSaveDebounce;

  @override
  EventCreateState build(String partyId) {
    ref.onDispose(() => _draftSaveDebounce?.cancel());
    final now = DateTime.now();
    final nextWeek = DateTime(now.year, now.month, now.day + 7, 19);

    return EventCreateState(
      partyId: partyId,
      startTime: nextWeek,
      endTime: nextWeek.add(const Duration(hours: 3)),
    );
  }

  Future<void> initWithParty({
    required Party party,
    required List<TicketTemplate> templates,
    Location? location,
  }) async {
    final savedDraft = await ref
        .read(eventCreateDraftRepositoryProvider)
        .getDraft(party.id);
    if (savedDraft != null) {
      state = savedDraft.toState();
      ref.read(recurrenceSettingsControllerProvider.notifier).snapshot =
          savedDraft.recurrence;
      return;
    }

    // 1. Create a base event from party template using the standardized factory
    final baseEvent = Event.createFromParty(
      party,
      startTime: state.startTime,
      endTime: state.endTime,
    );

    // 2. Map templates to instance-based tickets using the factory method
    final initialTickets = templates.map(Ticket.createFromTemplate).toList();

    // 3. Map entry group templates to instances
    final initialEntryGroups =
        party.entryGroups
            ?.map(
              (group) => EntryGroup.createFromTemplate(group, id: group.id),
            )
            .toList() ??
        [];

    state = state.copyWith(
      title: baseEvent.title ?? '',
      description: baseEvent.description ?? {},
      imageUrl: party.imageUrl,
      maxParticipants: baseEvent.maxParticipants,
      contactOptions: baseEvent.contactOptions,
      entryGroups: initialEntryGroups,
      tickets: initialTickets,
      locationId: baseEvent.locationId,
      selectedLocation: location,
      addressDetail: location?.addressDetail,
      directionsGuide: location?.directionsGuide,
    );
  }

  void updateStartTime(DateTime dateTime) {
    var nextState = state.copyWith(startTime: dateTime);
    if (nextState.endTime.isBefore(dateTime)) {
      nextState = nextState.copyWith(
        endTime: dateTime.add(const Duration(hours: 3)),
      );
    }
    _setDraftableState(nextState);
  }

  void updateEndTime(DateTime dateTime) {
    _setDraftableState(state.copyWith(endTime: dateTime));
  }

  void updateMaxParticipants(int count) {
    _setDraftableState(state.copyWith(maxParticipants: count));
  }

  void updateTitle(String? value) {
    _setDraftableState(state.copyWith(title: value ?? ''));
  }

  void updateDescription(Map<String, dynamic> value) {
    _setDraftableState(state.copyWith(description: value));
  }

  void updateImageUrl(String? value) {
    _setDraftableState(state.copyWith(imageUrl: value));
  }

  void updateContactOptions(Map<String, dynamic> options) {
    _setDraftableState(state.copyWith(contactOptions: options));
  }

  void updateLocation(Location? location) {
    _setDraftableState(
      state.copyWith(
        selectedLocation: location,
        locationId: location?.id,
      ),
    );
  }

  void updateAddressDetail(String? value) {
    _setDraftableState(state.copyWith(addressDetail: value));
  }

  void updateDirections(String? value) {
    _setDraftableState(state.copyWith(directionsGuide: value));
  }

  void setVisibility(String? value) {
    _setDraftableState(state.copyWith(visibility: value));
  }

  void updateCheckpointTab(int index) {
    if (state.checkpointTabIndex == index) return;
    _setDraftableState(state.copyWith(checkpointTabIndex: index));
  }

  void saveDraftSoon() {
    _scheduleDraftSave();
  }

  Future<void> submit() async {
    _draftSaveDebounce?.cancel();
    state = state.copyWith(status: const AsyncValue<void>.loading());

    // Fix #1037: snapshot recurrence state before any await to avoid race
    // conditions.
    final recurrenceSnapshot = ref.read(recurrenceSettingsControllerProvider);
    final draftRepo = ref.read(eventCreateDraftRepositoryProvider);
    final draftPartyId = state.partyId;

    final result = await AsyncValue.guard(() async {
      final repo = ref.read(partyRepositoryProvider);
      final locationRepo = ref.read(locationRepositoryProvider);

      var finalLocationId = state.locationId;

      if (state.selectedLocation != null &&
          (state.locationId == null || state.locationId!.isEmpty)) {
        // Fetch current party to get partnerId
        final party = await ref.read(partyDetailProvider(state.partyId).future);
        final newLoc = await locationRepo.createLocation(
          state.selectedLocation!.copyWith(
            partnerId: party.partnerId,
            addressDetail: state.addressDetail,
            directionsGuide: state.directionsGuide,
          ),
        );
        finalLocationId = newLoc.id;
      }

      final event = Event(
        id: '',
        partyId: state.partyId,
        startTime: state.startTime,
        endTime: state.endTime,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        maxParticipants: state.maxParticipants,
        locationId: finalLocationId,
        title: state.title,
        description: state.description.isEmpty ? null : state.description,
        contactOptions: state.contactOptions,
        entryGroups: state.entryGroups,
        tickets: state.tickets, // Pass the tickets to repository
        visibility: state.visibility,
      );

      await repo.createEvent(event);

      // Fix #1037: 반복 설정이 활성화된 경우 recurrence rule 생성 (invalidate는 이후)
      if (recurrenceSnapshot.isEnabled) {
        final recurrenceRepo = ref.read(recurrenceRuleRepositoryProvider);
        String pad2(int n) => n.toString().padLeft(2, '0');
        final startTimeStr =
            '${pad2(state.startTime.hour)}:${pad2(state.startTime.minute)}';
        final endTimeStr =
            '${pad2(state.endTime.hour)}:${pad2(state.endTime.minute)}';
        await recurrenceRepo.create(
          partyId: state.partyId,
          pattern: recurrenceSnapshot.pattern,
          daysOfWeek: recurrenceSnapshot.daysOfWeek,
          monthDay: recurrenceSnapshot.monthDay,
          startTime: startTimeStr,
          endTime: endTimeStr,
          endDate: recurrenceSnapshot.endDate,
        );
      }

      ref.invalidate(partyEventsProvider(state.partyId));
      // Fix #1943: bump shared signal so dashboard refreshes without
      // cross-feature import.
      ref.read(dashboardRefreshProvider.notifier).bump();
    });

    if (result.hasValue) {
      await draftRepo.deleteDraft(draftPartyId);
    }
    if (!ref.mounted) return;
    state = state.copyWith(
      draftId: result.hasValue ? null : state.draftId,
      draftUpdatedAt: result.hasValue ? null : state.draftUpdatedAt,
      status: result,
    );
  }

  void _setDraftableState(EventCreateState nextState) {
    state = nextState;
    _scheduleDraftSave();
  }

  void _scheduleDraftSave() {
    _draftSaveDebounce?.cancel();
    _draftSaveDebounce = Timer(const Duration(milliseconds: 500), () {
      unawaited(saveDraftNow());
    });
  }

  Future<void> saveDraftNow() async {
    _draftSaveDebounce?.cancel();
    final updatedAt = DateTime.now();
    final recurrence = ref.read(recurrenceSettingsControllerProvider);
    final draft = EventCreateDraft.fromState(
      state: state,
      recurrence: recurrence,
      updatedAt: updatedAt,
    );
    await ref.read(eventCreateDraftRepositoryProvider).saveDraft(draft);
    state = state.copyWith(draftId: draft.id, draftUpdatedAt: updatedAt);
  }
}
