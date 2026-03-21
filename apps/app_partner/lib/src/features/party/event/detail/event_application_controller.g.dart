// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_application_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(eventApplications)
const eventApplicationsProvider = EventApplicationsFamily._();

final class EventApplicationsProvider extends $FunctionalProvider<
        AsyncValue<List<EventApplication>>,
        List<EventApplication>,
        FutureOr<List<EventApplication>>>
    with
        $FutureModifier<List<EventApplication>>,
        $FutureProvider<List<EventApplication>> {
  const EventApplicationsProvider._({
    required EventApplicationsFamily super.from,
    required String super.argument,
  }) : super(
          retry: null,
          name: r'eventApplicationsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$eventApplicationsHash();

  @override
  String toString() {
    return r'eventApplicationsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<EventApplication>> $createElement(
    $ProviderPointer pointer,
  ) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<EventApplication>> create(Ref ref) {
    final argument = this.argument as String;
    return eventApplications(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EventApplicationsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventApplicationsHash() => r'f9d5b9692bb8baf2e3c9f27a1550fd33efcd40c1';

final class EventApplicationsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<EventApplication>>, String> {
  const EventApplicationsFamily._()
      : super(
          retry: null,
          name: r'eventApplicationsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  EventApplicationsProvider call(String eventId) =>
      EventApplicationsProvider._(argument: eventId, from: this);

  @override
  String toString() => r'eventApplicationsProvider';
}

@ProviderFor(EventApplicationReviewController)
const eventApplicationReviewControllerProvider =
    EventApplicationReviewControllerProvider._();

final class EventApplicationReviewControllerProvider
    extends $AsyncNotifierProvider<EventApplicationReviewController, void> {
  const EventApplicationReviewControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'eventApplicationReviewControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$eventApplicationReviewControllerHash();

  @$internal
  @override
  EventApplicationReviewController create() =>
      EventApplicationReviewController();
}

String _$eventApplicationReviewControllerHash() =>
    r'5b762c59541102d4e12e904f980ef60fa43cdc34';

abstract class _$EventApplicationReviewController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<void>, void>,
        AsyncValue<void>,
        Object?,
        Object?>;
    element.handleValue(ref, null);
  }
}
