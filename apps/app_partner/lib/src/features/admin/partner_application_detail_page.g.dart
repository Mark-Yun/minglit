// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'partner_application_detail_page.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(partnerApplication)
const partnerApplicationProvider = PartnerApplicationFamily._();

final class PartnerApplicationProvider
    extends
        $FunctionalProvider<
          AsyncValue<PartnerApplication?>,
          PartnerApplication?,
          FutureOr<PartnerApplication?>
        >
    with
        $FutureModifier<PartnerApplication?>,
        $FutureProvider<PartnerApplication?> {
  const PartnerApplicationProvider._({
    required PartnerApplicationFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'partnerApplicationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$partnerApplicationHash();

  @override
  String toString() {
    return r'partnerApplicationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PartnerApplication?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PartnerApplication?> create(Ref ref) {
    final argument = this.argument as String;
    return partnerApplication(ref, applicationId: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PartnerApplicationProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$partnerApplicationHash() =>
    r'2995a0b0dd9b08cb3d481bd8d3e192bee63811be';

final class PartnerApplicationFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PartnerApplication?>, String> {
  const PartnerApplicationFamily._()
    : super(
        retry: null,
        name: r'partnerApplicationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PartnerApplicationProvider call({required String applicationId}) =>
      PartnerApplicationProvider._(argument: applicationId, from: this);

  @override
  String toString() => r'partnerApplicationProvider';
}
