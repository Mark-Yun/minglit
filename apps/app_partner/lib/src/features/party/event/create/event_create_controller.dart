import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:minglit_kit/minglit_kit.dart' hide partyEventsProvider;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_create_controller.freezed.dart';
part 'event_create_controller.g.dart';

@freezed
abstract class EventCreateState with _$EventCreateState {
  const factory EventCreateState({
    required String partyId,
    required DateTime startTime,
    required DateTime endTime,
    @Default(20) int maxParticipants,
    @Default('') String title,
    @Default({}) Map<String, dynamic> description,
    String? imageUrl,
    String? locationId,
    Location? selectedLocation,
    String? addressDetail,
    String? directionsGuide,
    @Default({}) Map<String, dynamic> contactOptions,
    @Default([]) List<PartyEntryGroup> entryGroups,
    @Default([]) List<Ticket> tickets,
    @Default(AsyncValue.data(null)) AsyncValue<void> status,
  }) = _EventCreateState;
}

@riverpod
class EventCreateController extends _$EventCreateController {
  @override
  EventCreateState build(String partyId) {
    final now = DateTime.now();
    final nextWeek = DateTime(now.year, now.month, now.day + 7, 19);

    return EventCreateState(
      partyId: partyId,
      startTime: nextWeek,
      endTime: nextWeek.add(const Duration(hours: 3)),
    );
  }

  void initWithParty({
    required Party party,
    required List<TicketTemplate> templates,
    Location? location,
  }) {
    // Map templates to instance-based tickets using the factory method
    final initialTickets = templates.map(Ticket.createFromTemplate).toList();

    state = state.copyWith(
      title: party.title,
      description: party.description ?? {},
      imageUrl: party.imageUrl,
      maxParticipants: party.maxParticipants,
      contactOptions: party.contactOptions,
      entryGroups: party.entryGroups,
      tickets: initialTickets,
      locationId: party.locationId,
      selectedLocation: location,
      addressDetail: location?.addressDetail,
      directionsGuide: location?.directionsGuide,
    );
  }

  void updateStartTime(DateTime dateTime) {
    state = state.copyWith(startTime: dateTime);
    if (state.endTime.isBefore(dateTime)) {
      state = state.copyWith(endTime: dateTime.add(const Duration(hours: 3)));
    }
  }

  void updateEndTime(DateTime dateTime) {
    state = state.copyWith(endTime: dateTime);
  }

  void updateMaxParticipants(int count) {
    state = state.copyWith(maxParticipants: count);
  }

  void updateTitle(String? value) {
    state = state.copyWith(title: value ?? '');
  }

  void updateDescription(Map<String, dynamic> value) {
    state = state.copyWith(description: value);
  }

  void updateImageUrl(String? value) {
    state = state.copyWith(imageUrl: value);
  }

  void updateContactOptions(Map<String, dynamic> options) {
    state = state.copyWith(contactOptions: options);
  }

  void updateLocation(Location? location) {
    state = state.copyWith(
      selectedLocation: location,
      locationId: location?.id,
    );
  }

  void updateAddressDetail(String? value) {
    state = state.copyWith(addressDetail: value);
  }

  void updateDirections(String? value) {
    state = state.copyWith(directionsGuide: value);
  }

  Future<void> submit() async {
    state = state.copyWith(status: const AsyncValue<void>.loading());

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
        tickets: state.tickets, // Pass the tickets to repository
      );

      await repo.createEvent(event);
      ref.invalidate(partyEventsProvider(state.partyId));
    });

    state = state.copyWith(status: result);
  }
}
