// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'partner_detail_view.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider to fetch upcoming events for a specific partner.

@ProviderFor(partnerEvents)
const partnerEventsProvider = PartnerEventsFamily._();

/// Provider to fetch upcoming events for a specific partner.

final class PartnerEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Event>>,
          List<Event>,
          FutureOr<List<Event>>
        >
    with $FutureModifier<List<Event>>, $FutureProvider<List<Event>> {
  /// Provider to fetch upcoming events for a specific partner.
  const PartnerEventsProvider._({
    required PartnerEventsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'partnerEventsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$partnerEventsHash();

  @override
  String toString() {
    return r'partnerEventsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Event>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Event>> create(Ref ref) {
    final argument = this.argument as String;
    return partnerEvents(ref, partnerId: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PartnerEventsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$partnerEventsHash() => r'a3f2cd897e1bcef6b048b17f374ef6a6e44c4792';

/// Provider to fetch upcoming events for a specific partner.

final class PartnerEventsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Event>>, String> {
  const PartnerEventsFamily._()
    : super(
        retry: null,
        name: r'partnerEventsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider to fetch upcoming events for a specific partner.

  PartnerEventsProvider call({required String partnerId}) =>
      PartnerEventsProvider._(argument: partnerId, from: this);

  @override
  String toString() => r'partnerEventsProvider';
}
