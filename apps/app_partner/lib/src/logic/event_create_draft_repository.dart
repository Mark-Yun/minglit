import 'dart:convert';

import 'package:app_partner/src/features/party/event/create/event_create_controller.dart';
import 'package:app_partner/src/features/party/logic/recurrence_settings_controller.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

final eventCreateDraftRepositoryProvider = Provider<EventCreateDraftRepository>(
  (ref) => SharedPreferencesEventCreateDraftRepository(),
);

abstract class EventCreateDraftRepository {
  Future<EventCreateDraft?> getDraft(String partyId);

  Future<List<EventCreateDraft>> getDrafts();

  Future<void> saveDraft(EventCreateDraft draft);

  Future<void> deleteDraft(String partyId);
}

class SharedPreferencesEventCreateDraftRepository
    implements EventCreateDraftRepository {
  static const _indexKey = 'event_create_draft_party_ids';
  static const _keyPrefix = 'event_create_draft_v1_';

  @override
  Future<EventCreateDraft?> getDraft(String partyId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keyPrefix$partyId');
    if (raw == null) return null;
    return EventCreateDraft.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  @override
  Future<List<EventCreateDraft>> getDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final partyIds = prefs.getStringList(_indexKey) ?? const <String>[];
    final drafts = <EventCreateDraft>[];
    for (final partyId in partyIds) {
      final raw = prefs.getString('$_keyPrefix$partyId');
      if (raw == null) continue;
      drafts.add(
        EventCreateDraft.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        ),
      );
    }
    drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return drafts;
  }

  @override
  Future<void> saveDraft(EventCreateDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    final partyIds = prefs.getStringList(_indexKey) ?? <String>[];
    if (!partyIds.contains(draft.partyId)) {
      partyIds.add(draft.partyId);
      await prefs.setStringList(_indexKey, partyIds);
    }
    await prefs.setString(
      '$_keyPrefix${draft.partyId}',
      jsonEncode(draft.toJson()),
    );
  }

  @override
  Future<void> deleteDraft(String partyId) async {
    final prefs = await SharedPreferences.getInstance();
    final partyIds = (prefs.getStringList(_indexKey) ?? <String>[])
      ..remove(partyId);
    await prefs.setStringList(_indexKey, partyIds);
    await _removeDraftPayload(prefs, partyId);
  }

  Future<void> _removeDraftPayload(
    SharedPreferences prefs,
    String partyId,
  ) async {
    await prefs.remove('$_keyPrefix$partyId');
  }
}

class EventCreateDraft {
  EventCreateDraft({
    required this.id,
    required this.partyId,
    required this.checkpointTabIndex,
    required this.startTime,
    required this.endTime,
    required this.maxParticipants,
    required this.title,
    required this.description,
    required this.contactOptions,
    required this.entryGroups,
    required this.tickets,
    required this.recurrence,
    required this.updatedAt,
    this.imageUrl,
    this.locationId,
    this.selectedLocation,
    this.addressDetail,
    this.directionsGuide,
    this.visibility,
  });

  factory EventCreateDraft.fromState({
    required EventCreateState state,
    required RecurrenceSettingsState recurrence,
    required DateTime updatedAt,
  }) {
    return EventCreateDraft(
      id: state.draftId ?? const Uuid().v4(),
      partyId: state.partyId,
      checkpointTabIndex: state.checkpointTabIndex,
      startTime: state.startTime,
      endTime: state.endTime,
      maxParticipants: state.maxParticipants,
      title: state.title,
      description: state.description,
      imageUrl: state.imageUrl,
      locationId: state.locationId,
      selectedLocation: state.selectedLocation,
      addressDetail: state.addressDetail,
      directionsGuide: state.directionsGuide,
      contactOptions: state.contactOptions,
      entryGroups: state.entryGroups,
      tickets: state.tickets,
      visibility: state.visibility,
      recurrence: recurrence,
      updatedAt: updatedAt,
    );
  }

  factory EventCreateDraft.fromJson(Map<String, dynamic> json) {
    return EventCreateDraft(
      id: json['id'] as String,
      partyId: json['partyId'] as String,
      checkpointTabIndex: json['checkpointTabIndex'] as int? ?? 0,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      maxParticipants: json['maxParticipants'] as int? ?? 20,
      title: json['title'] as String? ?? '',
      description:
          (json['description'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
      imageUrl: json['imageUrl'] as String?,
      locationId: json['locationId'] as String?,
      selectedLocation: json['selectedLocation'] == null
          ? null
          : Location.fromJson(
              (json['selectedLocation'] as Map).cast<String, dynamic>(),
            ),
      addressDetail: json['addressDetail'] as String?,
      directionsGuide: json['directionsGuide'] as String?,
      contactOptions:
          (json['contactOptions'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
      entryGroups: (json['entryGroups'] as List<dynamic>? ?? const <dynamic>[])
          .map(
            (entry) => EntryGroup.fromJson(
              (entry as Map).cast<String, dynamic>(),
            ),
          )
          .toList(),
      tickets: (json['tickets'] as List<dynamic>? ?? const <dynamic>[])
          .map(
            (ticket) => Ticket.fromJson(
              (ticket as Map).cast<String, dynamic>(),
            ),
          )
          .toList(),
      visibility: json['visibility'] as String?,
      recurrence: _recurrenceFromJson(
        (json['recurrence'] as Map?)?.cast<String, dynamic>(),
      ),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  final String id;
  final String partyId;
  final int checkpointTabIndex;
  final DateTime startTime;
  final DateTime endTime;
  final int maxParticipants;
  final String title;
  final Map<String, dynamic> description;
  final String? imageUrl;
  final String? locationId;
  final Location? selectedLocation;
  final String? addressDetail;
  final String? directionsGuide;
  final Map<String, dynamic> contactOptions;
  final List<EntryGroup> entryGroups;
  final List<Ticket> tickets;
  final String? visibility;
  final RecurrenceSettingsState recurrence;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partyId': partyId,
      'checkpointTabIndex': checkpointTabIndex,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'maxParticipants': maxParticipants,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'locationId': locationId,
      'selectedLocation': selectedLocation?.toJson(),
      'addressDetail': addressDetail,
      'directionsGuide': directionsGuide,
      'contactOptions': contactOptions,
      'entryGroups': entryGroups.map((entry) => entry.toJson()).toList(),
      'tickets': tickets.map((ticket) => ticket.toJson()).toList(),
      'visibility': visibility,
      'recurrence': _recurrenceToJson(recurrence),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  EventCreateState toState() {
    return EventCreateState(
      partyId: partyId,
      draftId: id,
      checkpointTabIndex: checkpointTabIndex,
      startTime: startTime,
      endTime: endTime,
      maxParticipants: maxParticipants,
      title: title,
      description: description,
      imageUrl: imageUrl,
      locationId: locationId,
      selectedLocation: selectedLocation,
      addressDetail: addressDetail,
      directionsGuide: directionsGuide,
      contactOptions: contactOptions,
      entryGroups: entryGroups,
      tickets: tickets,
      visibility: visibility,
      draftUpdatedAt: updatedAt,
    );
  }
}

Map<String, dynamic> _recurrenceToJson(RecurrenceSettingsState recurrence) {
  return {
    'isEnabled': recurrence.isEnabled,
    'pattern': recurrence.pattern.name,
    'daysOfWeek': recurrence.daysOfWeek,
    'monthDay': recurrence.monthDay,
    'endDate': recurrence.endDate,
  };
}

RecurrenceSettingsState _recurrenceFromJson(Map<String, dynamic>? json) {
  if (json == null) return const RecurrenceSettingsState();
  return RecurrenceSettingsState(
    isEnabled: json['isEnabled'] as bool? ?? false,
    pattern: RecurrencePattern.values.firstWhere(
      (pattern) => pattern.name == json['pattern'],
      orElse: () => RecurrencePattern.weekly,
    ),
    daysOfWeek: (json['daysOfWeek'] as List<dynamic>? ?? const <dynamic>[1])
        .cast<int>(),
    monthDay: json['monthDay'] as int?,
    endDate: json['endDate'] as String?,
  );
}
