// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_detail_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EventDetailController)
const eventDetailControllerProvider = EventDetailControllerFamily._();

final class EventDetailControllerProvider
    extends $AsyncNotifierProvider<EventDetailController, Event> {
  const EventDetailControllerProvider._({
    required EventDetailControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'eventDetailControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventDetailControllerHash();

  @override
  String toString() {
    return r'eventDetailControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  EventDetailController create() => EventDetailController();

  @override
  bool operator ==(Object other) {
    return other is EventDetailControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventDetailControllerHash() =>
    r'2ce101f5c994b9fda177b4fbfa27a280b903ba89';

final class EventDetailControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          EventDetailController,
          AsyncValue<Event>,
          Event,
          FutureOr<Event>,
          String
        > {
  const EventDetailControllerFamily._()
    : super(
        retry: null,
        name: r'eventDetailControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EventDetailControllerProvider call(String eventId) =>
      EventDetailControllerProvider._(argument: eventId, from: this);

  @override
  String toString() => r'eventDetailControllerProvider';
}

abstract class _$EventDetailController extends $AsyncNotifier<Event> {
  late final _$args = ref.$arg as String;
  String get eventId => _$args;

  FutureOr<Event> build(String eventId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<AsyncValue<Event>, Event>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Event>, Event>,
              AsyncValue<Event>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(entryGroupParticipantCounts)
const entryGroupParticipantCountsProvider =
    EntryGroupParticipantCountsFamily._();

final class EntryGroupParticipantCountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, int>>,
          Map<String, int>,
          FutureOr<Map<String, int>>
        >
    with $FutureModifier<Map<String, int>>, $FutureProvider<Map<String, int>> {
  const EntryGroupParticipantCountsProvider._({
    required EntryGroupParticipantCountsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'entryGroupParticipantCountsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$entryGroupParticipantCountsHash();

  @override
  String toString() {
    return r'entryGroupParticipantCountsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Map<String, int>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, int>> create(Ref ref) {
    final argument = this.argument as String;
    return entryGroupParticipantCounts(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EntryGroupParticipantCountsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$entryGroupParticipantCountsHash() =>
    r'7e9fe0ef2132acff2158b9d80790afcf731dbaf9';

final class EntryGroupParticipantCountsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Map<String, int>>, String> {
  const EntryGroupParticipantCountsFamily._()
    : super(
        retry: null,
        name: r'entryGroupParticipantCountsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EntryGroupParticipantCountsProvider call(String eventId) =>
      EntryGroupParticipantCountsProvider._(argument: eventId, from: this);

  @override
  String toString() => r'entryGroupParticipantCountsProvider';
}
