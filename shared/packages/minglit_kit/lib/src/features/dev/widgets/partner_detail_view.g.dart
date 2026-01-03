// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'partner_detail_view.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider to fetch parties for a specific partner.

@ProviderFor(partnerParties)
const partnerPartiesProvider = PartnerPartiesFamily._();

/// Provider to fetch parties for a specific partner.

final class PartnerPartiesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Party>>,
          List<Party>,
          FutureOr<List<Party>>
        >
    with $FutureModifier<List<Party>>, $FutureProvider<List<Party>> {
  /// Provider to fetch parties for a specific partner.
  const PartnerPartiesProvider._({
    required PartnerPartiesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'partnerPartiesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$partnerPartiesHash();

  @override
  String toString() {
    return r'partnerPartiesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Party>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Party>> create(Ref ref) {
    final argument = this.argument as String;
    return partnerParties(ref, partnerId: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PartnerPartiesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$partnerPartiesHash() => r'f7b1cb676b9bdcf5a939a16e263fe5a5d33b3681';

/// Provider to fetch parties for a specific partner.

final class PartnerPartiesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Party>>, String> {
  const PartnerPartiesFamily._()
    : super(
        retry: null,
        name: r'partnerPartiesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider to fetch parties for a specific partner.

  PartnerPartiesProvider call({required String partnerId}) =>
      PartnerPartiesProvider._(argument: partnerId, from: this);

  @override
  String toString() => r'partnerPartiesProvider';
}
